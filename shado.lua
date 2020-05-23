-- SHADO demo.
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

function init()
    --local apps = util.scandir("/home/we/dust/code/shado/apps")
    local apps = util.scandir(os.getenv("HOME") .. "/dust/code/shado/apps")

    for _, v in ipairs(apps) do print("** " .. v) end

    local test = require "shado.apps.test"

    local g = grid.connect()
    local layer = test.layer
    renderers.VariableBlockRenderer:new(16, 8, g):render(layer)
end
