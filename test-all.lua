-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local types = require "shado-lua.lib.types"
local blocks = require "shado-lua.lib.blocks"
local frames = require "shado-lua.lib.frames"
local inspect = require "inspect"

test_Other = {
    test_Fooble = function ()
        lu.assertEquals(1, 1)
    end
}

test_Types = {
    testAgainstBlack = function ()
        lu.assertEquals(types.LampState.OFF:againstBlack(), 0)
        lu.assertEquals(types.LampState.ON:againstBlack(), 1)
        lu.assertEquals(types.LampState.THRU:againstBlack(), 0)
        lu.assertEquals(types.LampState.FLIP:againstBlack(), 1)
    end,

    testCover = function ()
        local on = types.LampState.ON
        local off = types.LampState.OFF
        local thru = types.LampState.THRU
        local flip = types.LampState.FLIP

        lu.assertEquals(on:cover(off), on, "on>off = on")
        lu.assertEquals(flip:cover(off), on, "flip>off = on")
        lu.assertEquals(thru:cover(on), on, "thru>on = on")
        lu.assertEquals(thru:cover(thru), thru, "thru>thru = thru")
    end,

    testBlend = function ()
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
}

test_Blocks = {
    testSimpleLampSet = function ()
        local b = blocks.Block.new(1, 1)

        b:setLamp(1, 1, types.LampState.ON)
        lu.assertEquals(b:getLamp(1, 1), types.LampState.ON, "lamp state")
    end,

    testCanFill = function ()
        local b = blocks.Block.new(2, 2)
        -- print(inspect.inspect(b))

        b:fill(types.LampState.ON)
        lu.assertEquals(b:getLamp(1, 1), types.LampState.ON, "lamp state")
    end,

    testCreateFromTokens = function ()
        local b = blocks.Block.new("1010 .... ././")

        lu.assertEquals(b:getLamp(2, 0), types.LampState.ON, "lamp 1")
        lu.assertEquals(b:getLamp(0, 1), types.LampState.THRU, "lamp 2")
        lu.assertEquals(b:getLamp(3, 2), types.LampState.FLIP, "lamp 3")
    end,

    testDetectsBadTokenLists = function ()
        lu.assertErrorMsgMatches(".*%sshado:%s.*%slength mismatch",
                                 blocks.Block.new, "11 111")
        lu.assertErrorMsgMatches(".*%sshado:%s.*%sbad token",
                                 blocks.Block.new, "111 000 00$")
    end,

    testOutsideRangeForSet = function ()
        local b = blocks.Block.new(1, 1)
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange",
                                  b.setLamp, b,
                                  10, 10, types.LampState.ON)
    end,

    testOutsideRangeForGet = function ()
        local b = blocks.Block.new(1, 1)
        lu.assertEquals(b:getLamp(10, 10), types.LampState.THRU, "out of range > THRU")
    end,

    testCanMakeThinBlocks = function ()
        local b1 = blocks.Block.new(1, 10)
        local b2 = blocks.Block.new(10, 1)
    end
}

test_Frames = {
    testFrameChecksItemRange = function ()
        f = frames.Frame.new()
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange",
                                 f.get, f, 0)
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange",
                                 f.get, f, 1)
    end,

    testCanAddToBottom = function ()
        f = frame.Frames.new()
        b1 = blocks.Block.new(0, 0)
        b2 = blocks.Block.new(0, 0)

        f:add(b1, 1, 1)
        f:add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)

        -- Test chaining:
        f = frame.Frames.new()
        f:add(b1, 1, 1):add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)
    end
}

runner = lu.LuaUnit.new()
runner:runSuite("--verbose")
