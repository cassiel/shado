-- -*- lua-indent-level: 4; -*-

--- Blocks: basic rectangular building blocks for `shado` applications.
-- Blocks are populated with lamps.
-- @see types.LampState:new

local types = require "shado/lib/types"
local manager = require "shado/lib/manager"

local Block = { }

-- "Empty" block (all lamps off) with specified width and height.

local function block_wh(self, width, height)
    local lamps = { }

    for x = 1, width do
        lamps[x] = { }
        for y = 1, height do
            lamps[x][y] = types.LampState.OFF
        end
    end

    local result = {
        width = width,
        height = height,
        lamps = lamps
    }

    --[[
        Different machinery here compared to Frame and Mask, since we expect
        inheritance from Block.
        TODO fix up Frame and Mask to match in style.
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

--[[
    Form a block from a format string,
    The pattern is a string of space-separated tokens, each of which is composed from 01./
    denoting OFF, ON, THRU and FLIP respectively.
]]

local function block_str(self, pattern)
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

--[[--
  Create a new block. Can be called as

    Block:new("xxxx xxxx xxxx")

  where the argument string specifies the number of rows (according to the
  number of space-separated tokens) and the content of each row (according
  to the character: `0`, `1`, `.`, `/`).

  The form

    Block:new(w, h)

  takes two integers and creates a block of width `w` and height `h`,
  all lamp values `OFF` (opaque black).

  The form

    Block:new()

  creates a block of size `(0, 0)` and is used in some circumstances
  for inheritance.

  @param a1 format string, or width (or omitted for zero-size block)
  @param a2 if present: height
  @return a new block
]]

function Block:new(a1, a2)
    if a1 == nil then
        return block_wh(self, 0, 0)
    elseif type(a1) == "string" and a2 == nil then
        return block_str(self, a1)
    else
        return block_wh(self, a1, a2)
    end
end

--[[--
  Test whether a coordinate position is within the size
  range of a block. Top-left is `(1, 1)`.

  @param x the X coordinate position
  @param y the Y coordinate position
  @return `true` or `false` depending on position
]]

function Block:inRange(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

--[[--
  Set the lamp value for a single position in the block. Throws an
  error if the position is out of range.

  @param x the X coordinate position
  @param y the Y coordinate position
  @param lampState the lamp value (type `types.LampState`)
  @see types.LampState
]]

function Block:setLamp(x, y, lampState)
    if self:inRange(x, y) then
        self.lamps[x][y] = lampState
    else
        error("shado: setLamp: coordinates (" .. x .. ", " .. y .. ") out of range")
    end
end

--[[--
  Fill a block with a single lamp value.

  @param lampState the lamp value (type `types.LampState`)
  @return the block
  @see types.LampState
]]

function Block:fill(lampState)
    for x = 1, self.width do
        for y = 1, self.height do
            self.lamps[x][y] = lampState
        end
    end

    return self
end

--[[--
  Get the lamp value of a location in the block, or return `THRU`
  if out of coordinate range. Top-left is `(1, 1)`.

  @param x the X coordinate
  @param y the Y coordinate
  @return the lamp value
  @see types.LampState
]]

function Block:getLamp(x, y)
    --[[
        TODO Could just do an '(expr or THRU)' for this, rather than range check?
        (At least for the inner dimension.)
    ]]
    if self:inRange(x, y) then
        return self.lamps[x][y]
    else
        return types.LampState.THRU
    end
end

--[[--
  The default button press handler. Returns `false`; override to
  do something useful (and return non-`false` to mark the press
  as being processed).

  @param x the X coordinate
  @param y the Y coordinate
  @param how `1` for press, `0` for release
]]

function Block:press(x, y, how)
    --[[
        Default press handler returns false, meaning press ignored.
        Contract that x and y are within block coordinates.
        Subclasses override this.
    ]]
    return false
end

--[[--
  Internal function for routing press-on events. Returns a
  `RouteResult` object if the location is within range and the
  block handles the press, otherwise `nil`.
]]

function Block:routePress00(x, y)
    if self:inRange(x, y) and self:press(x, y, 1) ~= false then
        return manager.RouteResult:new(self, x, y)
    else
        return nil
    end
end

return {
    Block = Block
}
