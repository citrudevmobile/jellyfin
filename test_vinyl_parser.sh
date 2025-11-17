#!/bin/bash

# Vinyl Parser Test Script for Jellyfin
# This script creates test files with vinyl track numbers to verify the parser works

set -e  # Exit on any error

# Configuration
MUSIC_ROOT="/workspaces/music/jellyfin/media/albums"
TEST_DIR="$MUSIC_ROOT/_Vinyl Parser Test"
SOURCE_ALBUM="$MUSIC_ROOT/The Vels/The Vels - House Of Miracles (1988) [FLAC] {422-826 804-1M-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if music directory exists
    if [ ! -d "$MUSIC_ROOT" ]; then
        log_error "Music directory not found: $MUSIC_ROOT"
        exit 1
    fi

    # Check if source album exists
    if [ ! -d "$SOURCE_ALBUM" ]; then
        log_error "Source album not found: $SOURCE_ALBUM"
        log_info "Available albums:"
        find "$MUSIC_ROOT" -maxdepth 2 -type d -name "*" | head -10
        exit 1
    fi

    # Check if metaflac is installed
    if ! command -v metaflac &> /dev/null; then
        log_error "metaflac is not installed. Install with: sudo apt install flac"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Cleanup any previous test files
cleanup_previous_test() {
    log_info "Cleaning up previous test files..."
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        log_success "Removed previous test directory"
    fi
}

# Create test directory
create_test_directory() {
    log_info "Creating test directory..."
    mkdir -p "$TEST_DIR"
    log_success "Created test directory: $TEST_DIR"
}

# Create test files with vinyl track numbers
create_test_files() {
    log_info "Creating test files with vinyl track numbers..."

    # Test Case 1: A1 format (should parse as track 1)
    log_info "Creating test case A1 → 1"
    cp "$SOURCE_ALBUM/01. Danger Zone.flac" "$TEST_DIR/01 - Test Track A1.flac"
    metaflac --remove-tag=TRACKNUMBER "$TEST_DIR/01 - Test Track A1.flac"
    metaflac --set-tag="TRACKNAME/POSITION=A1" "$TEST_DIR/01 - Test Track A1.flac"
    metaflac --set-tag="TITLE=Test Track A1" "$TEST_DIR/01 - Test Track A1.flac"
    metaflac --set-tag="ARTIST=Test Artist" "$TEST_DIR/01 - Test Track A1.flac"
    metaflac --set-tag="ALBUM=Vinyl Parser Test Album" "$TEST_DIR/01 - Test Track A1.flac"

    # Test Case 2: B2 format (should parse as track 22)
    log_info "Creating test case B2 → 22"
    cp "$SOURCE_ALBUM/02. Girl Most Likely To.flac" "$TEST_DIR/02 - Test Track B2.flac"
    metaflac --remove-tag=TRACKNUMBER "$TEST_DIR/02 - Test Track B2.flac"
    metaflac --set-tag="TRACKTOTAL=B2" "$TEST_DIR/02 - Test Track B2.flac"
    metaflac --set-tag="TITLE=Test Track B2" "$TEST_DIR/02 - Test Track B2.flac"
    metaflac --set-tag="ARTIST=Test Artist" "$TEST_DIR/02 - Test Track B2.flac"
    metaflac --set-tag="ALBUM=Vinyl Parser Test Album" "$TEST_DIR/02 - Test Track B2.flac"

    # Test Case 3: C3 format with different field (should parse as track 43)
    log_info "Creating test case C3 → 43"
    cp "$SOURCE_ALBUM/03. Way With Words.flac" "$TEST_DIR/03 - Test Track C3.flac"
    metaflac --remove-tag=TRACKNUMBER "$TEST_DIR/03 - Test Track C3.flac"
    metaflac --set-tag="POSITION=C3" "$TEST_DIR/03 - Test Track C3.flac"
    metaflac --set-tag="TITLE=Test Track C3" "$TEST_DIR/03 - Test Track C3.flac"
    metaflac --set-tag="ARTIST=Test Artist" "$TEST_DIR/03 - Test Track C3.flac"
    metaflac --set-tag="ALBUM=Vinyl Parser Test Album" "$TEST_DIR/03 - Test Track C3.flac"

    # Test Case 4: Mixed format 1A (should parse as track 1)
    log_info "Creating test case 1A → 1"
    cp "$SOURCE_ALBUM/04. Face To Face.flac" "$TEST_DIR/04 - Test Track 1A.flac"
    metaflac --remove-tag=TRACKNUMBER "$TEST_DIR/04 - Test Track 1A.flac"
    metaflac --set-tag="TRACKNAME/POSITION=1A" "$TEST_DIR/04 - Test Track 1A.flac"
    metaflac --set-tag="TITLE=Test Track 1A" "$TEST_DIR/04 - Test Track 1A.flac"
    metaflac --set-tag="ARTIST=Test Artist" "$TEST_DIR/04 - Test Track 1A.flac"
    metaflac --set-tag="ALBUM=Vinyl Parser Test Album" "$TEST_DIR/04 - Test Track 1A.flac"

    # Test Case 5: Standard number as fallback (should parse as track 5)
    log_info "Creating test case with standard track number 5"
    cp "$SOURCE_ALBUM/05. Hand In Hand.flac" "$TEST_DIR/05 - Test Track Standard.flac"
    metaflac --set-tag="TITLE=Test Track Standard" "$TEST_DIR/05 - Test Track Standard.flac"
    metaflac --set-tag="ARTIST=Test Artist" "$TEST_DIR/05 - Test Track Standard.flac"
    metaflac --set-tag="ALBUM=Vinyl Parser Test Album" "$TEST_DIR/05 - Test Track Standard.flac"

    log_success "Created all test files"
}

