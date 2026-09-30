#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -d dist/Cadence.app
dmgbuild_bin="${CADENCE_DMGBUILD:-dmgbuild}"
if ! command -v "$dmgbuild_bin" >/dev/null; then
  echo 'Install the packaging dependency: python3 -m pip install dmgbuild==1.6.7' >&2
  exit 1
fi
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/Cadence.app/Contents/Info.plist)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo 'Invalid app version' >&2; exit 1; fi
swift scripts/installer-artwork.swift dist/installer
"$dmgbuild_bin" -s Resources/Installer/dmg-settings.py "Cadence" "dist/Cadence-$version.dmg"
hdiutil verify "dist/Cadence-$version.dmg"
mkdir -p dist/release
ditto "dist/Cadence-$version.dmg" "dist/release/Cadence-$version.dmg"
ditto "dist/Cadence-macOS.zip" "dist/release/Cadence-$version-macOS.zip"
(cd dist/release && shasum -a 256 "Cadence-$version.dmg" "Cadence-$version-macOS.zip" > SHA256SUMS.txt)
