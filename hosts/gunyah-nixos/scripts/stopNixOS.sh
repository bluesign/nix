#!/bin/bash
# stopNixOS.sh — Gracefully stop NixOS VM
# Deploy to ~/nixos/ on the phone
set -e

SOCKET="$HOME/nixos/crosvm-nixos.sock"
TAP="tap2"

if [ ! -S "$SOCKET" ]; then
    echo "NixOS VM is not running (no socket at $SOCKET)"
    exit 1
fi

echo "Stopping NixOS VM..."
crosvm stop "$SOCKET"

# Clean up TAP interface
if ip link show "$TAP" &>/dev/null; then
    ip link set "$TAP" down
    ip tuntap del dev "$TAP" mode tap
fi

echo "NixOS VM stopped."
