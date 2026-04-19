#!/usr/bin/env bash
# Build MCPTray and install to /Applications.
# Requires: Xcode 26+, xcodegen (brew install xcodegen).
set -euo pipefail

cd "$(dirname "$0")"

command -v xcodegen >/dev/null || { echo "xcodegen missing — run: brew install xcodegen"; exit 1; }

echo "→ Generating Xcode project"
xcodegen generate --quiet

echo "→ Building (Release)"
xcodebuild \
  -project MCPTray.xcodeproj \
  -scheme MCPTray \
  -configuration Release \
  -derivedDataPath build \
  -destination 'platform=macOS' \
  build \
  | xcbeautify 2>/dev/null || xcodebuild \
      -project MCPTray.xcodeproj \
      -scheme MCPTray \
      -configuration Release \
      -derivedDataPath build \
      -destination 'platform=macOS' \
      build > build.log

APP_SRC="build/Build/Products/Release/MCPTray.app"
if [ ! -d "$APP_SRC" ]; then
  echo "Build failed — see build.log"
  exit 1
fi

echo "→ Installing to /Applications"
rm -rf /Applications/MCPTray.app
cp -R "$APP_SRC" /Applications/MCPTray.app

echo "→ Done. Launching"
open /Applications/MCPTray.app
