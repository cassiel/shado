-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "shado/lib/luaunit"

local types = require "shado/lib/types"

test_types = { }

function test_types:testAgainstBlack()
    lu.assertEquals(types.LampState.OFF:againstBlack(), 0)
    lu.assertEquals(types.LampState.ON:againstBlack(), 1)
    lu.assertEquals(types.LampState.THRU:againstBlack(), 0)
    lu.assertEquals(types.LampState.FLIP:againstBlack(), 1)
end

function test_types:testCover()
    local on = types.LampState.ON
    local off = types.LampState.OFF
    local thru = types.LampState.THRU
    local flip = types.LampState.FLIP

    lu.assertEquals(on:cover(off), on, "on>off = on")
    lu.assertEquals(flip:cover(off), on, "flip>off = on")
    lu.assertEquals(thru:cover(on), on, "thru>on = on")
    lu.assertEquals(thru:cover(thru), thru, "thru>thru = thru")
end

function test_types:testBlend()
    local lamp = types.LampState.new

    local function almostEquals(lamp1, lamp2, legend)
        lu.assertAlmostEquals(lamp1.level, lamp2.level, 0.001, legend .. "/level")
        lu.assertAlmostEquals(lamp1.blend, lamp2.blend, 0.001, legend .. "/blend")
    end

    -- Pure "flipper"
    almostEquals(lamp(0.0, -1.0):cover(lamp(0.0, 0.0)), lamp(1.0, 0.0), "tb1")

    -- Two semi-transparencies:
    almostEquals(lamp(0.0, 0.5):cover(lamp(0.0, 0.5)), lamp(0.0, 0.25), "tb2")

    -- Semi-transparent black over white returns opaque grey:
    almostEquals(lamp(0.0, 0.5):cover(lamp(1.0, 0.0)), lamp(0.5, 0), "tb3")

    -- Semi-transparent flipper over black returns opaque grey:
    almostEquals(lamp(0.0, -0.5):cover(lamp(0.0, 0.0)), lamp(0.5, 0), "tb4")

    -- Interpolation between two whites:
    almostEquals(lamp(1.0, 0.5):cover(lamp(1.0, 0.0)), types.LampState.ON, "tb5")

    -- A mostly-transparent white flipper over white:
    almostEquals(lamp(1.0, -0.1):cover(lamp(1.0, 0.0)), lamp(0.9, 0.0), "tb6")

    -- A slightly-transparent white flipper over white:
    almostEquals(lamp(1.0, -0.9):cover(lamp(1.0, 0.0)), lamp(0.1, 0.0), "tb7")
end

runner = lu.LuaUnit.new()
runner:runSuite("--verbose")
