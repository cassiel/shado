-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local utils = require "shado.lib.utils"
local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local masks = require "shado.lib.masks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"
local inspect = require "inspect"

test_Other = {
    test_Fooble = function ()
        lu.assertEquals(1, 1)
    end
}

test_TwoDMap = {
    testNoMapEntry = function ()
        lu.assertNil(utils.TwoDMap:new():get00(1, 1))
    end,

    testMapEntry = function ()
        local m = utils.TwoDMap:new()

        m:put(3, 4, "HELLO")
        m:put(4, 3, "GOODBYE")

        lu.assertEquals(m:get00(3, 4), "HELLO")
        lu.assertEquals(m:get00(4, 3), "GOODBYE")
        lu.assertNil(m:get00(2, 2))
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
        local b = blocks.Block:new(1, 1)

        b:setLamp(1, 1, types.LampState.ON)
        lu.assertEquals(b:getLamp(1, 1), types.LampState.ON, "lamp state")
    end,

    testCanFill = function ()
        local b = blocks.Block:new(2, 2)
        -- print(inspect.inspect(b))

        b:fill(types.LampState.ON)
        lu.assertEquals(b:getLamp(1, 1), types.LampState.ON, "lamp state")
    end,

    testCreateFromTokens = function ()
        local b = blocks.Block:new("1010 .... ././")

        lu.assertEquals(b:getLamp(3, 1), types.LampState.ON, "lamp 1")
        lu.assertEquals(b:getLamp(1, 2), types.LampState.THRU, "lamp 2")
        lu.assertEquals(b:getLamp(4, 3), types.LampState.FLIP, "lamp 3")
    end,

    testDetectsBadTokenLists = function ()
        local function new(str)
            return blocks.Block:new(str)
        end

        lu.assertErrorMsgMatches(".*%sshado: length mismatch%s.*",
                                 new, "11 111")
        lu.assertErrorMsgMatches(".*%sshado: bad character%s.*",
                                 new, "111 000 00$")
    end,

    testOutsideRangeForSet = function ()
        local b = blocks.Block:new(1, 1)
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange",
                                  b.setLamp, b,
                                  10, 10, types.LampState.ON)
    end,

    testOutsideRangeForGet = function ()
        local b = blocks.Block:new(1, 1)
        lu.assertEquals(b:getLamp(10, 10), types.LampState.THRU, "out of range > THRU")
    end,

    testCanMakeThinBlocks = function ()
        local b1 = blocks.Block:new(1, 10)
        local b2 = blocks.Block:new(10, 1)
    end
}

-- Machinery for Blocks inheritance:
-- TODO we'll need to allow arbitrary arguments in sub-class constructors.

PushBlock = blocks.Block:new()

function PushBlock:press(x, y, how)
    self.handledX = x
    self.handledY = y
end

test_BlocksInput = {
    testCanRouteSimpleOriginPress = function ()
        local pb = PushBlock:new(2, 1)
        pb:routePress00(2, 1)
        lu.assertEquals(pb.handledX, 2)
        lu.assertEquals(pb.handledY, 1)
    end,

    testIgnoresPressesOutOfRange = function ()
        local pb = PushBlock:new(1, 1)
        pb:routePress00(2, 1)
        lu.assertNil(pb.handledX)
        lu.assertNil(pb.handledY)
    end,

    testCanRouteSimpleOriginPressViaPatch = function ()
        local b = blocks.Block:new(2, 1)

        function b:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        b:routePress00(2, 1)
        lu.assertEquals(b.handledX, 2)
        lu.assertEquals(b.handledY, 1)
    end
}

