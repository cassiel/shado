-- -*- lua-indent-level: 4; -*-

local types = { }

local LampState = { }
LampState.__index = LampState

--[[
    Calculate the interpolated apparent level ("colour") when this lamp
    is laid over another lamp. It's an interpolation between our level
    and their level, according to our blend value (0.0=opaque), but
    with the sense of *their* level inverted if our blend is negative.
]]

local function interp(ourLevel, theirLevel, ourBlend)
    if ourBlend < 0 then
        ourBlend = -ourBlend
        theirLevel = 1 - theirLevel
    end

    return (ourLevel * (1 - ourBlend) + theirLevel * ourBlend)
end

--[[
    Return the result of this instance covering another instance.
]]

function LampState:cover(lamp)
    local level = interp(self.level, lamp.level, self.blend)
    local blend = self.blend * lamp.blend
    return LampState.new(level, blend)
end

function LampState.new(level, blend)
    local self = setmetatable({ }, LampState)
    self.level = level
    self.blend = blend
    return self
end

LampState.OFF = LampState.new(0, 1)
LampState.ON = LampState.new(1, 0)
LampState.THRU = LampState.new(0, 1)
LampState.FLIP = LampState.new(0, -1)

--[[
    Get the brightness state of a lamp if drawn against black (off).
]]

function LampState:againstBlack()
    return self:cover(LampState.OFF).level
end

types.LampState = LampState
return types
