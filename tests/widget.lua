-- Exercise the actual entry with deterministic host inputs (Lua 5.4 or Luau).
local root = arg[1] or "."
local config, tree, secondTicks, instant, reads
local defaults = dofile(root .. "/tests/defaults.lua")
local fonts = 0
local originalRequire = require
require = function(path)
    if path == "./wallpaper.luau" then
        return assert(loadfile(root .. "/clearclock/wallpaper.luau"))()
    end
    return originalRequire(path)
end
noctalia = {
    getConfig = function(key)
        assert(config[key] ~= nil, "undeclared setting: " .. key)
        return config[key]
    end,
    loadFont = function(path)
        fonts = fonts + 1
        return path:find("Smooch") and "Smooch" or "Outfit"
    end,
    formatTime = function(pattern, now, timezone)
        assert(now == instant, "labels must share one instant")
        assert(timezone == config.timezone)
        reads = reads + 1
        -- UTC makes the fixture independent of the test machine's timezone.
        pattern = pattern:gsub("%%%-d", tostring(tonumber(os.date("!%d", now))))
        return os.date("!" .. pattern, now)
    end,
}
desktopWidget = {
    render = function(value) tree = value end,
    setWantsSecondTicks = function(value) secondTicks = value end,
}
ui = {}
for _, kind in ipairs({ "label", "column", "row" }) do
    ui[kind] = function(props, children)
        return { kind = kind, props = props, children = children or {} }
    end
end
assert(loadfile(root .. "/clearclock/desktop.luau"))()
assert(fonts == 3, "bundle fonts should be loaded once")
local wallTime = os.time
os.time = function() return instant end
local function render(at, overrides)
    config = {}
    for key, value in pairs(defaults) do config[key] = value end
    config.adaptiveGradients = false
    for key, value in pairs(overrides or {}) do config[key] = value end
    instant, reads = at, 0
    update()
    return tree.children[1].children[1].children[1].props.text
end

-- 2026-01-01 00:05:09 UTC: midnight, leading zero, literal separator.
assert(render(1767225909) == "00.05")
assert(not secondTicks)
assert(tree.children[1].children[2].children[1].props.text == "Thursday")
assert(tree.children[1].props.gap == -tree.children[1].children[1].props.height)
local date = {}
for _, node in ipairs(tree.children[2].children) do
    table.insert(date, node.children[1].props.text)
end
assert(table.concat(date) == "1 JANUARY 2026")
assert(render(1767225909, {clockUse24hFormat = false, clockShowSeconds = true}) == "12.05.09 AM")
assert(secondTicks)
assert(render(1767268800, {clockUse24hFormat = false}) == "12.00 PM")
assert(render(1767225909, {clockSeparator = "%{}"}) == "00%{}05")
assert(render(1767225909, {clockSeparator = ""}) == "0005")
render(1767225909, {showDayDisplay = false, showDateDisplay = false})
assert(#tree.children == 1 and #tree.children[1].children == 1)
render(1767225909, {dateLetterSpacing = 0, clockFontFamily = "My Font", clockBoldText = false})
assert(tree.children[2].kind == "label")
assert(tree.children[1].children[1].children[1].props.fontFamily == "My Font")
assert(tree.children[1].children[1].children[1].props.fontWeight == "normal")
render(1767225909, {dateCustomDateFormat = "é日"})
assert(#tree.children[2].children == 2, "localized date must split UTF-8 characters, not bytes")
assert(tree.children[2].children[1].props.height == tree.children[2].children[2].props.height)
render(1767225599)
assert(tree.children[1].children[2].children[1].props.text == "Wednesday")
render(1767225600)
assert(tree.children[1].children[2].children[1].props.text == "Thursday")
assert(fonts == 3, "ticks must not reload fonts")
render(1767225909)
assert(tree.children[1].children[1].children[1].props.color == "primary")
assert(tree.children[1].children[2].children[1].props.color == "on_primary")
assert(tree.children[2].children[1].children[1].props.color == "on_surface")
render(1767225909, {adaptiveColors = false, clockFontColor = "#123456",
    dayFontColor = "#abcdef", dateFontColor = "#654321"})
assert(tree.children[1].children[1].children[1].props.color == "#123456")
assert(tree.children[1].children[2].children[1].props.color == "#abcdef")
assert(tree.children[2].children[1].children[1].props.color == "#654321")
render(1767225909, {adaptiveColors = true, dateLetterSpacing = 0})
assert(tree.children[2].props.color == "on_surface")
os.time = wallTime
print("Widget rendering, midnight/noon, visibility, formatting, UTF-8, and tick tests passed")
