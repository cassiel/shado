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

    result = {width = width,
              height = height,
              lamps = lamps}

    return setmetatable(result, Block)
end

local lampStateForChar = { }
lampStateForChar["0"] = types.LampState.OFF
lampStateForChar["1"] = types.LampState.ON
lampStateForChar["."] = types.LampState.THRU
lampStateForChar["/"] = types.LampState.FLIP

function block_str(pattern)
    -- pattern is a string of space-separated tokens, each of which is composed from 01./
    -- denoting OFF, ON, THRU and FLIP respectively.
    local width = 0

    local toks = { }

    -- Determine width and height:
    for tok in pattern.match("%S+") do
        if width > 0 and #tok ~= width then
            error("shado: length mismatch in block token \"" .. tok .. "\"")
        else
            width = #tok
        end

        toks.add(tok)
    end

    local b = block_wh(width, #toks)

    for y = 1, #toks do
        local tok = toks[y]
        local x = 1
        for t in tok.gmatch("01%./") do
            b:setLamp(x, y, lampStateForChar[t])
            x = x + 1
        end
    end

    return b
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
