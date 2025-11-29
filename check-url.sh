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

# First request - get ID
API_URL="https://www.jiosaavn.com/api.php?__call=webapi.get&token=${TOKEN}&type=${TYPE}&p=1&n=20&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0"

echo "Fetching ${TYPE} info..."
echo ""

RESPONSE=$(curl -s "$API_URL" \
    -H "User-Agent: $USER_AGENT" \
    -H "Cache-Control: private, max-age=0, no-cache")

# Pretty print if jq is available
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq .

    # Get song counts
    LIST_COUNT=$(echo "$RESPONSE" | jq -r '.list_count // empty' 2>/dev/null)
    RETURNED_COUNT=$(echo "$RESPONSE" | jq '.list | length // .songs | length // 0' 2>/dev/null)
    echo ""
    echo "--- Total songs: ${LIST_COUNT:-$RETURNED_COUNT} (returned in response: ${RETURNED_COUNT}) ---"
else
    echo "$RESPONSE"
fi
