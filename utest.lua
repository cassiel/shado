-- Unit testing.

local types = require "shado/lib/types"

local lu = require "shado/lib/luaunit"

function test_1()
    lu.assertEquals(1, 1)
end

print(lu.LuaUnit.run())
