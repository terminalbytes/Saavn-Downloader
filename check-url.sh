#!/bin/bash

# Check URL script - fetches playlist/album details from JioSaavn API

URL="${1:-$(head -1 urls.txt)}"

if [ -z "$URL" ]; then
    echo "Usage: $0 <url>"
    echo "Or put URL in urls.txt"
    exit 1
fi

# Headers matching the Python script
USER_AGENT="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0"

# Extract token from URL
TOKEN=$(echo "$URL" | rev | cut -d'/' -f1 | rev)

# Detect type
if echo "$URL" | grep -q "playlist"; then
    TYPE="playlist"
elif echo "$URL" | grep -q "album"; then
    TYPE="album"
elif echo "$URL" | grep -q "song"; then
    TYPE="song"
elif echo "$URL" | grep -q "artist"; then
    TYPE="artist"
else
    echo "Unknown URL type"
    exit 1
fi

echo "URL: $URL"
echo "Type: $TYPE"
echo "Token: $TOKEN"
echo ""

# First request - get ID (same as Python script)
API_URL="https://www.jiosaavn.com/api.php?__call=webapi.get&token=${TOKEN}&type=${TYPE}&p=1&n=20&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0"

echo "Fetching ${TYPE} ID..."
RESPONSE=$(curl -s "$API_URL" \
    -H "User-Agent: $USER_AGENT" \
    -H "Cache-Control: private, max-age=0, no-cache")

if command -v jq &> /dev/null; then
    PLAYLIST_ID=$(echo "$RESPONSE" | jq -r '.id // empty' 2>/dev/null)
    LIST_COUNT=$(echo "$RESPONSE" | jq -r '.list_count // empty' 2>/dev/null)

    if [ -n "$PLAYLIST_ID" ]; then
        echo "Playlist ID: $PLAYLIST_ID"
        echo "Listed count: $LIST_COUNT"
        echo ""

        # Second request - get details (same as Python script)
        echo "Fetching playlist details..."
        DETAILS_URL="https://www.jiosaavn.com/api.php?listid=${PLAYLIST_ID}&_format=json&__call=playlist.getDetails"
        DETAILS=$(curl -s "$DETAILS_URL" \
            -H "User-Agent: $USER_AGENT" \
            -H "Cache-Control: private, max-age=0, no-cache")

        # Parse the JSON (response has extra lines)
        DETAILS_JSON=$(echo "$DETAILS" | grep -E '^\{' | head -1)

        echo "$DETAILS_JSON" | jq .

        SONG_COUNT=$(echo "$DETAILS_JSON" | jq '.songs | length // 0' 2>/dev/null)
        echo ""
        echo "--- Songs available for download: ${SONG_COUNT} (playlist shows: ${LIST_COUNT}) ---"
    else
        echo "Could not get playlist ID"
        echo "$RESPONSE" | jq .
    fi
else
    echo "$RESPONSE"
fi
