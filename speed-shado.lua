-- SHADO speed-test.

for k, _ in pairs(package.loaded) do
    if k:find("shado.lib.") == 1 then
        print("rm " .. k)
        package.loaded[k] = nil
    end
end

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"

local block = blocks.Block.new("1")

local g = grid.connect()
local renderer = renderers.VariableBlockRenderer.new(16, 8, g)

--[[ EFFORT 1
for x = 1, 16 do
    for y = 1, 8 do
        local frame = frames.Frame.new():add(block, x, y)
        renderer:render(frame)        
    end
end
]]

-- EFFORT 2
local frame = frames.Frame.new():add(block, 1, 1)

for x = 1, 16 do
    for y = 1, 8 do
        frame:moveTo(block, x, y)
        renderer:render(frame)        
    end
end
