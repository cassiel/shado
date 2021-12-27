-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"

local block = blocks.Block:new(4, 4):fill(types.LampState.ON)
local frame = frames.Frame:new():add(block, 7, 3)

return {
    layer = frame,

    displayText = [[
        Square
        Super-simple fixed graphic.
        No button interaction.
    ]]
}
