-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local viewports = require "shado.lib.viewports"
local frames = require "shado.lib.frames"
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

        lu.assertEquals(b:getLamp(3, 1), types.LampState.ON, "lamp 1")
        lu.assertEquals(b:getLamp(1, 2), types.LampState.THRU, "lamp 2")
        lu.assertEquals(b:getLamp(4, 3), types.LampState.FLIP, "lamp 3")
    end,

    testDetectsBadTokenLists = function ()
        lu.assertErrorMsgMatches(".*%sshado: length mismatch%s.*",
                                 blocks.Block.new, "11 111")
        lu.assertErrorMsgMatches(".*%sshado: bad character%s.*",
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
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange:.*",
                                 f.get, f, 0)
        lu.assertErrorMsgMatches(".*%sshado:%s.*%srange:.*",
                                 f.get, f, 1)
    end,

    testCanAddToBottom = function ()
        local f = frames.Frame.new()
        local b1 = blocks.Block.new(0, 0)
        local b2 = blocks.Block.new(0, 0)

        f:add(b1, 1, 1)
        f:add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)

        -- Test chaining:
        f = frames.Frame.new()
        f:add(b1, 1, 1):add(b2, 1, 1)

        lu.assertIs(f:get(1), b1)
        lu.assertIs(f:get(2), b2)
    end,

    testFrameStackingOrder = function ()
        local f = frames.Frame.new()
        f:add(blocks.Block.new('1')):add(blocks.Block.new('0'))
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)

        f = frames.Frame.new()
        f:add(blocks.Block.new('1')):add(blocks.Block.new('/'))
        lu.assertEquals(f:getLamp(1, 1), types.LampState.OFF)
    end
}

test_ViewPorts = {
    testCanCropOnBlock = function ()
        --[[
        IPressRouter block = new Block(4, 4).fill(LampState.ON);
        IRenderable cropped = new ViewPort(block, 0, 1, 4, 2);

        assertEquals("above/1", LampState.THRU, cropped.getLamp(0, 0));
        assertEquals("within/1", LampState.ON, cropped.getLamp(0, 1));
        assertEquals("within/2", LampState.ON, cropped.getLamp(3, 2));
        assertEquals("above/1", LampState.THRU, cropped.getLamp(3, 3));
        ]]

        local block = blocks.Block.new(4, 4):fill(types.LampState.ON)
        -- args: (x, y, width, height). (1, 1) is normalised viewport position, Lua-style.
        local cropped = viewports.ViewPort.new(block, 1, 2, 4, 2)

        --[[
        lu.assertEquals(cropped:getLamp(1, 1), types.LampState.THRU, "above/1")
        lu.assertEquals(cropped:getLamp(1, 2), types.LampState.ON, "within/1")
        lu.assertEquals(cropped:getLamp(4, 3), types.LampState.ON, "within/2")
        lu.assertEquals(cropped:getLamp(4, 4), types.LampState.THRU, "above/1")
        ]]
    end,

    testCanMoveWindow = function ()
        --[[
        IPressRouter block = new Block(4, 4).fill(LampState.ON);
        ViewPort cropped = new ViewPort(block, 0, 0, 2, 2);

        assertEquals("TL/1", LampState.ON, cropped.getLamp(0, 0));
        assertEquals("BR/1", LampState.THRU, cropped.getLamp(3, 3));

        cropped.setX(2);

        assertEquals("TL/2", LampState.THRU, cropped.getLamp(0, 0));
        assertEquals("BR/2", LampState.THRU, cropped.getLamp(3, 3));

        cropped.setY(2);

        assertEquals("TL/3", LampState.THRU, cropped.getLamp(0, 0));
        assertEquals("BR/3", LampState.ON, cropped.getLamp(3, 3));
        ]]
    end,

    testWillMapPressToLocalCoordinates = function ()
        --[[
        final IPressable pressable = itsContext.mock(IPressable.class);

        itsContext.checking(new Expectations() {{
            //	Expect a press at (0, 0):
            one(pressable).press(0, 0, 1); will(returnValue(true));
        }});

        IPressRouter b = new Block(2, 2);

        ViewPort w =
            new ViewPort(b, 1, 0, 1, 1) {
                @Override public boolean press(int x, int y, int how) {
                    return pressable.press(x, y, how);
                }
            };

        assertNull("window press out of range", w.routePress00(0, 0));
        assertNotNull("window press in range", w.routePress00(1, 0));
        ]]
    end,

    testWillCorrectlyPassPressesToContents = function ()
        --[[
		final IPressable pressable = itsContext.mock(IPressable.class);

		itsContext.checking(new Expectations() {{
			//	Expect a press at (1, 0):
			one(pressable).press(1, 0, 1); will(returnValue(true));
		}});

		//	We'll expect a press to the inner block:
		IPressRouter b = new Block(2, 2) {
			@Override public boolean press(int x, int y, int how) {
				return pressable.press(x, y, how);
			}
		};

		//	The port is at X=1:
		ViewPort w =
			new ViewPort(b, 1, 0, 1, 1) {
				@Override public boolean press(int x, int y, int how) {
					return false;
				}
			};

		assertNull("port press out of range", w.routePress00(0, 0));
		assertNotNull("port press in range", w.routePress00(1, 0));
        ]]
	end,

    testPortWillNotPassFrameStampToContent = function ()
        --[[
        final IPressable pressable = itsContext.mock(IPressable.class);

        itsContext.checking(new Expectations() {{
                                    //	only expect the bottom item to route a click:
            one(pressable).press(0, 0, 1); will(returnValue(true));
        }});

        IPressRouter b = new Block(1, 1) {
            @Override public boolean press(int x, int y, int how) {
                return pressable.press(x, y, how);
            }
        };

        ViewPort p = new ViewPort(b, 0, 0, 1, 1);

        Frame f = new Frame();

        f.add(p, 0, 0);

        assertNotNull("press", f.routePress00(0, 0));
        ]]
    end,

    testPressEventsCorrelateWhenViewPortMoves = function ()
        --[[
        final IPressable pressable = itsContext.mock(IPressable.class);

        itsContext.checking(new Expectations() {{
                                    one(pressable).press(0, 0, 1); will(returnValue(true));
                                    one(pressable).press(0, 0, 0); will(returnValue(true));
        }});

        IPressRouter b = new Block(2, 2) {
            @Override public boolean press(int x, int y, int how) {
                return pressable.press(x, y, how);
                                                                  }
                                         };

        ViewPort p = new ViewPort(b, 0, 0, 2, 2);

        PressManager mgr = new PressManager(p);

        //	press, with 2x2 port directly over block:
            mgr.press(0, 0, 1);

        //	move the port:
            p.setX(p.getX() + 1);

        //	release: should still be at (0, 0).
            mgr.press(0, 0, 0);

        //	press again (ignored, since it's now outside the port,
		//	even though a hidden part of the block is here):
            mgr.press(0, 0, 1);
        ]]
    end
}

runner = lu.LuaUnit.new()
runner:runSuite("--verbose")
