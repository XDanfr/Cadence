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
# Layered-icon rendering uses Tahoe's asset runtime. CI passes the output
# from a Tahoe job; the app itself is still built and launched on Sequoia.
if [[ -n "${CADENCE_COMPILED_ASSETS:-}" ]]; then
  cp -R "$CADENCE_COMPILED_ASSETS/Resources/." dist/Cadence.app/Contents/Resources/
  cp "$CADENCE_COMPILED_ASSETS/asset-info.plist" dist/asset-info.plist
else
  bash scripts/compile-assets.sh dist/compiled-assets
  cp -R dist/compiled-assets/Resources/. dist/Cadence.app/Contents/Resources/
  cp dist/compiled-assets/asset-info.plist dist/asset-info.plist
fi
python3 scripts/merge-asset-info.py
swift scripts/export-icon-layers.swift
test -s dist/Cadence.app/Contents/Resources/Assets.car
test -s dist/Cadence.app/Contents/Resources/Cadence.icns
codesign --force --deep --sign - dist/Cadence.app
codesign --verify --deep --strict dist/Cadence.app
plutil -lint dist/Cadence.app/Contents/Info.plist
lipo -info dist/Cadence.app/Contents/MacOS/Cadence
ditto -c -k --sequesterRsrc --keepParent dist/Cadence.app dist/Cadence-macOS.zip
