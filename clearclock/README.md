# ClearClock

A Noctalia v5.4.1+ desktop widget port of [qewer33/ClearClock](https://github.com/qewer33/ClearClock), with its original Outfit clock, Smooch weekday overlay, and spaced date.

Enable `nirusaki/clearclock`, then add **ClearClock** under **Settings → Desktop**. Disable the host's **Background** option for a transparent clock. Drag and scale it in the desktop editor.

Per-instance settings cover 12/24-hour time, seconds, separator, IANA time zone, weekday/date visibility, fonts, colors, sizes, bold weights, and date spacing. `ccdefault` selects the bundled fonts. Date patterns use Noctalia/strftime tokens (`%-d %B %Y`), rather than Qt patterns. Empty time zone follows system local time. Invalid zones fall back to local time.

Italic text and text shadows are not exposed by the current Noctalia label API. Date uppercase conversion covers ASCII; set letter spacing to zero to preserve shaping for complex scripts.

GPL-3.0-or-later, following the original ClearClock source. Bundled fonts are SIL OFL 1.1; notices are in `fonts/`.

![Preview](thumbnail.webp)
