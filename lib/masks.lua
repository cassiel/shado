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

function Mask:getX()
    return self.x
end

function Mask:getY()
    return self.y
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

function Mask:press(x, y, how)
    return false
end

function Mask:routePress00(x, y)
    if self:inRange(x, y) then
        -- Are we handling the press in the mask directly?
        -- TODO: should be x - self.x + 1, but let's unit test first.
        local portX = x - self.x + 1
        local portY = y - self.y + 1
        local done = (self:press(portX, portY, 1) ~= false)

        if done then
            return "TODO" -- PressRouteResult(self, x, y)
        else
            return self.content:routePress00(x, y)
        end
    else
        return nil
    end
end

return {
    Mask = Mask
}
