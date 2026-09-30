"""Finder layout; coordinates and dimensions match installer-artwork.swift."""
import os

app = os.path.abspath(defines.get("app", "dist/Cadence.app"))
artwork = os.path.abspath(defines.get("artwork", "dist/installer"))
format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
icon = os.path.join(app, "Contents", "Resources", "Cadence.icns")
background = os.path.join(artwork, "background.tiff")
window_rect = ((160, 160), (800, 500))
default_view = "icon-view"
show_toolbar = False
show_sidebar = False
show_status_bar = False
show_pathbar = False
show_tab_view = False
include_icon_view_settings = True
icon_size = 128
text_size = 14
label_pos = "bottom"
arrange_by = None
icon_locations = {"Cadence.app": (220, 244), "Applications": (580, 244)}
hide_extensions = ["Cadence.app"]
