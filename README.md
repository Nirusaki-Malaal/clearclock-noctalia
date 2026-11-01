<div align="center">

# ClearClock

**A little typography for your desktop.**

A native [Noctalia](https://noctalia.dev) widget inspired by [qewer33/ClearClock](https://github.com/qewer33/ClearClock).

![ClearClock on a train wallpaper](docs/screenshot-train.png)

![ClearClock on a black hole wallpaper](docs/screenshot-black-hole.png)

</div>

## Install

Requires **Noctalia v5.4.1+**, `curl`, `tar`, and **Python 3 with Pillow** (`python-pillow` on Arch).

```sh
curl -fsSL https://raw.githubusercontent.com/Nirusaki-Malaal/clearclock-noctalia/main/install.sh | sh
```

Then open **Settings → Desktop → Add widget → ClearClock** and use the desktop editor to move and resize it. New widgets are transparent by default.

Run the same command to update. The installer works without sudo, respects your Noctalia/XDG data directory, and keeps your settings.

<details>
<summary>Prefer to inspect the installer first?</summary>

```sh
curl -fsSLO https://raw.githubusercontent.com/Nirusaki-Malaal/clearclock-noctalia/main/install.sh
less install.sh
sh install.sh
```

Use `sh install.sh --no-enable` to install files without contacting the running shell.

</details>

## Make it yours

- **Time:** 12/24-hour format, optional seconds, and your choice of separator.
- **Typography:** bundled Outfit and Smooch fonts, custom fonts, sizes, and weights.
- **Wallpaper gradient:** a smooth color gradient sampled beneath the clock's saved position. Move the clock, save the layout, and its gradient adapts to the new region.
- **Frosted glass font:** translucent digits with a blurred wallpaper fill, fine highlights, and polished edges.
- **Frosted background:** an optional rounded glass card with adjustable frosting. Use it independently of the glass font.
- **Adaptive color:** disable the wallpaper gradient to follow Noctalia's solid palette colors.
- **Custom color:** turn off **Adaptive colors** to choose independent clock, weekday, and date colors.
- **Layout:** toggle the weekday or date, adjust spacing, then scale and position freely.
- **Time zone:** follow your system or choose an IANA zone such as `Asia/Kolkata`.

All options are available in the widget settings. Custom dates use Noctalia tokens, such as `%-d %B %Y` or `%Y-%m-%d`.

Wallpaper gradients and glass use the local wallpaper image directly, including the clock's position, size, rotation, and wallpaper fill mode. They update after saving a placement change. Enable **Frosted glass font** or **Frosted background** in widget settings to try either effect. The surrounding desktop stays transparent by default.

For solid adaptive colors, select **Wallpaper** as Noctalia's theme source to follow its generated palette. Existing explicit background choices are preserved when updating.

## More

[Configuration example](examples/clearclock.toml) · [Development & compatibility](docs/DEVELOPMENT.md) · [Installer](install.sh)

## Credits

Original design by **[qewer33](https://github.com/qewer33/ClearClock)**. Noctalia port by **[Nirusaki](https://github.com/Nirusaki-Malaal)**.

[GPL-3.0-or-later](LICENSE). Outfit and Smooch are bundled under the [SIL Open Font License](clearclock/fonts/Outfit-OFL.txt).
