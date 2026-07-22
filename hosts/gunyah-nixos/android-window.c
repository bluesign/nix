/*
 * android-window: Wayland client that displays an Android VirtualDisplay
 * streamed from AppDisplay over TCP. Renders as a native niri window.
 *
 * Usage: android-window <host> <port> <width> <height> [title]
 * Example: android-window 192.168.8.1 17100 848 1200 "Chrome"
 *
 * Protocol: see AppDisplay.java
 * Build: gcc -O2 -o android-window android-window.c $(pkg-config --cflags --libs sdl2) -lpthread
 */

#include <SDL2/SDL.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MSG_FRAME 1
#define MSG_KEY   10
#define MSG_TOUCH 11
#define MSG_MOUSE 12

/* Android KeyEvent actions */
#define ACTION_DOWN 0
#define ACTION_UP   1
#define ACTION_MOVE 2

typedef struct {
    int sock;
    int width;
    int height;
    uint8_t *pixels;      /* double buffer: front */
    uint8_t *pixels_back;  /* double buffer: back */
    SDL_mutex *mutex;
    int frame_ready;
    int running;
} State;

static int read_exact(int fd, void *buf, size_t len) {
    size_t pos = 0;
    while (pos < len) {
        ssize_t n = read(fd, (char *)buf + pos, len - pos);
        if (n <= 0) return -1;
        pos += n;
    }
    return 0;
}

static int read_int(int fd) {
    int32_t val;
    if (read_exact(fd, &val, 4) < 0) return -1;
    return (int)ntohl((uint32_t)val);
}

static void send_int(int fd, int val) {
    int32_t be = (int32_t)htonl((uint32_t)val);
    write(fd, &be, 4);
}

static void *recv_thread(void *arg) {
    State *s = (State *)arg;
    int row_bytes = s->width * 4;

    while (s->running) {
        int msg = read_int(s->sock);
        if (msg < 0) break;

        if (msg == MSG_FRAME) {
            int w = read_int(s->sock);
            int h = read_int(s->sock);
            int stride = read_int(s->sock);
            (void)stride;

            /* Read frame into back buffer */
            for (int y = 0; y < h && y < s->height; y++) {
                if (read_exact(s->sock, s->pixels_back + y * row_bytes, row_bytes) < 0)
                    goto done;
            }

            /* Swap into front buffer */
            SDL_LockMutex(s->mutex);
            uint8_t *tmp = s->pixels;
            s->pixels = s->pixels_back;
            s->pixels_back = tmp;
            s->frame_ready = 1;
            SDL_UnlockMutex(s->mutex);
        }
    }
done:
    s->running = 0;
    /* Push a quit event to wake SDL */
    SDL_Event ev;
    ev.type = SDL_QUIT;
    SDL_PushEvent(&ev);
    return NULL;
}

/* Map SDL scancodes to Android keycodes (subset) */
static int sdl_to_android_keycode(SDL_Scancode sc) {
    if (sc >= SDL_SCANCODE_A && sc <= SDL_SCANCODE_Z)
        return 29 + (sc - SDL_SCANCODE_A); /* KEYCODE_A=29 */
    if (sc >= SDL_SCANCODE_1 && sc <= SDL_SCANCODE_9)
        return 8 + (sc - SDL_SCANCODE_1);  /* KEYCODE_1=8 */
    if (sc == SDL_SCANCODE_0) return 7;     /* KEYCODE_0 */

    switch (sc) {
        case SDL_SCANCODE_RETURN:    return 66;  /* KEYCODE_ENTER */
        case SDL_SCANCODE_ESCAPE:    return 111; /* KEYCODE_ESCAPE */
        case SDL_SCANCODE_BACKSPACE: return 67;  /* KEYCODE_DEL */
        case SDL_SCANCODE_TAB:       return 61;  /* KEYCODE_TAB */
        case SDL_SCANCODE_SPACE:     return 62;  /* KEYCODE_SPACE */
        case SDL_SCANCODE_LEFT:      return 21;  /* KEYCODE_DPAD_LEFT */
        case SDL_SCANCODE_RIGHT:     return 22;  /* KEYCODE_DPAD_RIGHT */
        case SDL_SCANCODE_UP:        return 19;  /* KEYCODE_DPAD_UP */
        case SDL_SCANCODE_DOWN:      return 20;  /* KEYCODE_DPAD_DOWN */
        case SDL_SCANCODE_HOME:      return 3;   /* KEYCODE_HOME */
        case SDL_SCANCODE_DELETE:     return 112; /* KEYCODE_FORWARD_DEL */
        case SDL_SCANCODE_MINUS:     return 69;  /* KEYCODE_MINUS */
        case SDL_SCANCODE_EQUALS:    return 70;  /* KEYCODE_EQUALS */
        case SDL_SCANCODE_LEFTBRACKET:  return 71;
        case SDL_SCANCODE_RIGHTBRACKET: return 72;
        case SDL_SCANCODE_BACKSLASH:    return 73;
        case SDL_SCANCODE_SEMICOLON:    return 74;
        case SDL_SCANCODE_APOSTROPHE:   return 75;
        case SDL_SCANCODE_GRAVE:        return 68;
        case SDL_SCANCODE_COMMA:        return 55;
        case SDL_SCANCODE_PERIOD:       return 56;
        case SDL_SCANCODE_SLASH:        return 76;
        case SDL_SCANCODE_F1:  return 131;
        case SDL_SCANCODE_F2:  return 132;
        case SDL_SCANCODE_F3:  return 133;
        case SDL_SCANCODE_F4:  return 134;
        case SDL_SCANCODE_F5:  return 135;
        case SDL_SCANCODE_F6:  return 136;
        case SDL_SCANCODE_F7:  return 137;
        case SDL_SCANCODE_F8:  return 138;
        case SDL_SCANCODE_F9:  return 139;
        case SDL_SCANCODE_F10: return 140;
        case SDL_SCANCODE_F11: return 141;
        case SDL_SCANCODE_F12: return 142;
        case SDL_SCANCODE_PAGEUP:   return 92;
        case SDL_SCANCODE_PAGEDOWN: return 93;
        case SDL_SCANCODE_INSERT:   return 124;
        case SDL_SCANCODE_LSHIFT: case SDL_SCANCODE_RSHIFT: return 59;
        case SDL_SCANCODE_LCTRL:  case SDL_SCANCODE_RCTRL:  return 113;
        case SDL_SCANCODE_LALT:   case SDL_SCANCODE_RALT:   return 57;
        default: return -1;
    }
}

