#!/bin/bash

# Exit on any error
set -e

# Get absolute path to current directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOWNLOADS_DIR="${CURRENT_DIR}/downloads"

echo "Setting Tailscale exit node to Indian..."
tailscale set --exit-node=indian

# Run the download script
echo "Starting downloads..."
python "${CURRENT_DIR}/download_reloaded.py" -o "${DOWNLOADS_DIR}" -f "${CURRENT_DIR}/urls.txt"

# Reset exit node (empty means no exit node)
echo "Resetting Tailscale exit node..."
tailscale set --exit-node=

# Cleanup partial downloads (files ending with .000, .001, etc.)
echo "Cleaning up partial downloads..."
PARTIAL_FILES=$(find "${DOWNLOADS_DIR}" -type f -name "*.[0-9][0-9][0-9]" 2>/dev/null)
if [ -n "$PARTIAL_FILES" ]; then
    echo "Found partial files to delete:"
    echo "$PARTIAL_FILES"
    find "${DOWNLOADS_DIR}" -type f -name "*.[0-9][0-9][0-9]" -delete
    echo "Partial downloads cleaned up."
else
    echo "No partial downloads found."
fi

# Upload to remote storage
echo "Uploading to remote storage..."
rclone -v copy "${DOWNLOADS_DIR}/" neon:/mnt/storage-box/music --progress --transfers=20

echo "All tasks completed successfully!"