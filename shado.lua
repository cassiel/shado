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

local function selectApp(app)
    -- TODO: we should really wrap each app in a mask to avoid it getting any
    -- out-of-bounds presses (or displaying out-of-bounds) when it's pushed away.
    frame:moveTo(frame:get(1), 1, 9)        -- Old top app out of line of sight.
    frame:top(app.layer)
    frame:moveTo(frame:get(1), 1, 1)        -- New top app into line of sight. 
end

local currentAppIndex = 1
local currentApp = apps[currentAppIndex]
selectApp(currentApp)

local g = grid.connect()
local renderer = renderers.VariableBlockRenderer:new(16, 8, g)

function key(n, z)
    local newIndex
    if z == 1 then
        if n == 2 then
            newIndex = currentAppIndex + 1
            if newIndex > #apps then newIndex = 1 end
        elseif n == 3 then
            newIndex = currentAppIndex - 1
            if newIndex < 1 then newIndex = #apps end
        end
        
        currentAppIndex = newIndex
        currentApp = apps[currentAppIndex]
        selectApp(currentApp)
        renderer:render(frame)
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
