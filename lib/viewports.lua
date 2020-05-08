-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local ViewPort = { }
ViewPort.__index = ViewPort

function ViewPort.new(content, x, y, width, height)
    local result = {
        content = content,
        x = x,
        y = y,
        width = width,
        height = height
    }

    return setmetatable(result, ViewPort)
end

function ViewPort:setX(x)
    self.x = x
end

function ViewPort:setY(y)
    self.y = y
end

function ViewPort:getLamp(x, y)
    if x >= self.x and x < self.x + self.width
    and y >= self.y and y < self.y + self.height then
        return self.content:getLamp(x, y)
    else
        return types.LampState.THRU
    end
end

return {
    ViewPort = ViewPort
}