test_Frames = {
    testFrameChecksItemRange = function ()
        local f = frames.Frame:new()
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange:.*",
                                 f.get, f, 0)
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange:.*",
                                 f.get, f, 1)
    end,

    testCanAddToEnd = function ()
        local f = frames.Frame:new()
        local b1 = blocks.Block:new(0, 0)
        local b2 = blocks.Block:new(0, 0)

        f:add(b1, 1, 1)
        f:add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)

        -- Test chaining:
        f = frames.Frame:new()
        f:add(b1, 1, 1):add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)
    end,

    testCanRemove = function ()
        local f = frames.Frame:new()
        local b = blocks.Block:new('1')

        f:add(b, 1, 1)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
        f:remove(b)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.THRU)
    end,

    testRemoveError = function ()
        local f = frames.Frame:new()
        lu.assertErrorMsgMatches(".*%sshado: item not found%s.*",
                                 f.remove, f, blocks.Block:new(0, 0))
    end,

    testFrameStackingOrder = function ()
        local f = frames.Frame:new()
        f:add(blocks.Block:new('1'), 1, 1):add(blocks.Block:new('0'), 1, 1)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)

        f = frames.Frame:new()
        f:add(blocks.Block:new('1'), 1, 1):add(blocks.Block:new('/'), 1, 1)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)
    end,

    testCanBringToTopOfFrame = function ()
        local f = frames.Frame:new()
        local b_OFF = blocks.Block:new('0')
        local b_ON = blocks.Block:new('1')

        f:add(b_OFF, 1, 1):add(b_ON, 1, 1)

        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
        f:top(b_OFF)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)
        f:top(b_ON)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
    end,

    testCanBringToBottomOfFrame = function ()
        local f = frames.Frame:new()
        local b_OFF = blocks.Block:new('0')
        local b_ON = blocks.Block:new('1')

        f:add(b_OFF, 1, 1):add(b_ON, 1, 1)

        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
        f:bottom(b_ON)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)
        f:bottom(b_OFF)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
    end,

    testErrorLiftingNonExistentFrame = function ()
        local b = blocks.Block:new('1')
        local f = frames.Frame:new():add(b, 1, 1)
        local b2 = blocks.Block:new('1')

        lu.assertErrorMsgMatches(".*%sshado: item not found%s.*",
                                 f.top, f, b2)
    end,

    testCannotHideNonExistentItem = function ()
        local b = blocks.Block:new('1')
        local f = frames.Frame:new():add(b, 1, 1)
        local b2 = blocks.Block:new('1')

        lu.assertErrorMsgMatches(".*%sshado: item not found%s.*",
                                 f.hide, f, b2)
    end,

    testCanHideItem = function ()
        local b = blocks.Block:new('1')
        local f = frames.Frame:new():add(b, 1, 1)

        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
        f:hide(b)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.THRU)
        f:show(b)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
    end,

    testFrameOffset = function ()
        local f = frames.Frame:new():add(blocks.Block:new('1'), 2, 1)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.THRU)
        lu.assertEquals(f:getLamp(2, 1), types.LampState.ON)
    end,

    testCanMoveInFrame = function ()
        local f = frames.Frame:new()
        local b = blocks.Block:new('1')

        f:add(b, 1, 1)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.ON)
        lu.assertEquals(f:getLamp(2, 2), types.LampState.THRU)

        f:moveTo(b, 2, 2)
        lu.assertEquals(f:getLamp(1, 1), types.LampState.THRU)
        lu.assertEquals(f:getLamp(2, 2), types.LampState.ON)
    end,

    testErrorFindingInFrame = function ()
        local f = frames.Frame:new()
        local b1 = blocks.Block:new('1')
        local b2 = blocks.Block:new('1')

        f:add(b1, 1, 1)

        lu.assertErrorMsgMatches(".*%sshado: item not found in frame.*",
                                 f.moveTo, f, b2, 1, 1)
    end
}

test_Masks = {
    testCanCropOnBlock = function ()
        local block = blocks.Block:new(4, 4):fill(types.LampState.ON)
        -- args: (x, y, width, height). (1, 1) is normalised mask position, Lua-style.
        local cropped = masks.Mask:new(block, 1, 2, 4, 2)

        lu.assertEquals(cropped:getLamp(1, 1), types.LampState.THRU, "above/1")
        lu.assertEquals(cropped:getLamp(1, 2), types.LampState.ON, "within/1")
        lu.assertEquals(cropped:getLamp(4, 3), types.LampState.ON, "within/2")
        lu.assertEquals(cropped:getLamp(4, 4), types.LampState.THRU, "below/1")
    end,

    testCanMoveWindow = function ()
        local block = blocks.Block:new(4, 4):fill(types.LampState.ON)
        local cropped = masks.Mask:new(block, 1, 1, 2, 2)

        lu.assertEquals(cropped:getLamp(1, 1), types.LampState.ON, "TL/1")
        lu.assertEquals(cropped:getLamp(4, 4), types.LampState.THRU, "BR/1")

        cropped:setX(3)

        lu.assertEquals(cropped:getLamp(1, 1), types.LampState.THRU, "TL/2")
        lu.assertEquals(cropped:getLamp(4, 4), types.LampState.THRU, "BR/2")

        cropped:setY(3)

        lu.assertEquals(cropped:getLamp(1, 1), types.LampState.THRU, "TL/3")
        lu.assertEquals(cropped:getLamp(4, 4), types.LampState.ON, "BR/3")
    end
}

