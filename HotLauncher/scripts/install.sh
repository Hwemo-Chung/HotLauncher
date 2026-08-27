#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/HotLauncher.app"
DEST="/Applications/HotLauncher.app"

if [[ ! -d "$SRC" ]]; then
    echo "missing $SRC — run scripts/bundle.sh first" >&2
    exit 1
fi

killall HotLauncher 2>/dev/null || true
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true
echo "Installed $DEST"
echo "Open with: open $DEST"