int main(int argc, char *argv[]) {
    if (argc < 5) {
        fprintf(stderr, "Usage: android-window <host> <port> <width> <height> [title]\n");
        return 1;
    }

    const char *host = argv[1];
    int port = atoi(argv[2]);
    int width = atoi(argv[3]);
    int height = atoi(argv[4]);
    const char *title = argc > 5 ? argv[5] : "Android App";

    /* Connect to AppDisplay server */
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) { perror("socket"); return 1; }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    inet_pton(AF_INET, host, &addr.sin_addr);

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("connect");
        return 1;
    }
    int flag = 1;
    setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
    fprintf(stderr, "Connected to %s:%d\n", host, port);

    /* SDL2 init — prefer Wayland */
    setenv("SDL_VIDEODRIVER", "wayland", 0);
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *win = SDL_CreateWindow(title,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        width, height,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
    if (!win) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!ren)
        ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);

    SDL_Texture *tex = SDL_CreateTexture(ren,
        SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING,
        width, height);

    /* State */
    int frame_size = width * height * 4;
    State state = {
        .sock = sock,
        .width = width,
        .height = height,
        .pixels = calloc(1, frame_size),
        .pixels_back = calloc(1, frame_size),
        .mutex = SDL_CreateMutex(),
        .frame_ready = 0,
        .running = 1,
    };

    /* Start frame receiver thread */
    pthread_t tid;
    pthread_create(&tid, NULL, recv_thread, &state);

    /* Main loop */
    while (state.running) {
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            switch (ev.type) {
            case SDL_QUIT:
                state.running = 0;
                break;

            case SDL_KEYDOWN:
            case SDL_KEYUP: {
                int kc = sdl_to_android_keycode(ev.key.keysym.scancode);
                if (kc >= 0) {
                    send_int(sock, MSG_KEY);
                    send_int(sock, ev.type == SDL_KEYDOWN ? ACTION_DOWN : ACTION_UP);
                    send_int(sock, kc);
                    send_int(sock, 0);
                }
                break;
            }

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                if (ev.button.button == SDL_BUTTON_LEFT) {
                    /* Scale mouse coords to app resolution */
                    int ww, wh;
                    SDL_GetWindowSize(win, &ww, &wh);
                    int ax = ev.button.x * width / ww;
                    int ay = ev.button.y * height / wh;
                    send_int(sock, MSG_TOUCH);
                    send_int(sock, ev.type == SDL_MOUSEBUTTONDOWN ? ACTION_DOWN : ACTION_UP);
                    send_int(sock, ax);
                    send_int(sock, ay);
                    send_int(sock, 0);
                }
                break;

            case SDL_MOUSEMOTION:
                if (ev.motion.state & SDL_BUTTON_LMASK) {
                    int ww, wh;
                    SDL_GetWindowSize(win, &ww, &wh);
                    int ax = ev.motion.x * width / ww;
                    int ay = ev.motion.y * height / wh;
                    send_int(sock, MSG_TOUCH);
                    send_int(sock, ACTION_MOVE);
                    send_int(sock, ax);
                    send_int(sock, ay);
                    send_int(sock, 0);
                }
                break;

            case SDL_MOUSEWHEEL: {
                /* Scroll: simulate swipe gesture */
                int cx = width / 2, cy = height / 2;
                int dy = ev.wheel.y * -120;
                send_int(sock, MSG_TOUCH);
                send_int(sock, ACTION_DOWN);
                send_int(sock, cx);
                send_int(sock, cy);
                send_int(sock, 0);
                send_int(sock, MSG_TOUCH);
                send_int(sock, ACTION_MOVE);
                send_int(sock, cx);
                send_int(sock, cy + dy);
                send_int(sock, 0);
                send_int(sock, MSG_TOUCH);
                send_int(sock, ACTION_UP);
                send_int(sock, cx);
                send_int(sock, cy + dy);
                send_int(sock, 0);
                break;
            }
            }
        }

        /* Render latest frame */
        SDL_LockMutex(state.mutex);
        if (state.frame_ready) {
            SDL_UpdateTexture(tex, NULL, state.pixels, width * 4);
            state.frame_ready = 0;
        }
        SDL_UnlockMutex(state.mutex);

        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, NULL, NULL);
        SDL_RenderPresent(ren);
    }

    close(sock);
    pthread_join(tid, NULL);
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    free(state.pixels);
    free(state.pixels_back);
    return 0;
}
