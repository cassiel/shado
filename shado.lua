-----
-- ## shado
--
-- shado demonstrator script.
-- Nick Rothwell, nick@cassiel.com.
-- https://llllllll.co/t/51408


-- Source: [https://github.com/cassiel/shado](https://github.com/cassiel/shado).
--
-- Introduction and description [here](https://github.com/cassiel/shado/blob/master/README.MANUAL.org).
--
-- Press K2 and K3
-- to scroll between apps.

-- For development, purge any shado scripts/libraries from the cache on reload:
for k, _ in pairs(package.loaded) do
    if k:find("shado.") == 1 then
        print("purge " .. k)
        package.loaded[k] = nil
    end
end

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"

-- Build list of apps (and stack their content in a frame):
local frame = frames.Frame:new()

local appFiles = util.scandir(_path.code .. "shado/apps")
local apps = { }

for _, v in ipairs(appFiles) do
    local _, _, name = string.find(v, "(%a+)%.lua$")
    local app = require("shado.apps." .. name)
    table.insert(apps, app)
    frame:add(app.layer, 1, 9)   -- All apps are visually sitting below the actual grid, at y = 9.
end

-- Keep track of currently selected/running app:
local currentAppIndex = 1
local currentApp = apps[currentAppIndex]

-- Attach shado machinery to grid:
local g = grid.connect()
local renderer = renderers.VariableBlockRenderer:new(16, 8, g)

-- Show application index: alone on butten press, then again with text at end of scroll.
local function showAppIndex()
    screen.level(3)
    screen.font_face(15)    -- "VeraBd".
    screen.font_size(10)
    screen.move(127, 10 + 5)
    screen.text_right(string.format("%02d/%02d", currentAppIndex, #apps))
end

-- Some local state for app-specific display text (multiple newline-separated lines, first is title):
local appDisplayText = ""

-- Screen draw: app title (big) and index, then descriptive lines of text:
function redraw()
    screen.clear()

    -- Build table of lines of text:
    local tab = { }
    for line in appDisplayText:gmatch("%s*([^\n]+)") do
        table.insert(tab, line)
    end

    showAppIndex()

    -- Display:
    for i, v in ipairs(tab) do
        if i == 1 then              -- Title:
            screen.level(15)
            screen.font_face(15)    -- "VeraBd".
            screen.font_size(12)
        else                        -- Body text:
            screen.level(5)
            screen.font_face(1)     -- Default.
            screen.font_size(8)
        end

        screen.move(0, i * 10 + 5)
        screen.text(v)
    end

    screen.update()
end

--[[
    Scrolling an app into view via a clock. We block the keys while
    scrolling to avoid confusion, and also clear the display to
    update it once the scroll has finished. (Refinement: we should
    scroll the display too!)
]]

local keysBlocked = false

local function scroller(oldFrom, oldTo, oldStep, newOffset, displayText)
    keysBlocked = true

    return function ()
        -- We've already brought the new app to the top (index 1):
        local oldAppLayer = frame:get(2)
        local newAppLayer = frame:get(1)

        -- Scroll the pair of app layers up or down:
        for i = oldFrom, oldTo, oldStep do
            frame:moveTo(oldAppLayer, 1, i)
            frame:moveTo(newAppLayer, 1, i + newOffset)
            renderer:render(frame)
            clock.sleep(0.02)
        end

        appDisplayText = displayText
        redraw()
        keysBlocked = false
    end
end

local function selectApp(app, sense)
    --[[
        sense == -1 to scroll "view" up, +1 for down, 0 for immediate select.
        TODO: we should really wrap each app in a mask to avoid it getting any
        out-of-bounds presses (or displaying out-of-bounds) when it's pushed away.
    ]]

    -- Immediately clear screen (we'll draw the new text on end of scroll):
    appDisplayText = ""
    redraw()

    local displayText = app.displayText or ""

    -- New application to top of display stack:
    frame:top(app.layer)

    if sense == 1 then
        -- Old app moves up, corner from (1, 0) to (1, -7).
        -- New app is below, offset 8:
        clock.run(scroller(0, -7, -1, 8, displayText))
    elseif sense == -1 then
        -- Old app moves down, corner from (1, 2) to (1, 9):
        -- New app is above, offset -8:
        clock.run(scroller(2, 9, 1, -8, displayText))
    else        -- Immediate move (launch of main script)
        frame:moveTo(frame:get(2), 1, 9)        -- Old top app out of line of sight.
        frame:moveTo(frame:get(1), 1, 1)        -- New top app into line of sight.
        appDisplayText = displayText
        redraw()
    end

end

function key(n, z)
    if not keysBlocked then
        local newIndex, sense

        if z == 1 then
            if n == 3 then      -- Next app (and wrap):
                newIndex = currentAppIndex + 1
                if newIndex > #apps then newIndex = 1 end
                sense = 1
            elseif n == 2 then  -- Previous app (and wrap):
                newIndex = currentAppIndex - 1
                if newIndex < 1 then newIndex = #apps end
                sense = -1
            else                -- (Not reachable:)
                newIndex = currentAppIndex
                sense = 0
            end

            currentAppIndex = newIndex
            currentApp = apps[currentAppIndex]
            selectApp(currentApp, sense)
        end
    end
end

-- Service periodic counter, via app:count() if any:
local function service(i)
    if currentApp.count then
        currentApp:count(i)
        renderer:render(frame)
    end
end

function init()
    renderer:render(frame)

    local mgr = manager.PressManager:new(frame)

    g.key = function (x, y, how)
        mgr:press(x, y, how)
        renderer:render(frame)
    end

    -- Apps get serviced with a counter every 0.1 seconds
    local counter = metro.init()
    counter.time = 0.1
    counter.count = -1
    counter.event = service
    counter:start()

    selectApp(currentApp, 0)
end
