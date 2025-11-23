#!/bin/sh

set -e

PATCHES_DIR="patches"
SOURCE_DIR="hath"

echo "Applying patches from $PATCHES_DIR directory..."

# Check if patches directory exists
if [ ! -d "$PATCHES_DIR" ]; then
    echo "Error: Patches directory $PATCHES_DIR not found!"
    exit 1
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR not found!"
    exit 1
fi

# Change to source directory
cd "$SOURCE_DIR"

# Find and sort patch files (numeric order first, then alphabetical)
find "../$PATCHES_DIR" -name "*.patch" | sort | while IFS= read -r patch; do
    patch_name=$(basename "$patch")

    echo "Applying $patch_name..."

    # Check if patch can be applied cleanly
    if patch -p1 --dry-run < "$patch" > /dev/null 2>&1; then
        patch -p1 < "$patch"
        echo "✅ $patch_name applied successfully"
    else
        echo "❌ Failed to apply $patch_name (patch may already be applied or there are conflicts)"
        echo "Attempting to check if patch is already applied..."

        # Check if this patch is already applied by trying to reverse it
        if patch -p1 --dry-run -R < "$patch" > /dev/null 2>&1; then
            echo "⚠️  $patch_name appears to already be applied, skipping..."
        else
            echo "❌ $patch_name has conflicts or cannot be applied"
            # In a piped loop, 'exit 1' only exits the subshell (the loop), not the script.
            # To strict fail, we create a marker file or strictly rely on 'set -e' behavior 
            # combined with the command failing.
            exit 1
        fi
    fi
    echo
done

echo "All patches processed successfully!"
