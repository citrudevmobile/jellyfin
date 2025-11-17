#!/bin/bash
# Enhanced Vinyl Track Finder Script
# Usage: ./find_vinyl_tracks.sh [search_directory]

SEARCH_DIR="${1:-/workspaces/music/jellyfin/media/albums}"

echo "🎵 Enhanced Vinyl Track Search"
echo "=============================="
echo "Searching in: $SEARCH_DIR"
echo ""

# Counter for results
found_count=0

# Check if directory exists
if [ ! -d "$SEARCH_DIR" ]; then
    echo "❌ Error: Directory '$SEARCH_DIR' does not exist!"
    exit 1
fi

# Check if metaflac is installed
if ! command -v metaflac &> /dev/null; then
    echo "❌ Error: metaflac is not installed. Install with: sudo apt install flac"
    exit 1
fi

echo "🔍 Searching for files with vinyl track numbers..."
echo ""

find "$SEARCH_DIR" -name "*.flac" | while read file; do
    # Get all metadata
    metadata=$(metaflac --list "$file")

    # Check for various vinyl track patterns
    if echo "$metadata" | grep -q -E "(TRACKNAME/POSITION|TRACKTOTAL|POSITION.*[A-Z][0-9]|SIDE.*[A-Z][0-9]|[A-Z][0-9].*TRACK)"; then
        found_count=$((found_count + 1))
        echo "🎯 FOUND VINYL TRACK: $file"
        echo "--- Metadata ---"

        # Show relevant track fields
        echo "$metadata" | grep -E "(TRACKNAME|TRACKTOTAL|POSITION|SIDE|TRACKNUMBER|TITLE|ARTIST)" | head -15

        # Also show any field containing A1, B2 patterns
        echo "$metadata" | grep -E "[A-Z][0-9]" | while read line; do
            if echo "$line" | grep -q -v "reference libFLAC"; then
                echo "Pattern match: $line"
            fi
        done

        echo "---"
        echo ""
    fi
done

echo "=========================================="
echo "🎵 Search complete!"
echo "📊 Files with potential vinyl track numbers: $found_count"

# If nothing found, show what track fields DO exist
if [ $found_count -eq 0 ]; then
    echo ""
    echo "💡 No vinyl track numbers found. Common track fields in your collection:"
    find "$SEARCH_DIR" -name "*.flac" | head -20 | while read file; do
        echo "File: $(basename "$file")"
        metaflac --list "$file" | grep -E "^(TRACK|POSITION|SIDE)" | head -3
    done
fi
