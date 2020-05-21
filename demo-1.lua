-- SHADO demo 1.

-- Purge cache:
for k, _ in pairs(package.loaded) do
    if k:find("shado.lib.") == 1 then
        print("purge " .. k)
        package.loaded[k] = nil
    end
end

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"

function init()
    local lamp_full = types.LampState.ON
    local lamp_dull =  types.LampState:new(0.3, 0)

    local g = grid.connect()
    local renderer = renderers.VariableBlockRenderer:new(16, 8, g)

    local block = blocks.Block:new(2, 2):fill(lamp_dull)

    local frame = frames.Frame:new():add(block, 1, 1)

    function block:press(x, y, how)
        if how == 1 then
            self:setLamp(x, y, lamp_full)

            local newX = math.random(1, 15)
            local newY = math.random(1, 7)

            frame:moveTo(block, newX, newY)
        else
            self:setLamp(x, y, lamp_dull)
        end

        renderer:render(frame)
    end

    local mgr = manager.PressManager:new(frame)

    g.key = function (x, y, how)
        mgr:press(x, y, how)
    end

    renderer:render(frame)
end
