-- Exercise the actual fork handlers without loading KOReader's widget tree.
local t = dofile("tests/_helpers.lua").runner()
local function source(path)
    local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end
local widget = source("lib/bookshelf_widget.lua")
local calls = 0
local UIManager = { suspend = function() calls = calls + 1 end }
local BookshelfWidget = {}
local InputContainer = { handleEvent = function() return false end }
local live_calls = 0
local GestureZones = {
    tryUserFirst = function() return false end,
    tryLiveZones = function() live_calls = live_calls + 1; return false end,
    forwardToLive = function() return false end,
}
local Device = {}
local fm, reader = {}, {}
local function mockRequire(name)
    if name == "apps/filemanager/filemanager" then return fm end
    if name == "apps/reader/readerui" then return reader end
    if name == "lib/bookshelf_reader_park" then return { isParked = function() return true end } end
    error(name)
end
local handlers = assert(widget:match("function BookshelfWidget:handleEvent%(event%)(.-)\nend\n"))
local suspend = assert(widget:match("function BookshelfWidget:onRequestSuspend%(%)(.-)\nend\n"))
local build = assert(load("return function(BookshelfWidget, InputContainer, GestureZones, Device, require, UIManager, logger)\n"
    .. "function BookshelfWidget:handleEvent(event)" .. handlers .. "\nend\n"
    .. "function BookshelfWidget:onRequestSuspend()" .. suspend .. "\nend\nend"))()
build(BookshelfWidget, InputContainer, GestureZones, Device, mockRequire, UIManager, { info = function() end })
BookshelfWidget._dropLiftOnTap = function() return false end
local event = { handler = "onGesture", args = {{ ges = "multiswipe", multiswipe_directions = "south east" }} }
local host = { gestures = { settings_data = { data = { gesture_reader = {
    multiswipe_south_east = { suspend = true },
} } } } }
t.test("reader sleep binding suspends from FileManager or parked ReaderUI", function()
    fm.instance = host
    assert(BookshelfWidget:handleEvent(event)); assert(calls == 1)
    fm.instance = nil; reader.instance = host
    assert(BookshelfWidget:handleEvent(event)); assert(calls == 2)
    assert(live_calls == 0)
end)
t.test("sleep screen lock leaves the unlock gesture alone", function()
    Device.screen_saver_lock = true
    assert(BookshelfWidget:handleEvent(event) == false); assert(calls == 2)
    Device.screen_saver_lock = false
end)
t.test("unbound multiswipe reaches upstream gesture routing", function()
    reader.instance = nil
    assert(BookshelfWidget:handleEvent(event) == false)
    assert(live_calls == 1); assert(calls == 2)
end)
t.test("direct suspend requests suspend once and consume the event", function()
    assert(BookshelfWidget:onRequestSuspend()); assert(calls == 3)
end)
t.test("screensaver fallback is scoped and restores the host even on error", function()
    local src = source("main.lua")
    local body = assert(src:match("local function _installScreensaverHostFallback%(%)(.-)\nend\n"))
    local manager = { isWidgetShown = function() return true end }
    local filemanager, readerui = {}, {}
    local should_error, seen = false, nil
    local screen = { setup = function()
        seen = filemanager.instance
        if should_error then error("setup failed") end
    end }
    local install = assert(load("return function(UIManager, _live_widget, require)\n"
        .. "local function _installScreensaverHostFallback()" .. body
        .. "\nend\n_installScreensaverHostFallback()\nend"))()
    install(manager, {}, function(name)
        if name == "ui/screensaver" then return screen end
        if name == "apps/filemanager/filemanager" then return filemanager end
        if name == "apps/reader/readerui" then return readerui end
        error(name)
    end)
    screen:setup()
    assert(seen and seen.bookinfo:expandString("text") == "text")
    assert(filemanager.instance == nil)
    should_error = true
    assert(not pcall(screen.setup, screen)); assert(filemanager.instance == nil)
    should_error = false
    local real_host = {}; filemanager.instance = real_host
    screen:setup(); assert(seen == real_host and filemanager.instance == real_host)
    filemanager.instance = nil; readerui.instance = {}
    screen:setup(); assert(seen == nil and filemanager.instance == nil)
end)
t.done()
