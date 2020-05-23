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
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"


-- Build list of apps:
local appFiles = util.scandir(os.getenv("HOME") .. "/dust/code/shado/apps")
local apps = { }

for _, v in ipairs(appFiles) do
    local _, _, name = string.find(v, "(%a+)%.lua$")
    local app = require("shado.apps." .. name)
    table.insert(apps, app)
end

local currentApp = apps[2]

local g = grid.connect()
local renderer = renderers.VariableBlockRenderer:new(16, 8, g)

local function service(i)
    if currentApp.count then
        currentApp:count(i)
        renderer:render(currentApp.layer)
    end
end

function init()
    local layer = currentApp.layer
    renderer:render(layer)
    
    local mgr = manager.PressManager:new(layer)

    g.key = function (x, y, how)
        mgr:press(x, y, how)
        renderer:render(layer)
    end

    local counter = metro.init()
    counter.time = 0.1
    counter.count = -1
    counter.event = service
    counter:start()
end
