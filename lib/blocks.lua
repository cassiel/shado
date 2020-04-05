-- -*- lua-indent-level: 4; -*-

local types = require "shado-lua.lib.types"

local Block = { }
Block.__index = Block

function Block.new(width, height)
    local lamps = { }

    for x = 1, width do
        lamps[x] = { }
        for y = 1, height do
            lamps[x][y] = types.LampState.OFF
        end
    end

    self = {width = width,
            height = height,
            lamps = lamps}

    return setmetatable(self, Block)
end

function Block:setLamp(x, y, lampState)
    self.lamps[x][y] = lampState
end

function Block:fill(lampState)
    for x = 1, self.width do
        for y = 1, self.height do
            self.lamps[x][y] = lampState
        end
    end
end

function Block:getLamp(x, y)
    return self.lamps[x][y]
end

return {
    Block = Block
}
