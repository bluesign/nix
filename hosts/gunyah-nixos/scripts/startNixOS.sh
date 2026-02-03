#!/system/bin/sh

# Re-exec as root if not already
if [ "$(id -u)" != "0" ]; then
    exec su -c "sh $0 $*"
fi

SCRIPT_DIR=$(dirname $(readlink -f "$0"))
SOCK="$SCRIPT_DIR/crosvm-nixos.sock"
LOG="$SCRIPT_DIR/crosvm-nixos.log"

cd /data/local/tmp

# --- Check if already running ---
if [ -S "$SOCK" ]; then
    echo "Error: NixOS VM is already running. Stop it first:"
    echo "  sh $SCRIPT_DIR/stopNixOS.sh"
    exit 1
fi

rm -f "$SOCK" "$LOG"

ifname=tap2
if [ -d /sys/class/net/$ifname ]; then
    ip link set $ifname down 2>/dev/null
    ip link delete $ifname 2>/dev/null
fi

# --- Network setup ---
ip tuntap add mode tap vnet_hdr $ifname
ip addr add 192.168.8.1/24 dev $ifname 2>/dev/null || true
ip link set $ifname up

iptables -D INPUT -j ACCEPT -i $ifname 2>/dev/null
iptables -D OUTPUT -j ACCEPT -o $ifname 2>/dev/null
iptables -I INPUT -j ACCEPT -i $ifname
iptables -I OUTPUT -j ACCEPT -o $ifname
iptables -t nat -D POSTROUTING -j MASQUERADE -o wlan0 -s 192.168.8.0/24 2>/dev/null
iptables -t nat -I POSTROUTING -j MASQUERADE -o wlan0 -s 192.168.8.0/24
sysctl -w net.ipv4.ip_forward=1

ip rule add iif $ifname lookup wlan0 2>/dev/null

iptables -j ACCEPT -D FORWARD -i $ifname -o wlan0 2>/dev/null
iptables -j ACCEPT -D FORWARD -m state --state ESTABLISHED,RELATED -i wlan0 -o $ifname 2>/dev/null
iptables -j ACCEPT -D FORWARD -m state --state ESTABLISHED,RELATED -o wlan0 -i $ifname 2>/dev/null
iptables -j ACCEPT -I FORWARD -i $ifname -o wlan0
iptables -j ACCEPT -I FORWARD -m state --state ESTABLISHED,RELATED -i wlan0 -o $ifname
iptables -j ACCEPT -I FORWARD -m state --state ESTABLISHED,RELATED -o wlan0 -i $ifname

# --- Raise limits ---
ulimit -l unlimited
ulimit -n 65536

# --- Launch crosvm ---
/data/local/tmp/crosvm --log-level debug run \
    --socket "$SOCK" \
    --lock-guest-memory \
    --disable-sandbox \
    --no-balloon \
    --protected-vm-without-firmware \
    --swiotlb 64 \
    --mem 4096 \
    --cpus 4 \
    --net tap-name=$ifname \
    --shared-dir "$SCRIPT_DIR/rootfs:rootfs:type=fs" \
    --initrd "$SCRIPT_DIR/initrd" \
    --params "rootfstype=virtiofs root=rootfs rw console=hvc0" \
    "$SCRIPT_DIR/Image" \
    >> "$LOG" 2>&1 &

echo "NixOS VM started (pid $!)"
echo "Socket: $SOCK"
echo "Log:    $LOG"
echo "Stop:   sh $SCRIPT_DIR/stopNixOS.sh"
echo "SSH:    ssh root@192.168.8.3"
