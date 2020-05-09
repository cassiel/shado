-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local BinaryBlockRenderer = { }
BinaryBlockRenderer.__index = BinaryBlockRenderer

function BinaryBlockRenderer.new(grid)
    local result = { }

    return setmetatable(result, BinaryBlockRenderer)
end

function BinaryBlockRenderer:render()
end

return {
    BinaryBlockRenderer = BinaryBlockRenderer
}
