-- -*- lua-indent-level: 4; -*-

--- Variable-brightness grid renderer.

local types = require "shado/lib/types"

local VariableBlockRenderer = { }
VariableBlockRenderer.__index = VariableBlockRenderer

--[[--
  Create a renderer.

  @param width the width of the grid
  @param height the height of the grid
  @param grid the underlying grid object
  @return the renderer

]]

function VariableBlockRenderer:new(width, height, grid)
    local result = {width = width,
                    height = height,
                    grid = grid}

    return setmetatable(result, self)
end

--[[--
  Render a renderable `shado` object (block, frame or mask).
  Update all grid LEDs and refresh.

  @param renderable the `shado` object to render
]]

function VariableBlockRenderer:render(renderable)
    for x = 1, self.width do
        for y = 1, self.height do
            local f = renderable:getLamp(x, y):againstBlack()
            self.grid:led(x, y, math.floor(f * 15.0))
            -- TODO might want nearest rather than floor(), then clamp to 0..15.
        end
    end

    self.grid:refresh()
end

return {
    VariableBlockRenderer = VariableBlockRenderer
}
