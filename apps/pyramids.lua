-----
-- Two pyramids. Each is a stack of concentric squares, 8x8 at the bottom
-- to 2x2 at the top. Each responds to button press, randomising its
-- own level and blend (opacity).

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"

-- Random level and blend/opacity:

function randomLamp()
    local level = math.random()             -- 0.0..1.0
    local blend = math.random() * 2 - 1     -- -1.0..1.0

    return  types.LampState:new(level, blend)
end

function makeLayer(size)
    -- Create the block:
    local b = blocks.Block:new(size, size):fill(randomLamp())

    -- A button press should randomise the lamp:
    b.press =
        function(self, x, y, how)
            if how > 0 then
                b:fill(randomLamp())
            end
        end

    -- Create a frame to centre the block (though we could
    -- just do that in the outermost frame below):
    local offset = (8 - size) // 2
    local f = frames.Frame:new():add(b, 1 + offset, 1 + offset)

    return f
end

local frame = frames.Frame:new()

-- Stack blocks, biggest at the bottom:
for i = 8, 2, -2 do
    frame:add(makeLayer(i), 1, 1)
end

-- Do it again, for the second pyramid:
for i = 8, 2, -2 do
    frame:add(makeLayer(i), 9, 1)
end

return {
    layer = frame,

    displayText = [[
        Pyramids
        Two stacks of concentric
        squares, 2x2 to 8x8.
        Press to randomise level and
        opacity of selected square.
    ]]
}

-- Local Variables: ***
-- lua-indent-level: 4 ***
-- End: ***
