-- Verify render caching, placement updates, and asynchronous mode switches.
local root = arg[1] or "."
local config = {renderInstance = "clock", adaptiveGradients = true, adaptiveColors = true,
    frostedGlass = false, glassStrength = .5, frostedFont = false, fontGlassStrength = .55}
local widget = {output = "eDP-1", cx = 300, cy = 400}
local active, calls, callback, now = nil, 0, nil, 100
local wallTime = os.time
os.time = function() return now end
local function encode(value)
    if type(value) ~= "table" then return tostring(value) end
    local keys, parts = {}, {}
    for key in pairs(value) do table.insert(keys,key) end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for _, key in ipairs(keys) do table.insert(parts,tostring(key)..":"..encode(value[key])) end
    return "{"..table.concat(parts,",").."}"
end
noctalia = {
    getConfig = function(key) return config[key] end,
    getSetting = function(path)
        if path == "desktop_widgets" then return {widget = {clock = widget}} end
        return {fill_mode = "crop"}
    end,
    outputs = function() return {{name = "eDP-1", width = 1536, height = 960}} end,
    wallpaperPath = function() return "/wallpaper.png" end,
    fileInfo = function() return {mtime = 1} end,
    pluginDir = function() return "/plugin" end,
    pluginDataDir = function() return "/cache" end,
    getColor = function() return "#a5c5ff" end,
    json = {encode = encode, decode = function(value)
        if value == "ok" then return {width=600,height=300} end
        error("invalid JSON")
    end},
    runAsync = function(argv, cb)
        assert(argv[1] == "python3" and argv[2] == "/plugin/render.py")
        assert(argv[6]:match("^/cache/wallpaper%-636c6f636b%-[01]%.png$"))
        calls, callback = calls+1, cb
        return true
    end,
    log = function() end,
}
desktopWidget = {render = function(tree) active = tree end}
ui = {image = function(props) return {kind = "image", props=props} end}
local module = assert(loadfile(root.."/clearclock/wallpaper.luau"))()
local fallback = {kind="native"}
module.render({},fallback)
assert(calls == 1 and active == fallback)
module.render({},fallback)
assert(calls == 1, "pending requests must be coalesced")
callback({exitCode=0,stdout="ok",stderr=""})
assert(active.kind == "image")
module.render({},fallback)
assert(calls == 1, "unchanged time, wallpaper and placement must reuse the image")
widget.cx = 900
module.render({},fallback)
assert(calls == 2, "moving the saved clock must refresh the wallpaper crop")
module.reset()
desktopWidget.render(fallback)
callback({exitCode=0,stdout="ok",stderr=""})
assert(active == fallback, "late renderer callbacks must not overwrite solid mode")
module.render({},fallback)
assert(calls == 3)
callback({exitCode=1,stdout="",stderr="failure"})
assert(active == fallback)
module.render({},fallback)
assert(calls == 3, "renderer failures must back off")
now = 131
module.render({},fallback)
assert(calls == 4)
callback({exitCode=0,stdout="bad JSON",stderr=""})
assert(active == fallback, "invalid output must fall back safely")
os.time = wallTime
print("Wallpaper cache, saved movement, callback isolation, fallback, and error backoff passed")
