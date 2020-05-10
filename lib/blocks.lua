-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local Block = { }
Block.__index = Block

local function block_wh(self, width, height)
    local lamps = { }

    for x = 1, width do
        lamps[x] = { }
        for y = 1, height do
            lamps[x][y] = types.LampState.OFF
        end
    end

    local result = {width = width,
                    height = height,
                    lamps = lamps}

    return setmetatable(result, self)
end

local lampStateForChar = {
    ["0"] = types.LampState.OFF,
    ["1"] = types.LampState.ON,
    ["."] = types.LampState.THRU,
    ["/"] = types.LampState.FLIP
}

local function block_str(self, pattern)
    -- pattern is a string of space-separated tokens, each of which is composed from 01./
    -- denoting OFF, ON, THRU and FLIP respectively.
    local width = 0

    local toks = { }

    -- Determine width and height:
    for tok in string.gmatch(pattern, "%S+") do
        if width > 0 and #tok ~= width then
            error("shado: length mismatch in block token \"" .. tok .. "\"")
        else
            width = #tok
        end

        table.insert(toks, tok)
    end

    local b = block_wh(self, width, #toks)

    for y = 1, #toks do
        local tok = toks[y]

        if string.match(tok, "^[01./]+$") then
            local x = 1
            for t in string.gmatch(tok, "[01./]") do
                b:setLamp(x, y, lampStateForChar[t])
                x = x + 1
            end
        else
            error("shado: bad character in block token: \"" .. tok .. "\"")
        end
    end

    return b
end

function Block:new(a1, a2)
    if type(a1) == "string" and a2 == nil then
        return block_str(self, a1)
    else
        return block_wh(self, a1, a2)
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

    return self
end

function Block:getLamp(x, y)
    --[[
        TODO Could just do an "(expr or THRU)" for this, rather than range check?
        (At least for the inner dimension.)
    ]]
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        return self.lamps[x][y]
    else
        return types.LampState.THRU
    end
end

return {
    Block = Block
}
