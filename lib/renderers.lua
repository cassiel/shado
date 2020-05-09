-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local VariableBlockRenderer = { }
VariableBlockRenderer.__index = VariableBlockRenderer

function VariableBlockRenderer.new(width, height, grid)
    local result = {width = width,
                    height = height,
                    grid = grid}

    return setmetatable(result, VariableBlockRenderer)
end

function VariableBlockRenderer:render(renderable)
    for x = 1, self.width do
        for y = 1, self.height do
            local f = renderable:getLamp(x, y):againstBlack()
            self.grid:led(x, y, f * 15.0)
        end
    end

    self.grid:refresh()
end

return {
    VariableBlockRenderer = VariableBlockRenderer
}
