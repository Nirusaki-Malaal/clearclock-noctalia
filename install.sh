#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu

enable=true
case "${1:-}" in
    --no-enable) enable=false; shift ;;
    -h|--help)
        printf '%s\n' 'Usage: sh install.sh [--no-enable]' \
            'Installs or updates ClearClock for the current user.' \
            '--no-enable  Copy files without contacting the running Noctalia shell.' \
            'CLEARCLOCK_REF selects a Git branch, tag, or commit (default: main).'
        exit 0 ;;
esac
[ "$#" -eq 0 ] || { printf '%s\n' 'Unknown option. Use --help.' >&2; exit 1; }
for tool in curl tar mktemp; do
    command -v "$tool" >/dev/null 2>&1 || {
        printf 'Missing dependency: %s\n' "$tool" >&2
        exit 1
    }
done
if "$enable" && ! command -v noctalia >/dev/null 2>&1; then
    printf '%s\n' 'Install Noctalia v5.4.1+ first, or use --no-enable to copy files only.' >&2
    exit 1
fi

ref=${CLEARCLOCK_REF:-main}
case "$ref" in
    *[!a-zA-Z0-9._/-]*|/*|*..*) printf '%s\n' 'Invalid CLEARCLOCK_REF.' >&2; exit 1 ;;
esac
data_home=${NOCTALIA_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}
parent=$data_home/noctalia/plugins
destination=$parent/clearclock
if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -d "$destination" ]; }; then
    printf 'Refusing to replace a symlink or non-directory: %s\n' "$destination" >&2
    exit 1
fi
mkdir -p "$parent"
work=$(mktemp -d "$parent/.clearclock-install.XXXXXX")
cleanup() {
    # Restore the previous installation if the final move was interrupted.
    if [ -d "$work/previous" ] && [ ! -e "$destination" ]; then
        mv "$work/previous" "$destination"
    fi
    rm -rf "$work"
}
trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'Downloading ClearClock (%s)…\n' "$ref"
curl --fail --silent --show-error --location --retry 3 --connect-timeout 15 \
    --max-time 120 --proto '=https' --proto-redir '=https' \
    --output "$work/source.tar.gz" \
    "https://codeload.github.com/Nirusaki-Malaal/clearclock-noctalia/tar.gz/$ref"
mkdir "$work/source"
tar -xzf "$work/source.tar.gz" -C "$work/source"
set -- "$work/source/"*/clearclock
[ "$#" -eq 1 ] && [ -f "$1/plugin.toml" ] && [ -f "$1/desktop.luau" ] || {
    printf '%s\n' 'The download does not contain a ClearClock plugin.' >&2
    exit 1
}
staged=$1
cp "$staged/../LICENSE" "$staged/LICENSE"
if command -v noctalia >/dev/null 2>&1; then
    noctalia plugins lint "$staged"
fi

# Prepare everything before replacing the installed files. Settings live in
# Noctalia's separate config/state directories and are never edited here.
if [ -d "$destination" ]; then
    mv "$destination" "$work/previous"
fi
mv "$staged" "$destination"
printf '\nInstalled: %s\n' "$destination"
if "$enable"; then
    if noctalia msg config-reload >"$work/activation.log" 2>&1 \
        && noctalia msg plugins enable nirusaki/clearclock >>"$work/activation.log" 2>&1 \
        && ! grep -qi '^error:' "$work/activation.log"; then
        printf '%s\n' 'Enabled in Noctalia.'
    else
        printf '%s\n' 'Files installed; automatic activation could not finish.'
        cat "$work/activation.log" >&2
        printf '%s\n' 'Once Noctalia is running, run:' \
            '  noctalia msg config-reload' \
            '  noctalia msg plugins enable nirusaki/clearclock'
    fi
fi
printf '\n%s\n' 'Open Settings → Desktop, add ClearClock, and turn off Background.'
