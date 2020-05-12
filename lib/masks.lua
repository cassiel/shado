-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local Mask = { }
Mask.__index = Mask

function Mask:new(content, x, y, width, height)
    local result = {
        content = content,
        x = x,
        y = y,
        width = width,
        height = height
    }

    return setmetatable(result, self)
end

function Mask:setX(x)
    self.x = x
end

function Mask:setY(y)
    self.y = y
end

function Mask:inRange(x, y)
    return x >= self.x and x < self.x + self.width
        and y >= self.y and y < self.y + self.height
end

function Mask:getLamp(x, y)
    if self:inRange(x, y) then
        return self.content:getLamp(x, y)
    else
        return types.LampState.THRU
    end
end

function Mask:routePress00(x, y)
    if self:inRange(x, y) then
        return self.content:routePress00(x, y)
    else
        return nil
    end
end

return {
    Mask = Mask
}
