-- Exercise transparent defaults without invoking or modifying a running shell.
local root = arg[1] or "."
local widgets, calls, callback, started, now = {}, {}, nil, true, 100
local log = {}
local wallTime = os.time
os.time = function() return now end
noctalia = {
    setUpdateInterval = function(value) assert(value == 2000) end,
    getSetting = function(path)
        assert(path == "desktop_widgets")
        return {widget = widgets}
    end,
    runAsync = function(argv, cb)
        table.insert(calls, argv)
        callback = cb
        return started
    end,
    log = function(message) table.insert(log, message) end,
}
assert(loadfile(root .. "/clearclock/defaults.luau"))()
update()
assert(#calls == 0)
widgets = {
    other = {type = "clock"},
    explicit = {type = "nirusaki/clearclock:desktop", settings = {background = true}},
    transparent = {type = "nirusaki/clearclock:desktop", settings = {background = false}},
}
update()
assert(#calls == 0, "explicit backgrounds and unrelated widgets must be preserved")
widgets['clock "quoted".id'] = {type = "nirusaki/clearclock:desktop"}
update()
assert(#calls == 1)
assert(calls[1][1] == "noctalia" and calls[1][2] == "msg")
assert(calls[1][3] == "config-set" and calls[1][4] == "desktop_widgets.widget")
assert(calls[1][5] == '{ "clock \\"quoted\\".id" = { settings = { background = false } } }')
update()
assert(#calls == 1, "do not issue duplicate config writes while one is pending")
widgets['clock "quoted".id'].settings = {background = false}
callback({exitCode = 0, stdout = "ok\n", stderr = ""})
update()
assert(#calls == 1)
widgets.new = {type = "nirusaki/clearclock:desktop", settings = {clockFontSize = 99}}
update()
assert(#calls == 2)
callback({exitCode = 1, stdout = "", stderr = "unavailable"})
update()
assert(#calls == 2 and #log == 1, "failed mutations must back off")
now = 131
started = false
update()
assert(#calls == 3 and #log == 2)
update()
assert(#calls == 3, "failed process launches must also back off")
now = 162
started = true
update()
callback({exitCode = 0, stdout = "error: rejected\n", stderr = ""})
update()
assert(#calls == 4 and #log == 3, "IPC text errors must not count as success")
os.time = wallTime
print("Transparent defaults, explicit overrides, quoted IDs, duplicate suppression, and retry tests passed")