test_MasksInput = {
    testPressInRange = function ()
        local block = blocks.Block:new(4, 4)
        local mask = masks.Mask:new(block, 1, 1, 1, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        mask:routePress00(1, 1)
        lu.assertEquals(block.handledX, 1)
        lu.assertEquals(block.handledY, 1)
    end,

    testPressOutOfRange = function ()
        local block = blocks.Block:new(4, 4)
        local mask = masks.Mask:new(block, 4, 4, 1, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        mask:routePress00(1, 1)
        lu.assertNil(block.handledX)
        lu.assertNil(block.handledY)
    end,

    testWillMapPressToMaskCoordinates = function ()
        --[[
            If the mask handles the press, the coordinates are relative to the
            view port in the mask, not the mask origin. Also checks that the block
            doesn't get the press if the mask does.
        ]]
        local block = blocks.Block:new(4, 4)
        local mask = masks.Mask:new(block, 2, 1, 1, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        function mask:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        mask:routePress00(2, 1)
        lu.assertEquals(mask.handledX, 1)
        lu.assertEquals(mask.handledY, 1)
        lu.assertNil(block.handledX)
        lu.assertNil(block.handledY)
    end,

    testWillMapPressToMaskAndContent = function ()
        --[[
            If the mask returns false from the press, it\'s passed to the contents.
        ]]
        local block = blocks.Block:new(4, 4)
        local mask = masks.Mask:new(block, 1, 1, 1, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        function mask:press(x, y, how)
            self.handledX = x
            self.handledY = y
            return false
        end

        mask:routePress00(1, 1)
        lu.assertEquals(mask.handledX, 1)
        lu.assertEquals(mask.handledY, 1)
        lu.assertEquals(block.handledX, 1)
        lu.assertEquals(block.handledY, 1)
    end,

    testWillCorrectlyPassPressesToContents = function ()
        --[[
            Any contained object will receive presses at their underlying coordinates,
            regardness of the position of the mask. TODO I could be persuaded to change this
            to use mask port coordinates, but I feel masks should have minimal
            functional impact.
        ]]
        local block = blocks.Block:new(4, 4)
        local mask = masks.Mask:new(block, 2, 1, 1, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        mask:routePress00(2, 1)
        lu.assertEquals(block.handledX, 2)
        lu.assertEquals(block.handledY, 1)
    end,

    testCanPressThroughFrameAndMask = function ()
        local block = blocks.Block:new(2, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        local mask = masks.Mask:new(block, 1, 1, 2, 1)
        local frame = frames.Frame:new()

        frame:add(mask, 1, 2)

        frame:routePress00(2, 2)

        lu.assertEquals(block.handledX, 2)
        lu.assertEquals(block.handledY, 1)
    end,

    testMaskCanHandlePressWithOffset = function ()
        local block = blocks.Block:new(2, 2)

        function block:press(x, y, how)
            self.wasWronglyPressed = true
        end

        local mask = masks.Mask:new(block, 2, 2, 1, 1)

        function mask:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        mask:routePress00(2, 2)

        lu.assertNil(block.wasWronglyPressed)
        lu.assertEquals(mask.handledX, 1)
        lu.assertEquals(mask.handledY, 1)
    end
}

test_FramesInput = {
    testFrameCanPassPressToBlock = function ()
        local block = blocks.Block:new(2, 1)

        function block:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        local frame = frames.Frame:new()

        frame:add(block, 1, 2)

        frame:routePress00(2, 2)

        lu.assertEquals(block.handledX, 2)
        lu.assertEquals(block.handledY, 1)
    end,

    testTopItemGetsPress = function ()
        local b1 = blocks.Block:new(1, 1)
        local b2 = blocks.Block:new(1, 1)

        function b1:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        function b2:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        local frame = frames.Frame:new():add(b1, 1, 1):add(b2, 1, 1)

        frame:routePress00(1, 1)

        lu.assertNil(b1.handledX)
        lu.assertNil(b1.handledY)
        lu.assertEquals(b2.handledX, 1)
        lu.assertEquals(b2.handledY, 1)
    end,

    -- Note: no check here of the result of routePress00(): see correlation checks later.

    testFrameCanTakeInput = function ()
        local frame = frames.Frame:new()

        function frame:press(x, y, how)
            self.handledX = x
            self.handledY = y
        end

        frame:routePress00(1, 2)

        lu.assertEquals(frame.handledX, 1)
        lu.assertEquals(frame.handledY, 2)
    end
}

local function mockGrid()
    local logging = { }

    return {
        led = function (self, x, y, val)
            -- Truncated float formatting so that we can compare precisely:
            table.insert(logging, string.format("x=%d y=%d v=%.2f", x, y, val))
        end,

        refresh = function (self)
            table.insert(logging, "refresh")
        end,

        logging = logging
    }
end

test_Rendering = {
    testBlockRender = function ()
        local block = blocks.Block:new(4, 4):fill(types.LampState.ON)
        local grid = mockGrid()
        local renderer = renderers.VariableBlockRenderer:new(2, 1, grid)

        renderer:render(block)

        local expected = {
            "x=1 y=1 v=15.00",
            "x=2 y=1 v=15.00",
            "refresh"
        }

        lu.assertEquals(grid.logging, expected)
    end,

    testFrameRender = function ()
        local block = blocks.Block:new(2, 2):fill(types.LampState.ON)
        local frame = frames.Frame:new()

        -- Shift block to right:
        frame:add(block, 2, 1)

        local grid = mockGrid()
        local renderer = renderers.VariableBlockRenderer:new(2, 1, grid)

        renderer:render(frame)

        local expected = {
            "x=1 y=1 v=0.00",
            "x=2 y=1 v=15.00",
            "refresh"
        }

        lu.assertEquals(grid.logging, expected)
    end,

    testMaskRender = function ()
        local block = blocks.Block:new(2, 2):fill(types.LampState.ON)

        -- Port starts at (2, 1):
        local port = masks.Mask:new(block, 2, 1, 1, 1)

        local grid = mockGrid()
        local renderer = renderers.VariableBlockRenderer:new(2, 1, grid)

        renderer:render(port)

        local expected = {
            "x=1 y=1 v=0.00",
            "x=2 y=1 v=15.00",
            "refresh"
        }

        lu.assertEquals(grid.logging, expected)
    end
}

test_PressCorrelation = {
    testSimpleBlockCorrelation = function ()
        local block = blocks.Block:new(1, 1)

        block.logging = { }

        function block:press(x, y, how)
            table.insert(self.logging, string.format("x=%d y=%d how=%d", x, y, how))
        end

        local mgr = manager.PressManager:new(block)

        mgr:press(1, 1, 1)
        mgr:press(1, 1, 0)

        local expected = {
            "x=1 y=1 how=1",
            "x=1 y=1 how=0"
        }

        lu.assertEquals(block.logging, expected)
    end,

    testPressEventsCorrelateWhenMaskMoves = function ()
        local block = blocks.Block:new(1, 1)

        block.logging = { }

        function block:press(x, y, how)
            table.insert(self.logging, string.format("x=%d y=%d how=%d", x, y, how))
        end

        local mask = masks.Mask:new(block, 1, 1, 2, 2)

        mgr = manager.PressManager:new(mask)

        -- press, with 2x2 port directly over block:
        mgr:press(1, 1, 1)
        -- print(inspect.inspect(block.logging))

        -- move the port to the right:
        mask:setX(mask:getX() + 1)

        -- release: should still be at (1, 1) on the block:
        mgr:press(1, 1, 0)

        -- press again (ignored, since it\'s now outside the port,
        -- even though a hidden part of the block is here):
        mgr:press(1, 1, 1)

        local expected = {
            "x=1 y=1 how=1",
            "x=1 y=1 how=0"
        }

        lu.assertEquals(block.logging, expected)
    end,

    testFrameCorrelatesPress = function ()
        local frame = frames.Frame:new()

        frame.logging = { }

        function frame:press(x, y, how)
            table.insert(self.logging, string.format("x=%d y=%d how=%d", x, y, how))
        end

        local mgr = manager.PressManager:new(frame)

        mgr:press(1, 1, 1)
        mgr:press(1, 1, 0)

        local expected = {
            "x=1 y=1 how=1",
            "x=1 y=1 how=0"
        }

        lu.assertEquals(frame.logging, expected)
    end,

    testMaskCorrelatesPress = function ()
        local mask = masks.Mask:new(blocks.Block:new('1'), 1, 1, 1, 1)

        mask.logging = { }

        function mask:press(x, y, how)
            table.insert(self.logging, string.format("x=%d y=%d how=%d", x, y, how))
        end

        local mgr = manager.PressManager:new(mask)

        mgr:press(1, 1, 1)
        mgr:press(1, 1, 0)

        local expected = {
            "x=1 y=1 how=1",
            "x=1 y=1 how=0"
        }

        lu.assertEquals(mask.logging, expected)
    end,

    -- TODO: also check that hidden items still get clicks.
    -- TODO: check clicks also for raise/lower (check target for press and for release).

    testCorrelationWhenMovingInFrame = function ()
        local block = blocks.Block:new(1, 1)

        block.logging = { }

        frame = frames.Frame:new()
        frame:add(block, 1, 1)

        function block:press(x, y, how)
            table.insert(self.logging, string.format("x=%d y=%d how=%d", x, y, how))
            if how == 1 then
                frame:moveTo(self, 2, 2)
            end
        end

        mgr = manager.PressManager:new(frame)

        mgr:press(1, 1, 1)      -- Will move block to (2, 2) (before confirming)
        mgr:press(1, 1, 0)      -- Should still fire the block at local (1, 1)
        mgr:press(1, 1, 1)      -- Should be ignored: block has moved

        local expected = {
            "x=1 y=1 how=1",
            "x=1 y=1 how=0"
        }

        lu.assertEquals(block.logging, expected)
    end
}

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")
-- runner:runSuite("--pattern", "test_TwoDMap" .. "%." .. ".*", "--verbose", "--failure")
