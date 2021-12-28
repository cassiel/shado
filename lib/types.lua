-- -*- lua-indent-level: 4; -*-

--[[--
  Basic types: at this stage, just `LampState`, the basic type
  representing an LED, with variable brightness and opacity.
]]

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

--[[--
  The result of this `LampState` instance covering another `LampState`.
  @param lamp the lamp that is being covered
  @return the calculated lamp value
]]

function LampState:cover(lamp)
    local level = interp(self.level, lamp.level, self.blend)
    local blend = self.blend * lamp.blend
    return LampState:new(level, blend)
end

--[[--
  Create a new lamp.
  @param level the brightness of the lamp from `0.0` (off)
  to `1.0` (full).
  @param blend a kind of normalised opacity; `0.0` is fully opaque, `1.0` is
  fully transparent, `-1.0` is full inversion of whatever is below.
  @return a new lamp
]]

function LampState:new(level, blend)
    local result = {
        level = level,
        blend = blend
    }

    return setmetatable(result, self)
end

--- The "off" lamp preset: black, opaque.
LampState.OFF = LampState:new(0, 0)
--- The "on" lamp preset: fully lit, opaque.
LampState.ON = LampState:new(1, 0)
--- The "transparent" lamp preset.
LampState.THRU = LampState:new(0, 1)
--- The "inversion" lamp preset.
LampState.FLIP = LampState:new(0, -1)

--[[--
  Get the brightness (only, not opacity) state of a lamp
  if drawn against black (off).

  @return the brightness, `0.0` to `1.0`
]]

function LampState:againstBlack()
    return self:cover(LampState.OFF).level
end

return {
    LampState = LampState
}
