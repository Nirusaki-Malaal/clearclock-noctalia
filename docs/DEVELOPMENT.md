# Development

ClearClock targets Noctalia v5.4.1 and Luau plugin API 31. Python 3 and Pillow 9.2+ render wallpaper gradients and glass effects. Solid mode stays native to Noctalia.

## Local install

```sh
plugin_dir="${NOCTALIA_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/noctalia/plugins/clearclock"
mkdir -p "$plugin_dir"
cp -R clearclock/. "$plugin_dir/"
noctalia msg config-reload
noctalia msg plugins disable nirusaki/clearclock
noctalia msg plugins enable nirusaki/clearclock
```

After an atomic directory replacement, restart the plugin explicitly. Reloading configuration and enabling an already enabled plugin can leave an existing desktop runtime on old code. The curl installer performs the disable/enable cycle for updates.

For development, symlink `clearclock/` into the plugins directory. Luau module changes hot-reload; restart the plugin after Python renderer edits if a cached request has not otherwise changed.

## Rendering modes

- **Solid adaptive:** retained `primary`, `on_primary`, and `on_surface` roles repaint with Noctalia's active palette. Disable Wallpaper gradient to select this mode.
- **Wallpaper gradient:** sample three regions under the clock, blend in a little palette accent, adjust for local luminance, and render a continuous gradient through a high-resolution text mask. Moving or rotating the clock changes the sampled region.
- **Frosted glass font:** a softened wallpaper fill inside translucent clock digits, with a directional highlight, lower edge, and subtle shadow. The weekday/date stay legible as solid text.
- **Frosted background:** a separate blurred, tinted, rounded wallpaper crop beneath the whole widget. Its frosting strength is independent of font frosting.
- **Manual:** disable Adaptive colors to use individual clock, weekday, and date colors. Glass effects remain available.

The Python renderer uses the bundled fonts or resolves a custom family with `fc-match`. It renders at 2x resolution and writes PNGs atomically. Each instance uses two alternating files, keeping the cache bounded. Identical requests reuse the current image. Updates are asynchronous, stale results cannot replace a newer mode, and failures fall back to native text with retry backoff. Seconds mode can launch a render every second; minute-only mode avoids this extra work when the content is unchanged.

## Position and background defaults

Noctalia's desktop script API does not expose an instance ID or unsaved editor geometry. The defaults service binds a hidden `renderInstance` setting to each saved widget ID. The renderer then reads that instance's saved position, size, rotation, and output. Changes appear after saving the editor, rather than while dragging an unsaved preview.

Coordinates use the output's logical dimensions, so fractional display scaling does not change the sampled region. Wallpaper crop, fit, stretch, center, repeat, and span projections are supported. Wallpaper image paths and mtimes participate in cache invalidation.

The current implementation samples the configured wallpaper image, not the compositor's live contents. Windows, video wallpapers, compositor effects, and wallpaper transitions are not captured. Contrast is improved from regional samples; highly detailed wallpaper can still benefit from the frosted background. For a mirrored or identity-selected monitor, use an unambiguous output selector.

Noctalia v5.4.1 hard-codes plugin backgrounds to enabled. Every two seconds the defaults service supplies `background = false` only for ClearClock instances without an explicit background choice. Other widgets, settings, and explicit background choices are preserved. Instance association and background defaults use one leaf merge through argument-array IPC, including quoted widget IDs. Errors back off. The instance association is hidden from normal widget settings.

For declarative placement, merge [examples/clearclock.toml](../examples/clearclock.toml) into your configuration. Append its ID to an existing `widget_order`; unlisted IDs are ignored. GUI overrides take precedence over config files.

## Verification

Requires Python 3.11+, Pillow, Lua 5.4, and Noctalia:

```sh
python3 tests/check.py
python3 tests/installer.py
python3 tests/rendering.py
```

The checks cover manifest/catalog consistency, translations, settings lint, actual Luau entry behavior, transparent defaults, quoted IDs, asynchronous caching and fallback, installer upgrades and restart order, and pixel-level gradient/glass behavior. Synthetic wallpaper tests move the clock across different colors and verify that gradient stops change, glyphs contain a continuous gradient, and glass modes preserve transparent corners.

The complete flow was also tested in an isolated nested Niri/Noctalia session with separate configuration, data, and state directories, using multiple independently positioned widgets.

## References

- [Manifest and settings](https://docs.noctalia.dev/noctalia/v5.4.1/plugins/development/manifest/)
- [Declarative desktop UI](https://docs.noctalia.dev/noctalia/v5.4.1/plugins/development/declarative-ui/)
- [Runtime API](https://docs.noctalia.dev/noctalia/v5.4.1/plugins/development/runtime-api/)
- [Desktop widget configuration](https://docs.noctalia.dev/noctalia/v5.4.1/desktop/widgets/)
- [Development and distribution](https://docs.noctalia.dev/noctalia/v5.4.1/plugins/development/workflow/)

Original composition, defaults, and bundled font files come from [qewer33/ClearClock](https://github.com/qewer33/ClearClock), revision `fd9e4795d24ab80c45846a634c3c844850674c51`. Its QML declares GPL-3.0-or-later; this port uses the same license. [LICENSE](../LICENSE) contains the full text. Outfit and Smooch are distributed under SIL OFL 1.1; notices are in `clearclock/fonts/`.
