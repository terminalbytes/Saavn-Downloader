#!/bin/bash
set -e

DOWNLOADS_DIR="/mnt/storage-box/music"
POLL_INTERVAL="${POLL_INTERVAL:-120}"

echo "========================================="
echo "  Saavn Downloader Service"
echo "========================================="
echo "Downloads dir: ${DOWNLOADS_DIR}"
echo "Poll interval: ${POLL_INTERVAL}s"
echo "Exit node: ${TS_EXIT_NODE:-indian}"
echo ""

# Start tailscaled in userspace mode (background)
echo "[tailscale] Starting tailscaled in userspace mode..."
tailscaled --state=/var/lib/tailscale/tailscaled.state --tun=userspace-networking &
TAILSCALED_PID=$!

# Wait for tailscaled to be ready
sleep 3

# Authenticate with Tailscale
if [ -z "$TS_AUTHKEY" ]; then
    echo "[tailscale] ERROR: TS_AUTHKEY not set"
    exit 1
fi

echo "[tailscale] Authenticating..."
tailscale up --authkey="${TS_AUTHKEY}" --hostname="saavn-downloader"

# Set exit node
echo "[tailscale] Setting exit node to ${TS_EXIT_NODE:-indian}..."
tailscale set --exit-node="${TS_EXIT_NODE:-indian}"

echo "[tailscale] Status:"
tailscale status

echo ""
echo "[tailscale] Public IP:"
curl -s ifconfig.me && echo ""

echo ""
echo "[service] Starting download loop (every ${POLL_INTERVAL}s)..."
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "[service] Shutting down..."
    tailscale down
    kill $TAILSCALED_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main polling loop
while true; do
    echo "========================================="
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting download run..."
    echo "========================================="

    # Run the downloader
    python /app/download_reloaded.py -o "${DOWNLOADS_DIR}" -f /app/urls.txt || {
        echo "[service] Download run failed, will retry next cycle"
    }

    # Cleanup partial downloads
    echo "[cleanup] Checking for partial downloads..."
    PARTIAL_COUNT=$(find "${DOWNLOADS_DIR}" -type f -name "*.[0-9][0-9][0-9]" 2>/dev/null | wc -l)
    if [ "$PARTIAL_COUNT" -gt 0 ]; then
        echo "[cleanup] Removing ${PARTIAL_COUNT} partial file(s)..."
        find "${DOWNLOADS_DIR}" -type f -name "*.[0-9][0-9][0-9]" -delete
    else
        echo "[cleanup] No partial downloads found"
    fi

    echo ""
    echo "[service] Sleeping for ${POLL_INTERVAL}s..."
    echo ""

    sleep "${POLL_INTERVAL}" &
    wait $!
done
