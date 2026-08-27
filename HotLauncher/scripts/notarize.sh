#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/HotLauncher.app"
if [[ ! -d "$APP" ]]; then
    echo "missing $APP — run scripts/bundle.sh first" >&2
    exit 1
fi
if [[ -z "${NOTARY_PROFILE:-}" ]]; then
    echo "Set NOTARY_PROFILE to a notarytool keychain profile (notarytool store-credentials)." >&2
    echo "Notarization skipped: no Apple Developer credentials in this environment." >&2
    exit 1
fi
ZIP="${TMPDIR:-/tmp}/HotLauncher.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
echo "Notarized and stapled $APP"
