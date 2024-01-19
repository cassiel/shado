-- -*- lua-indent-level: 4; -*-

--- Masks: containers for clipping and offsetting other `shado` objects.

local types = require "shado/lib/types"
local manager = require "shado/lib/manager"

local Mask = { }
Mask.__index = Mask

--[[--
  Create a new mask around an existing object. The object doesn't
  shift its position, but is covered with a mask which starts at
  `(x, y)` (origin is `(1, 1)`) and has size `(width, height)`.
  Nothing appears outside the mask - the area is transparent - and
  button presses outside the mask are ignored.

  @param content the object to mask
  @param x the leftmost coordinate of the mask
  @param y the topmost coordinate of the mask
  @param width the width of the mask
  @param height the height of the mask
  @return a new mask
]]

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

--[[--
  Update the leftmost coordinate of the mask,
  shifting it horizontally.

  @param x the X coordinate
]]

function Mask:setX(x)
    self.x = x
end

--[[--
  Update the topmost coordinate of the mask,
  shifting it vertically.

  @param y the Y coordinate
]]

function Mask:setY(y)
    self.y = y
end

--[[--
  Get the leftmost coordinate of the mask.

  @return the X coordinate
]]

function Mask:getX()
    return self.x
end

--[[--
  Get the topmost coordinate of the mask.

  @return the Y coordinate
]]

function Mask:getY()
    return self.y
end

--[[--
  Determine whether a coordinate point `(x, y)` is within
  the mask area.

  @param x the X coordinate
  @param y the Y coordinate
  @return `true` or `false` depending on inclusion
]]

function Mask:inRange(x, y)
    return x >= self.x and x < self.x + self.width
        and y >= self.y and y < self.y + self.height
end

--[[--
  Get the effective lamp value at position `(x, y)`.
  If the position is within the mask, then return the value
  calculated from the contained object, otherwise
  return `LampState.THRU`.

  @param x the X coordinate
  @param y the Y coordinate
  @return the lamp value
  @see types.LampState
]]

function Mask:getLamp(x, y)
    if self:inRange(x, y) then
        return self.content:getLamp(x, y)
    else
        return types.LampState.THRU
    end
end

--[[--
  The default handler for button press events. It returns
  `false`, which will cause press events to be passed into
  the mask's contained object. Override to handle buttons
  in the mask itself, rather than its contained object.

  @param x the X location of the press
  @param y the Y location of the press
  @param how the kind of button event: `1` for press, `0` for release.
  @return `false`
]]

function Mask:press(x, y, how)
    return false
end

--[[--
  Internal function for routing press-on events. Returns a `RouteResult`
  object so that the corresponding press-off can be handled properly.

  Return `nil` if the coordinate position is outside the mask.
  Otherwise, if the mask itself does not handle the press, then the constituent
  object is tried.

  There is some subtlety here; if the mask itself handles the press,
  the coordinate system treats the top-left corner of the mask
  as `(1, 1)`, regardless of where the mask is positioned over its
  enclosed object. If the object handles the press, the coordinates are
  as if the mask were not present.
]]

function Mask:routePress00(x, y)
    if self:inRange(x, y) then
        -- Are we handling the press in the mask directly?
        local portX = x - self.x + 1
        local portY = y - self.y + 1
        local done = (self:press(portX, portY, 1) ~= false)

        if done then
            return manager.RouteResult:new(self, x, y)
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
