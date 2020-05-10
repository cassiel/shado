-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local ViewPort = { }
ViewPort.__index = ViewPort

function ViewPort:new(content, x, y, width, height)
    local result = {
        content = content,
        x = x,
        y = y,
        width = width,
        height = height
    }

    return setmetatable(result, self)
end

function ViewPort:setX(x)
    self.x = x
end

function ViewPort:setY(y)
    self.y = y
end

function ViewPort:inRange(x, y)
    return x >= self.x and x < self.x + self.width
        and y >= self.y and y < self.y + self.height
end

function ViewPort:getLamp(x, y)
    if self:inRange(x, y) then
        return self.content:getLamp(x, y)
    else
        return types.LampState.THRU
    end
end

function ViewPort:routePress00(x, y, how)
    if self:inRange(x, y) then
        return self.content:routePress00(x, y, how)
    else
        return nil
    end
end

return {
    ViewPort = ViewPort
}
