#!/usr/bin/env python3
"""Exercise installer upgrades and failure paths without changing the desktop."""
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

root = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="clearclock-installer-") as tmp:
    work = Path(tmp)
    archive = work / "source.tar.gz"
    with tarfile.open(archive, "w:gz") as tar:
        tar.add(root / "clearclock", arcname="source/clearclock")
        tar.add(root / "LICENSE", arcname="source/LICENSE")
    mock_bin = work / "bin"
    mock_bin.mkdir()
    (mock_bin / "curl").write_text('''#!/bin/sh
set -eu
[ "${FAIL_DOWNLOAD:-0}" = 0 ] || exit 22
while [ "$#" -gt 0 ]; do
    if [ "$1" = --output ]; then cp "$FIXTURE" "$2"; exit; fi
    shift
done
exit 1
''')
    (mock_bin / "noctalia").write_text('''#!/bin/sh
printf '%s\\n' "$*" >> "$CALL_LOG"
if [ "${FAIL_ACTIVATION:-0}" = 1 ] && [ "$1" = msg ]; then
    echo 'error: no running shell'; exit 1
fi
if [ "${FAIL_LINT:-0}" = 1 ] && [ "$1" = plugins ]; then exit 1; fi
echo ok
''')
    for path in mock_bin.iterdir():
        path.chmod(0o755)
    env = dict(os.environ, PATH=f"{mock_bin}:{os.environ['PATH']}",
               HOME=str(work / "home"), XDG_DATA_HOME=str(work / "xdg data"),
               NOCTALIA_DATA_HOME=str(work / "noctalia data"),
               FIXTURE=str(archive), CALL_LOG=str(work / "calls.log"))
    env.pop("CLEARCLOCK_REF", None)
    destination = work / "noctalia data/noctalia/plugins/clearclock"

    def run(*args, success=True, **extra):
        result = subprocess.run(["sh", str(root / "install.sh"), *args],
                                env=env | extra, capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result

    run("--no-enable")
    assert (destination / "desktop.luau").read_bytes() == (root / "clearclock/desktop.luau").read_bytes()
    assert (destination / "LICENSE").is_file()
    assert not (work / "xdg data/noctalia/plugins/clearclock").exists()
    assert "msg " not in (work / "calls.log").read_text()
    sentinel = destination / "old-version-marker"
    sentinel.write_text("keep on failure")
    for failure in (dict(FAIL_DOWNLOAD="1"), dict(FAIL_LINT="1")):
        run("--no-enable", success=False, **failure)
        assert sentinel.read_text() == "keep on failure"
        assert not list(destination.parent.glob(".clearclock-install.*"))
    malformed = work / "malformed.tar.gz"
    with tarfile.open(malformed, "w:gz") as tar:
        tar.add(root / "README.md", arcname="source/README.md")
    run("--no-enable", success=False, FIXTURE=str(malformed))
    assert sentinel.exists()
    run()
    assert not sentinel.exists(), "upgrades must remove obsolete plugin files"
    calls = (work / "calls.log").read_text()
    assert "msg config-reload" in calls and "msg plugins enable nirusaki/clearclock" in calls
    assert calls.index("msg config-reload") < calls.index("msg plugins disable nirusaki/clearclock") < calls.index("msg plugins enable nirusaki/clearclock"), "upgrades must restart the running plugin to discard stale code"
    assert "automatic activation could not finish" in run(FAIL_ACTIVATION="1").stdout
    run("--bad-option", success=False)
    run("--no-enable", success=False, CLEARCLOCK_REF="../bad")

    shutil.rmtree(destination)
    target = work / "development-checkout"
    target.mkdir()
    destination.symlink_to(target, target_is_directory=True)
    run("--no-enable", success=False)
    assert destination.is_symlink() and target.is_dir()
    destination.unlink()

    # XDG fallback works without Noctalia's explicit override.
    env.pop("NOCTALIA_DATA_HOME")
    run("--no-enable")
    assert (work / "xdg data/noctalia/plugins/clearclock/desktop.luau").is_file()
    assert "Usage:" in run("--help").stdout

print("Installer fresh install, upgrade, activation, failures, symlinks, and XDG tests passed")
