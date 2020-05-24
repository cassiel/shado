-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"

local lamp_full = types.LampState.ON
local lamp_dull =  types.LampState:new(0.3, 0)

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
end

return {
    layer = frame
}
