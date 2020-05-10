-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local Block = { }

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

    --[[
        Different machinery here compared to Frame and ViewPort, since we expect
        inheritance from Block.
        TODO fix up Frame and ViewPort to match in style.
    ]]

    self.__index = self
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
    if a1 == nil then -- Empty-constructor used for inheritance.
        return block_wh(self, 0, 0)
    elseif type(a1) == "string" and a2 == nil then
        return block_str(self, a1)
    else
        return block_wh(self, a1, a2)
    end
end

function Block:inRange(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

function Block:setLamp(x, y, lampState)
    if self:inRange(x, y) then
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
    if self:inRange(x, y) then
        return self.lamps[x][y]
    else
        return types.LampState.THRU
    end
end

function Block:press(x, y, how)
    --[[
        Default press handler returns false, meaning press ignored.
        Contract that x and y are within block coordinates.
        Subclasses override this.
    ]]
    return false
end

function Block:routePress00(x, y, how)
    if self:inRange(x, y) and self:press(x, y, how) then
        -- TODO proper press tracking here
        return "XXXXX"
    else
        return nil
    end
end

return {
    Block = Block
}
