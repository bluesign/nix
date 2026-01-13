# Whisper speech-to-text module
{ config, lib, pkgs, ... }:

{
  # whisper-cpp for local transcription
  environment.systemPackages = with pkgs; [
    whisper-cpp
  ];

  # Download whisper models on activation
  system.activationScripts.whisper-model = ''
    WHISPER_DIR="/var/lib/whisper"
    mkdir -p "$WHISPER_DIR"

    # Large model for Turkish/multilingual
    if [ ! -f "$WHISPER_DIR/ggml-large-v3-turbo.bin" ]; then
      echo "Downloading whisper large-v3-turbo model (~1.5GB)..."
      ${pkgs.curl}/bin/curl -L -o "$WHISPER_DIR/ggml-large-v3-turbo.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
    fi

    # Small model for English (faster)
    if [ ! -f "$WHISPER_DIR/ggml-small.en.bin" ]; then
      echo "Downloading whisper small.en model (~466MB)..."
      ${pkgs.curl}/bin/curl -L -o "$WHISPER_DIR/ggml-small.en.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
    fi

    chmod 644 "$WHISPER_DIR"/*.bin
  '';
}
