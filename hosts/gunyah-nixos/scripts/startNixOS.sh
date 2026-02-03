#!/bin/bash
# startNixOS.sh — Start NixOS VM on Gunyah/crosvm (OnePlus 13)
# Deploy to ~/nixos/ on the phone
# Runs alongside Debian VM (.2) — NixOS gets .3
set -e

NIXOS_DIR="$HOME/nixos"
KERNEL="$NIXOS_DIR/Image"
INITRD="$NIXOS_DIR/initrd"
ROOTFS="$NIXOS_DIR/rootfs"
SOCKET="$NIXOS_DIR/crosvm-nixos.sock"

TAP="tap2"
HOST_IP="192.168.8.1"
GUEST_IP="192.168.8.3"
MAC="52:54:00:12:34:03"

MEM=4096
CPUS=4

# --- Networking setup ---

# Create TAP interface for NixOS VM
if ! ip link show "$TAP" &>/dev/null; then
    ip tuntap add dev "$TAP" mode tap
fi
# Host IP may already be on tap1/bridge — only add if not present
if ! ip addr show dev "$TAP" | grep -q "$HOST_IP"; then
    ip addr add "$HOST_IP/24" dev "$TAP" 2>/dev/null || true
fi
ip link set "$TAP" up

# Enable IP forwarding + NAT for internet access
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -C POSTROUTING -s 192.168.8.0/24 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 192.168.8.0/24 -j MASQUERADE
iptables -C FORWARD -i "$TAP" -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i "$TAP" -j ACCEPT
iptables -C FORWARD -o "$TAP" -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -o "$TAP" -j ACCEPT

# --- Launch VM ---

echo "Starting NixOS VM: ${GUEST_IP} (mem=${MEM}M, cpus=${CPUS})"
echo "Control socket: ${SOCKET}"
echo "X11 display: ${HOST_IP}:0 (termux-x11)"

crosvm run \
    -m "size=${MEM}" \
    -c "num-cores=${CPUS}" \
    --initrd "$INITRD" \
    --shared-dir "${ROOTFS}:rootfs:type=fs:cache=always" \
    --net "tap-name=${TAP},mac=${MAC}" \
    --serial type=stdout,console \
    -s "$SOCKET" \
    -p "rootfstype=virtiofs root=rootfs console=hvc0" \
    "$KERNEL"
