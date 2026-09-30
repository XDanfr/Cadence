# Cadence — Icon Composer handoff

Use a 1024 × 1024 canvas for the Mac icon. Import `cadence-timer-purple.png` as a foreground layer; it is transparent, already positioned, and contains only the exact SF Symbol used in the app. `cadence-timer-white.png` is an optional white version for recolouring or a dark variant.

Symbol: **timer**, **Medium** weight. The legacy renderer requests a 573.44pt symbol, then fits its aspect ratio into a 614.4 × 634.88px region centred at (512, 512). These PNGs preserve that placement. Keep the imported layer at its original canvas size rather than fitting its opaque bounds to the entire icon.

## Original colours

sRGB decimal components are authoritative; hex is rounded to 8-bit.

| Element | sRGB | Hex | Stop |
|---|---|---|---|
| Timer purple | 0.345, 0.337, 0.839 | #5856D6 | Solid |
| Background lavender | 0.84, 0.79, 1.0 | #D6C9FF | 0% |
| Background pale lilac | 0.96, 0.94, 1.0 | #F5F0FF | 50% |
| Background cyan | 0.64, 0.91, 1.0 | #A3E8FF | 100% |

The background is **linear**, running from the upper left (lavender) to the lower right (cyan). AppKit angle: **−45°**; the equivalent CSS direction is **135deg**. It has no radius or radial centre.

## Original highlight geometry

Coordinates below use an origin at the **top left** of the 1024px canvas.

- Elliptical highlight bounds: x = 122.88, y = −71.68, width = 819.2, height = 563.2px.
- Centre: (532.48, 209.92px), or (52%, 20.5%).
- Ellipse radii: 409.6px horizontally and 281.6px vertically (40% and 27.5%).
- Fill is a **linear vertical** gradient inside the ellipse: white at 65% opacity at the top, fading to white at 0% at the bottom. It is not a radial gradient.
- The highlight is clipped to the original background tile.

## Original corner and border geometry

The current `.icns` has a baked rounded rectangle, not Apple's dynamic Liquid Glass:

- Tile bounds: 51.2px inset on each side, width/height 921.6px (5% inset; 90% size).
- Corner radius: 225.28px (22% of the full canvas).
- White border: 70% opacity, 12.288px line width (1.2% of full canvas).

**Do not copy the baked tile mask or border into the Icon Composer foreground.** Use its full-canvas background and system-provided icon mask. Use its Liquid Glass controls for specular highlights/refraction instead of baking the old ellipse into the timer layer. The legacy radius was an approximation, not the platform's official icon mask.

## Appearance handoff

Create Default and Dark variants (and preview Mono/clear/tinted as desired) in Icon Composer, using its appearance controls. The old `.icns` is a single rendered appearance; the app does not yet compile a `.icon` package or expose an icon-appearance override.

Once the `.icon` is ready, add it to `Resources/` and update packaging to compile it with Apple's asset tooling. Keep a pre-Tahoe `.icns` fallback and test both Sequoia and Tahoe. Merely copying the `.icon` directory into the app bundle is not enough to adopt the layered icon.

References:
- https://developer.apple.com/icon-composer/
- https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
- https://developer.apple.com/design/human-interface-guidelines/app-icons/
