#!/usr/bin/env bash
# Builds the production app bundle, obfuscated, and keeps its debug
# symbols (needed to read crash stack traces from this exact build).
#
# Obfuscation makes the app harder to take apart; it does NOT make the
# OpenSubtitles key secret: the key is still inside the app.
set -euo pipefail
cd "$(dirname "$0")/.."

KEYS=config/opensubtitles.json
if [[ ! -f "$KEYS" ]]; then
  echo "Missing $KEYS: copy config/opensubtitles.example.json and add the key." >&2
  exit 1
fi

flutter build appbundle --release \
  --flavor production -t lib/main_production.dart \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file="$KEYS"

# build/ is wiped by `flutter clean`: keep a copy per version (git-ignored;
# back it up somewhere safe, e.g. next to the uploaded bundle).
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
mkdir -p "release-symbols/$VERSION"
cp -R build/symbols/. "release-symbols/$VERSION/"
echo "Symbols kept in release-symbols/$VERSION"
echo "Read a crash: flutter symbolize -i <stack.txt> -d release-symbols/$VERSION/app.android-arm64.symbols"
