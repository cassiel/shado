-- -*- lua-indent-level: 4; -*-

local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"

local patterns = {
   "111 101 101 101 111",       -- 0
   "110 010 010 010 111",       -- 1
   "111 001 111 100 111",       -- 2
   "111 001 111 001 111",       -- 3
   "101 101 111 001 001",       -- 4
   "111 100 111 001 111",       -- 5
   "111 100 111 101 111",       -- 6
   "111 001 001 001 001",       -- 7
   "111 101 111 101 111",       -- 8
   "111 101 111 001 111"        -- 9
}

-- A frame for each digit counter:
local tensFrame = frames.Frame:new()
local unitsFrame = frames.Frame:new()

-- The outermost frame positions the two digit frames on the device:
local outerFrame = frames.Frame:new():add(tensFrame, 5, 2):add(unitsFrame, 10, 2)

-- Build an indexable array of the block objects from the patterns, and
-- add them to the frames also:
local blockObjects = { }

for _, v in ipairs(patterns) do
   local b = blocks.Block:new(v)
   table.insert(blockObjects, b)
   tensFrame:add(b, 1, 1)
   unitsFrame:add(b, 1, 1)
end

return {
    layer = outerFrame,

    count = function (self, i)
       local tens = ((i // 10) % 10) + 1
       local units = (i % 10) + 1

       -- Digit animation done by bringing the required digits to the top:
       tensFrame:top(blockObjects[tens])
       unitsFrame:top(blockObjects[units])
    end,
    
    displayText = {"Counter", "Whatever"}
}