# Verify test files were created correctly
verify_test_files() {
    log_info "Verifying test files..."

    echo ""
    echo -e "${BLUE}=== Test Files Created ===${NC}"
    ls -la "$TEST_DIR"

    echo ""
    echo -e "${BLUE}=== Test File Metadata ===${NC}"
    for file in "$TEST_DIR"/*.flac; do
        echo -e "${YELLOW}File: $(basename "$file")${NC}"
        metaflac --list "$file" | grep -E "(TITLE|ARTIST|ALBUM|TRACKNAME|TRACKTOTAL|POSITION|TRACKNUMBER)" | while read line; do
            echo "  $line"
        done
        echo ""
    done

    log_success "Test files verified"
}

# Display instructions for testing
display_instructions() {
    echo ""
    echo -e "${GREEN}🎵 VINYL PARSER TEST SETUP COMPLETE!${NC}"
    echo ""
    echo -e "${BLUE}📋 Expected Parser Behavior:${NC}"
    echo "  • A1 should parse as track 1"
    echo "  • B2 should parse as track 22"
    echo "  • C3 should parse as track 43"
    echo "  • 1A should parse as track 1"
    echo "  • Standard 5 should remain as track 5"
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "  1. Trigger a library scan in Jellyfin:"
    echo "     - Go to Dashboard → Advanced → Library → Scan All Libraries"
    echo "     - OR wait for automatic scan (usually within 5 minutes)"
    echo ""
    echo "  2. Monitor the Jellyfin logs for:"
    echo "     ${YELLOW}🎵 PARSE_TRACK_NUMBER - Found vinyl candidate${NC}"
    echo "     ${YELLOW}🎵 PARSE_TRACK_NUMBER - Parsed vinyl as${NC}"
    echo ""
    echo "  3. Check in Jellyfin Music Library:"
    echo "     - Look for 'Vinyl Parser Test Album'"
    echo "     - Verify tracks are in correct order"
    echo ""
    echo -e "${BLUE}🧹 Cleanup When Done:${NC}"
    echo "  Run: ${YELLOW}rm -rf '$TEST_DIR'${NC}"
    echo "  Then trigger another library scan"
    echo ""
    echo -e "${GREEN}The test files are now ready for Jellyfin to discover!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}        JELLYFIN VINYL PARSER TEST       ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""

    check_prerequisites
    cleanup_previous_test
    create_test_directory
    create_test_files
    verify_test_files
    display_instructions
}

# Run the main function
main
