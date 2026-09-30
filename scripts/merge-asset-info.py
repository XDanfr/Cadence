"""Preserve the asset compiler's icon metadata in the packaged app."""
import plistlib
from pathlib import Path

bundle_info = Path("dist/Cadence.app/Contents/Info.plist")
asset_info = Path("dist/asset-info.plist")
with bundle_info.open("rb") as source:
    info = plistlib.load(source)
with asset_info.open("rb") as source:
    info.update(plistlib.load(source))
with bundle_info.open("wb") as output:
    plistlib.dump(info, output)
