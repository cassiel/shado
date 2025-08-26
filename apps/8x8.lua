-----
-- Simple static random pattern, 8x8.
-- No variable brightness. No interaction.

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"

local lamp_full = types.LampState.ON

local pixel = blocks.Block:new("1")
local frame = frames.Frame:new()

for x = 1, 8 do
    for y = 1, 8 do
        if math.random() > 0.5 then
            frame:add(pixel, x, y)
        end
    end
end

return {
    layer = frame,

    displayText = [[
        8x8
        Simple display demo for the
        vintage 8x8 greyscale grid.
        No variable brightness.
    ]]
}

-- Local Variables: ***
-- lua-indent-level: 4 ***
-- End: ***
