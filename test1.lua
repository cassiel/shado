-- SHADO.
-- Test script 1.

local g = nil


for k, _ in pairs(package.loaded) do
    if k:find("shado-lua/lib/") == 1 then
        print("rm " .. k)
        package.loaded[k] = nil
    end
end

local f1 = require "shado-lua/lib/f1"

print(">>>")
print(f1)
print("<<<")

function init()
    g = grid.connect()
    screen.clear()
end

function key(n, z)
    f1.process(g, z)
end
