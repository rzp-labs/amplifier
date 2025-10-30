#!/usr/bin/env bash
#
# Create a zip file of amplifier-dev excluding gitignored files
#
# This script creates a clean zip of the amplifier-dev repository including
# all submodules, but excluding any files that would be gitignored.
#
# Usage:
#   ./create-amplifier-dev-zip.sh
#
# The resulting zip file will be placed in .data/ with a timestamp.
#

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
echo "  Amplifier-Dev Zip Creator"
echo "========================================"
echo ""

# Get the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Ensure amplifier-dev exists and is initialized
if [ ! -d "amplifier-dev" ]; then
    echo "Error: amplifier-dev directory not found"
    exit 1
fi

# Create .data directory if it doesn't exist
mkdir -p .data

# Create a timestamp for the zip file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIP_NAME="amplifier-dev_${TIMESTAMP}.zip"
ZIP_PATH=".data/${ZIP_NAME}"

echo "Creating zip archive..."
echo "  Source: amplifier-dev/"
echo "  Output: ${ZIP_PATH}"
echo ""

# Change to amplifier-dev directory
cd amplifier-dev

# Use git archive to create a zip of tracked files in the main repo
# This automatically excludes gitignored files
echo "→ Archiving main repository..."
git archive --format=zip --prefix=amplifier-dev/ -o "../${ZIP_PATH}" HEAD

# Now handle submodules
# Get list of submodules
SUBMODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

if [ -n "$SUBMODULES" ]; then
    echo "→ Archiving submodules..."

    # Create a temporary directory for submodule archives
    TEMP_DIR=$(mktemp -d)

    for submodule in $SUBMODULES; do
        if [ -d "$submodule/.git" ] || [ -f "$submodule/.git" ]; then
            echo "  • $submodule"

            # Create archive for this submodule
            (
                cd "$submodule"
                git archive --format=zip --prefix="amplifier-dev/${submodule}/" -o "${TEMP_DIR}/${submodule//\//_}.zip" HEAD
            )

            # Merge this submodule archive into the main zip
            # Using Python's zipfile to merge (more reliable than zip command)
            python3 << EOF
import zipfile
import os

main_zip = "../${ZIP_PATH}"
sub_zip = "${TEMP_DIR}/${submodule//\//_}.zip"

# Read submodule zip and append to main zip, skipping duplicates
with zipfile.ZipFile(main_zip, 'a') as main:
    existing_names = set(main.namelist())
    with zipfile.ZipFile(sub_zip, 'r') as sub:
        for item in sub.namelist():
            # Skip directory entries that already exist to avoid warnings
            if item not in existing_names:
                main.writestr(item, sub.read(item))
EOF
        fi
    done

    # Clean up temp directory
    rm -rf "$TEMP_DIR"
fi

cd "$REPO_ROOT"

# Get zip file size
ZIP_SIZE=$(du -h "${ZIP_PATH}" | cut -f1)

echo ""
echo -e "${GREEN}✓${NC} Zip archive created successfully!"
echo ""
echo "Archive details:"
echo "  Location: ${ZIP_PATH}"
echo "  Size: ${ZIP_SIZE}"
echo ""
echo "You can extract it with:"
echo "  unzip ${ZIP_PATH}"
echo ""
