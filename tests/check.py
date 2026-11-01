#!/usr/bin/env python3
"""Validate distribution metadata and run the entry's behavioral tests."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

root = Path(__file__).resolve().parents[1]
plugin = root / "clearclock"
manifest = tomllib.loads((plugin / "plugin.toml").read_text())
catalog = tomllib.loads((root / "catalog.toml").read_text())["plugin"][0]
for key in catalog:
    assert manifest[key] == catalog[key], f"catalog mismatch: {key}"
entry = manifest["desktop_widget"][0]
assert (plugin / entry["entry"]).is_file()
translations = json.loads((plugin / "translations/en.json").read_text())
settings = entry["setting"]
assert len({s["key"] for s in settings}) == len(settings)
for setting in settings:
    assert setting["label_key"] in translations
    if "min" in setting:
        assert setting["min"] <= setting["default"] <= setting["max"]
assert len(list((plugin / "fonts").glob("*.ttf"))) == 3
assert len(list((plugin / "fonts").glob("*-OFL.txt"))) == 2

# Generate test defaults directly from the manifest to catch schema drift.
with tempfile.TemporaryDirectory() as tmp:
    harness = Path(tmp)
    (harness / "tests").mkdir()
    (harness / "clearclock").symlink_to(plugin, target_is_directory=True)
    values = []
    for setting in settings:
        value = setting["default"]
        encoded = json.dumps(value, ensure_ascii=False)
        values.append(f'[{json.dumps(setting["key"])}] = {encoded}')
    (harness / "tests/defaults.lua").write_text("return {\n" + ",\n".join(values) + "\n}\n")
    lua = shutil.which("lua5.4") or shutil.which("lua")
    if not lua:
        raise SystemExit("Install Lua 5.4 to run the behavioral harness")
    subprocess.run([lua, str(root / "tests/widget.lua"), str(harness)], check=True)
subprocess.run(["noctalia", "plugins", "lint", str(plugin)], check=True)
print("Manifest, catalog, translation, and font license checks passed")
