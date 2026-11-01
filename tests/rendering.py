#!/usr/bin/env python3
"""Verify real renderer pixels and movement against a synthetic wallpaper."""
import importlib.util
from pathlib import Path
import tempfile

from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("wallpaper_renderer", root / "clearclock/render.py")
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)

with tempfile.TemporaryDirectory(prefix="clearclock-render-") as tmp:
    folder = Path(tmp)
    wall = Image.new("RGB", (1600, 1000))
    draw = ImageDraw.Draw(wall)
    for x in range(1600):
        draw.line((x,0,x,1000), fill=(10, 25, 90) if x < 800 else (240, 180, 90))
    for y in range(0,1000,12):
        draw.line((0,y,1599,y),fill=(60,80,100),width=2)
    wall.save(folder / "wallpaper.png")
    request = dict(wallpaper=str(folder/"wallpaper.png"), fill="crop", gradient=True,
                   glass=False, glassStrength=.5, fontDir=str(root/"clearclock/fonts"),
                   output=dict(width=1600,height=1000,x=0,y=0),
                   widget=dict(cx=350,cy=500,box_width=0,box_height=0,rotation=0),
                   clock="12.59",day="Sunday",date="1 NOVEMBER 2026", primary="#a5c5ff",
                   colors=dict(clock="#ffffff",day="#5e4573",date="#ffffff"),
                   settings=dict(clockFontSize=160,dayFontSize=75,dateFontSize=22,dateGap=-20,
                                 dateLetterSpacing=2,clockBoldText=True))
    left = renderer.render(request,folder/"left.png")
    request["widget"]["cx"] = 1250
    right = renderer.render(request,folder/"right.png")
    assert left["stops"] != right["stops"], "moving the clock must change the sampled gradient"
    with Image.open(folder/"left.png") as image:
        assert image.getpixel((0,0))[3] == 0, "transparent mode must not add a backdrop"
        opaque_colors = {pixel[:3] for count,pixel in image.getcolors(image.width*image.height) if pixel[3]==255}
        assert len(opaque_colors) > 40, "the gradient must vary within glyphs, not only between digits"
    request["fontGlass"] = True
    renderer.render(request,folder/"font.png")
    with Image.open(folder/"font.png") as image:
        assert image.getpixel((0,0))[3] == 0
        translucent = sum(count for count,pixel in image.getcolors(image.width*image.height) if 190 < pixel[3] < 245)
        assert translucent > 1000, "frosted font must have translucent glyph interiors"
        assert image.tobytes() != Image.open(folder/"right.png").tobytes()
    request["glass"] = True
    glass = renderer.render(request,folder/"glass.png")
    with Image.open(folder/"glass.png") as image:
        assert image.getpixel((0,0))[3] == 0, "glass must retain rounded transparent corners"
        assert image.getpixel((image.width//2,8))[3] > 0, "glass must draw a real backdrop"
    # Manual colors, Unicode separators, custom fonts, empty date/day, rotation,
    # explicit resize, and every supported wallpaper projection must render.
    request.update(gradient=False,clock="12∶59",day="",date="")
    request["widget"].update(box_width=500,box_height=200,rotation=.2)
    for fill in ("crop","fit","stretch","center","repeat","span"):
        request["fill"] = fill
        result = renderer.render(request,folder/(fill+".png"))
        assert result["width"] > 0 and result["height"] > 0
    assert not list(folder.glob("*.tmp")), "rendered files must be replaced atomically"

print("Position-dependent smooth gradient pixels, glass alpha, resize, rotation, and wallpaper projections passed")
