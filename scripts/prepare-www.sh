#!/bin/bash
set -e
WWW_DIR="www"

echo "=== Preparing www directory ==="

HTML_FILE=$(find "$WWW_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" | head -1)
if [ -z "$HTML_FILE" ]; then
    echo "No original HTML found, checking for index.html..."
    if [ -f "$WWW_DIR/index.html" ]; then
        echo "index.html already exists, skipping"
        exit 0
    fi
    echo "ERROR: No HTML file found"
    exit 1
fi

echo "Found HTML: $HTML_FILE"

FILES_DIR=$(find "$WWW_DIR" -maxdepth 1 -type d -name "*_files" | head -1)
if [ -z "$FILES_DIR" ]; then
    echo "ERROR: No _files directory found"
    exit 1
fi

echo "Found assets dir: $FILES_DIR"

ASSETS_DIR="$WWW_DIR/assets"
if [ -d "$ASSETS_DIR" ]; then
    rm -rf "$ASSETS_DIR"
fi
cp -r "$FILES_DIR" "$ASSETS_DIR"

echo "Renaming .download files..."
find "$ASSETS_DIR" -name "*.下载" | while read -r file; do
    new_name="${file%.下载}"
    mv "$file" "$new_name"
    echo "  $(basename "$file") -> $(basename "$new_name")"
done

OLD_DIR_NAME=$(basename "$FILES_DIR")

cp "$HTML_FILE" "$HTML_FILE.bak"

sed -i "s|${OLD_DIR_NAME}|assets|g" "$HTML_FILE.bak"
sed -i 's/\.下载//g' "$HTML_FILE.bak"

echo "Removing external font references..."
perl -i -0pe 's/\@font-face\s*\{[^}]*fonts\.gstatic\.com[^}]*\}//gs' "$HTML_FILE.bak"
perl -i -0pe 's/\@font-face\s*\{[^}]*fonts\.googleapis\.com[^}]*\}//gs' "$HTML_FILE.bak"
perl -i -0pe 's/<style[^>]*>\s*<\/style>//gs' "$HTML_FILE.bak"

if ! grep -q "native-bridge.js" "$HTML_FILE.bak"; then
    sed -i 's|</head>|    <script src="./native-bridge.js"></script>\n</head>|' "$HTML_FILE.bak"
    echo "Injected native bridge script"
fi

mv "$HTML_FILE.bak" "$WWW_DIR/index.html"
rm -f "$HTML_FILE"

echo ""
echo "=== Done ==="
echo "index.html size: $(wc -c < "$WWW_DIR/index.html") bytes"
echo "assets files: $(find "$ASSETS_DIR" -type f | wc -l)"
