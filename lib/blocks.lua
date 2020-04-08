-- -*- lua-indent-level: 4; -*-

local types = require "shado-lua.lib.types"

local Block = { }
Block.__index = Block

function block_wh(width, height)
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

function block_str(pattern)
end

function Block.new(a1, a2)
    if type(a1) == "string" and a2 == nil then
        return block_str(a1)
    else
        return block_wh(a1, a2)
    end
end

function Block:setLamp(x, y, lampState)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        self.lamps[x][y] = lampState
    else
        error("shado: setLamp: coordinates (" .. x .. ", " .. y .. ") out of range")
    end
end

function Block:fill(lampState)
    for x = 1, self.width do
        for y = 1, self.height do
            self.lamps[x][y] = lampState
        end
    end
end

function Block:getLamp(x, y)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        return self.lamps[x][y]
    else
        return types.LampState.THRU
    end
end

return {
    Block = Block
}
