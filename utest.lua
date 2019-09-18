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

runner = lu.LuaUnit.new()
runner:setOutputType("tap")
runner:runSuite("--verbose")
