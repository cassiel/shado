-- "Native" speed-test.

local g = grid.connect()

local lastX = 1
local lastY = 1

for x = 1, 16 do
    for y = 1, 8 do
        g:led(lastX, lastY, 0)
        --g:all(0)
        g:led(x, y, 15)
        g:refresh()
        lastX = x
        lastY = y
    end
end
