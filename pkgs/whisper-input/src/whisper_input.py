#!/usr/bin/env python3
"""
Voice-to-text input using whisper-stream for real-time transcription.
Uses whisper-cpp's built-in streaming which handles all the chunking properly.
"""

import argparse
import subprocess
import sys
import re


def type_text(text):
    """Type text using wtype (Wayland)"""
    if not text:
        return
    try:
        subprocess.run(["wtype", "--", text], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Failed to type text: {e}", file=sys.stderr)
    except FileNotFoundError:
        print("wtype not found.", file=sys.stderr)


def delete_chars(count):
    """Delete characters using wtype backspace"""
    if count <= 0:
        return
    try:
        for _ in range(count):
            subprocess.run(["wtype", "-k", "BackSpace"], check=True)
    except subprocess.CalledProcessError:
        pass


class TranscriptionHistory:
    """Track typed text for undo functionality"""
    def __init__(self):
        self.history = []  # List of (text, char_count) tuples

    def add(self, text):
        # +1 for the space we add after
        self.history.append((text, len(text) + 1))
        # Keep only last 10
        if len(self.history) > 10:
            self.history.pop(0)

    def undo(self):
        if self.history:
            text, count = self.history.pop()
            delete_chars(count)
            return text
        return None

    def clear(self):
        self.history = []


def get_model_for_lang(lang, model_override):
    """Select appropriate model based on language"""
    if model_override:
        return model_override
    if lang == "en":
        return "/var/lib/whisper/ggml-small.en.bin"
    return "/var/lib/whisper/ggml-large-v3-turbo.bin"


def run_stream(args):
    """Run whisper-stream and pipe output to wtype"""
    model = get_model_for_lang(args.lang, args.model)
    cmd = [
        "whisper-stream",
        "-m", model,
        "-l", args.lang,
        "-t", str(args.threads),
        "--step", str(args.step),
        "--length", str(args.length),
    ]

    if args.vad:
        cmd.append("--vad-thold")
        cmd.append(str(args.vad_threshold))

    print(f"Starting whisper-stream...")
    print(f"Language: {args.lang}")
    print(f"Model: {model}")
    print("Commands: 'sil/delete' = undo last, 'temizle/clear' = undo all")
    print("Ctrl+C to exit")
    print("-" * 40)

    # Command words for undo/clear
    undo_words = ["sil", "delete", "geri", "undo", "back", "iptal"]
    clear_words = ["temizle", "clear", "reset", "sıfırla"]

    history = TranscriptionHistory()

    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,  # Ignore init messages
            text=True,
            bufsize=1
        )

        for line in process.stdout:
            line = line.strip()

            # Skip empty lines and status messages
            if not line or line.startswith("[") or line.startswith("main:") or line.startswith("whisper"):
                continue

            # Clean up the transcription
            text = clean_text(line)
            if not text:
                continue

            text_lower = text.lower().strip()

            # Check for undo command
            if text_lower in undo_words or any(text_lower.startswith(w) for w in undo_words):
                undone = history.undo()
                if undone:
                    print(f"[UNDO: '{undone}']", flush=True)
                else:
                    print("[Nothing to undo]", flush=True)
                continue

            # Check for clear command
            if text_lower in clear_words or any(text_lower.startswith(w) for w in clear_words):
                count = len(history.history)
                while history.undo():
                    pass
                print(f"[CLEARED {count} items]", flush=True)
                continue

            # Normal transcription - type it
            print(f"► {text}", flush=True)
            type_text(text + " ")
            history.add(text)

    except KeyboardInterrupt:
        print("\nExiting...")
        process.terminate()
    except FileNotFoundError:
        print("whisper-stream not found. Make sure whisper-cpp is installed.", file=sys.stderr)
        sys.exit(1)


def clean_text(text):
    """Remove whisper artifacts"""
    if not text:
        return None

    # Remove common artifacts
    artifacts = [
        "[BLANK_AUDIO]", "[MUSIC]", "[NOISE]", "[SILENCE]",
        "(silence)", "(music)", "(blank audio)", "(noise)",
        "[inaudible]", "(inaudible)", "*silence*", "*music*",
        "[ Silence ]", "[ Music ]", "[silence]", "[music]",
        "(sighs)", "(coughs)", "[applause]", "(applause)",
    ]

    cleaned = text
    for artifact in artifacts:
        cleaned = cleaned.replace(artifact, "")

    # Remove timestamps like [00:00:00.000 --> 00:00:02.000]
    cleaned = re.sub(r'\[\d{2}:\d{2}:\d{2}\.\d{3}\s*-->\s*\d{2}:\d{2}:\d{2}\.\d{3}\]', '', cleaned)

    cleaned = cleaned.strip()

    if len(cleaned) < 1:
        return None

    return cleaned


def main():
    parser = argparse.ArgumentParser(description="Voice-to-text input using whisper-stream")
    parser.add_argument("-m", "--model", default=None,
                        help="Path to whisper model (auto-selects based on language)")
    parser.add_argument("-l", "--lang", default="tr",
                        help="Language code (e.g., en, tr, de)")
    parser.add_argument("-t", "--threads", type=int, default=8,
                        help="Number of threads")
    parser.add_argument("--step", type=int, default=3000,
                        help="Audio step size in ms (default: 3000)")
    parser.add_argument("--length", type=int, default=10000,
                        help="Audio length in ms (default: 10000)")
    parser.add_argument("--vad", action="store_true",
                        help="Enable voice activity detection")
    parser.add_argument("--vad-threshold", type=float, default=0.6,
                        help="VAD threshold (default: 0.6)")
    args = parser.parse_args()

    run_stream(args)


if __name__ == "__main__":
    main()
