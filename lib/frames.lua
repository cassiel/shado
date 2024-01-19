-- -*- lua-indent-level: 4; -*-

--- Frames: stacks of shado objects (including sub-frames).

local types = require "shado/lib/types"
local manager = require "shado/lib/manager"

local Frame = { }
Frame.__index = Frame

--- Create a new, empty frame.

function Frame:new()
   return setmetatable({contentStack = { }}, self)
end

--[[--
  Add an item to a frame, at the top. Calls can be cascaded, thus:

    frame:add(item1, x1, y1):add(item2, x2, y2)

  Note: an item should not be added to a frame more than once.
  (*TODO* Test for this.)

  @param item the `shado` object to add
  @param x the horizontal location, `1` being the origin
  @param y the vertical location, `1` being the origin
  @return the frame
]]

function Frame:add(item, x, y)
    -- Stacking order: [1] is lowest, [#len] is highest. "add" adds to "top".
    table.insert(self.contentStack, {item = item, x = x, y = y, visible = true})
    return self
end

local function find00(stack, item)
    for i, v in ipairs(stack) do
        if v.item == item then
            return v, i
        end
    end

    return nil
end

local function find(stack, item)
    local v, i = find00(stack, item)

    if v then
        return v, i
    else
        error("shado: item not found in frame")
    end
end

--[[--
  Remove a `shado` object from the frame.
  Raises an error if the item isn't present.
  *TODO* Calls to `remove` should chain.
  @param item the `shado` object to remove
]]

function Frame:remove(item)
    local _, i = find(self.contentStack, item)
    table.remove(self.contentStack, i)
end

--[[--
  Bring a `shado` object to the top of a frame.
  Raises an error if the item isn't present.
  *TODO* Calls to `top` should chain.
  @param item the `shado` object to raise
]]

function Frame:top(item)
    local s = self.contentStack
    local v, i = find(s, item)

    table.remove(s, i)
    table.insert(s, v)
end

--[[--
  Drop a `shado` object to the bottom of a frame.
  Raises an error if the item isn't present.
  *TODO* Calls to `bottom` should chain.
  @param item the `shado` object to lower
]]

function Frame:bottom(item)
    local s = self.contentStack
    local v, i = find(s, item)

    table.remove(s, i)
    table.insert(s, 1, v)
end

local function setVisibility(stack, item, how)
    local v, _ = find(stack, item)
    v.visible = how
end

--[[--
  Hide a `shado` object in a frame (effectively, make
  it transparent). This does not affect its response
  to button presses.
  @param item the object to hide
]]

function Frame:hide(item)
    setVisibility(self.contentStack, item, false)
end

--[[--
  Show a `shado` object in a frame. This does
  not affect its response to button presses.
  @param item the object to show
]]

function Frame:show(item)
    setVisibility(self.contentStack, item, true)
end

--[[--
  Move an object in a frame to a new location.
  Origin is `(1, 1).`
  Returns the frame, for chaining.
  @param item the object to move
  @param x the new X location
  @param y the new Y location
  @return the frame
]]

function Frame:moveTo(item, x, y)
    local v, _ = find(self.contentStack, item)

    v.x = x
    v.y = y
    return self
end

--[[--
  Retrieve an object from a frame. The topmost
  object is at index `1`. Throws an error if
  the index is less than `1` or greater than the
  number of objects present.
  @param i the index of the desired object
  @return the object
]]

function Frame:get(i)
    local len = #self.contentStack
    if i < 1 or i > len then
        error("shado: frame index out of range: " .. i)
    else
        -- Top item is at the end; our indexing is from the top, so:
        return self.contentStack[len - i + 1].item
    end
end

--[[--
  Get the computed "lamp" value for a frame at location
  `(x, y)`. If the frame is empty, or the coordinates `(x, y)` are
  outside any objects in the frame, the result will be
  `types.LampState.THRU`.
  @param x the X location to examine
  @param y the Y location to examine
  @return the lamp value
  @see types.LampState
]]

function Frame:getLamp(x, y)
    local result = types.LampState.THRU

    for i = 1, #self.contentStack do
        local entry = self.contentStack[i]

        if entry.visible then
            result = entry.item:getLamp(x - entry.x + 1, y - entry.y + 1):cover(result)
        end
    end

    return result
end

--[[--
  The default handler for button press events. It returns
  `false`, which will cause press events to be passed into
  the frame's component objects. Override to handle buttons
  in the frame itself, rather than its components.

  @param x the X location of the press
  @param y the Y location of the press
  @param how the kind of button event: `1` for press, `0` for release.
  @return `false`
]]

function Frame:press(x, y, how)
    return false
end

--[[--
  Internal function for routing press-on events. Returns a `RouteResult`
  object so that the corresponding press-off can be handled properly.

  If the frame itself does not handle the press, then the constituent
  objects are interrogated from top to bottom, until one does handle
  it (by returning a result from its `routePress00` method). If there is
  no result, then the frame as a whole has not handled the press, so
  return `nil`.
]]

function Frame:routePress00(x, y)
    -- TODO: if we care: what if stack content changes as a result of press() calls?
    -- (We should dup.)
    if self:press(x, y, 1) ~= false then
        return manager.RouteResult:new(self, x, y)
    else
        -- End of stack is top.
        for i = #self.contentStack, 1, -1 do
            v = self.contentStack[i]
            local p = v.item:routePress00(x - v.x + 1, y - v.y + 1)
            if p then
                return p
            end
        end

        return nil
    end
end

return {
   Frame = Frame
}
