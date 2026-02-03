#!/system/bin/sh

if [ "$(id -u)" != "0" ]; then
    exec su -c "sh $0 $*"
fi

SCRIPT_DIR=$(dirname $(readlink -f "$0"))
SOCK="$SCRIPT_DIR/crosvm-nixos.sock"

# Try graceful stop via socket first
if [ -S "$SOCK" ]; then
    echo "Stopping NixOS VM via socket..."
    /data/local/tmp/crosvm stop "$SOCK" && echo "VM stopped gracefully"
    rm -f "$SOCK"
else
    echo "No socket found."
fi

# Clean up tap
if [ -d /sys/class/net/tap2 ]; then
    ip link set tap2 down 2>/dev/null
    ip link delete tap2 2>/dev/null
    echo "TAP device removed"
fi
