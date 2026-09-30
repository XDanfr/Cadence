#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export MACOSX_DEPLOYMENT_TARGET=15.0
mkdir -p dist/Cadence.app/Contents/{MacOS,Resources}
for arch in arm64 x86_64; do
  swift build -c release --arch "$arch"
  bin_path="$(swift build -c release --arch "$arch" --show-bin-path)"
  cp "$bin_path/Cadence" "dist/Cadence-$arch"
done
lipo -create dist/Cadence-arm64 dist/Cadence-x86_64 -output dist/Cadence.app/Contents/MacOS/Cadence
cp Resources/Info.plist dist/Cadence.app/Contents/Info.plist
xcrun actool Resources/Colors.xcassets --compile dist/Cadence.app/Contents/Resources --platform macosx --minimum-deployment-target 15.0 --output-partial-info-plist dist/asset-info.plist
swift scripts/icon.swift
iconutil -c icns dist/AppIcon.iconset -o dist/Cadence.app/Contents/Resources/AppIcon.icns
codesign --force --deep --sign - dist/Cadence.app
codesign --verify --deep --strict dist/Cadence.app
plutil -lint dist/Cadence.app/Contents/Info.plist
lipo -info dist/Cadence.app/Contents/MacOS/Cadence
ditto -c -k --sequesterRsrc --keepParent dist/Cadence.app dist/Cadence-macOS.zip
