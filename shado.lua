-- shado demo.
-- Nick Rothwell, nick@cassiel.com

-- Purge cache:
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

local appFiles = util.scandir(os.getenv("HOME") .. "/dust/code/shado/apps")
local apps = { }

for _, v in ipairs(appFiles) do
    local _, _, name = string.find(v, "(%a+)%.lua$")
    local app = require("shado.apps." .. name)
    table.insert(apps, app)
    frame:add(app.layer, 1, 9)   -- All apps are below the actual grid
end

local g = grid.connect()
local renderer = renderers.VariableBlockRenderer:new(16, 8, g)

local keysBlocked = false

local function scroller(oldFrom, oldTo, oldStep, newOffset)
    keysBlocked = true
    return function ()
        local oldAppLayer = frame:get(2)
        local newAppLayer = frame:get(1)
    
        for i = oldFrom, oldTo, oldStep do
            frame:moveTo(oldAppLayer, 1, i)
            frame:moveTo(newAppLayer, 1, i + newOffset)
            renderer:render(frame)
            clock.sleep(0.02)
        end
        keysBlocked = false
    end
end

local function selectApp(app, sense)
    -- sense == -1 to scroll up, +1 for down, 0 for immediate select.
    -- TODO: we should really wrap each app in a mask to avoid it getting any
    -- out-of-bounds presses (or displaying out-of-bounds) when it's pushed away.
    
    local oldAppLayer = frame:get(1)
    local newAppLayer = app.layer
    
    frame:top(newAppLayer)

    if sense == 1 then
        clock.run(scroller(0, -7, -1, 8))
    elseif sense == -1 then
        clock.run(scroller(2, 9, 1, -8))
    else        -- Immediate move (launch of main script)
        frame:moveTo(frame:get(2), 1, 9)        -- Old top app out of line of sight.
        frame:moveTo(frame:get(1), 1, 1)        -- New top app into line of sight.
    end

end

local currentAppIndex = 1
local currentApp = apps[currentAppIndex]
selectApp(currentApp, 0)

function key(n, z)
    if not keysBlocked then
        local newIndex, sense

        if z == 1 then
            if n == 2 then
                newIndex = currentAppIndex + 1
                if newIndex > #apps then newIndex = 1 end
                sense = -1
            elseif n == 3 then
                newIndex = currentAppIndex - 1
                if newIndex < 1 then newIndex = #apps end
                sense = 1
            end
        
            currentAppIndex = newIndex
            currentApp = apps[currentAppIndex]
            selectApp(currentApp, sense)
            renderer:render(frame)
        end
    end
end

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

    local counter = metro.init()
    counter.time = 0.1
    counter.count = -1
    counter.event = service
    counter:start()
end
