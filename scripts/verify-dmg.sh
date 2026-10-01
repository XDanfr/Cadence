#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/Cadence.app/Contents/Info.plist)"
mount_point="$PWD/dist/dmg-check"
mkdir -p "$mount_point"
hdiutil attach "dist/Cadence-$version.dmg" -readonly -nobrowse -mountpoint "$mount_point"
trap 'hdiutil detach "$mount_point"' EXIT
test -d "$mount_point/Cadence.app"
test "$(readlink "$mount_point/Applications")" = /Applications
test -s "$mount_point/.DS_Store"
codesign --verify --deep --strict "$mount_point/Cadence.app"
# Check the actual Finder window, as well as the generated artwork preview.
open "$mount_point"
sleep 3
screencapture -x dist/installer/Finder-preview.png
