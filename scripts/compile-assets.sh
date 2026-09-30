#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
asset_output="${1:-dist/compiled-assets}"
mkdir -p "$asset_output/Resources"
xcrun actool Resources/Colors.xcassets Resources/Cadence.icon \
  --compile "$asset_output/Resources" \
  --platform macosx --target-device mac --minimum-deployment-target 15.0 \
  --app-icon Cadence --accent-color AccentColor \
  --enable-on-demand-resources NO --output-partial-info-plist "$asset_output/asset-info.plist"
test -s "$asset_output/Resources/Assets.car"
test -s "$asset_output/Resources/Cadence.icns"
plutil -lint "$asset_output/asset-info.plist"
