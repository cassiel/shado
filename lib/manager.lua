-- -*- lua-indent-level: 4; -*-

--[[--
  Internal button press management machinery.

  Manage press and release events. Objects in the renderable heirarchy
  might move around between press and release, so that matching calls to
  `press()` on an object might have mismatched coordinates - or the calls
  may not occur in matching pairs at all. Hence, we retain the object
  and coordinates for every successful press-on, indexed against actual
  grid coordinates, so that we can always deliver the corresponding
  release.
]]

local utils = require "shado.lib.utils"
-- local inspect = require "inspect"

local PressManager = { }
PressManager.__index = PressManager

local RouteResult = { }
RouteResult.__index = RouteResult

--[[--
  The `PressManager` maintains a two-dimensional map from device `(x, y)` to
  `RouteResult`, which encapsulates a press: it holds the `(x, y)` position
  of the original press-down on the target object, and the target itself.
  It has a `release()` method to send through a release to the target
  at the same coordinates, even if the target has moved (in location, and/or
  in the object heirarchy).

  @param target the top-level `shado` object handling button presses (and releases)
  @return a press manager
]]

function PressManager:new(target)
   local result = {
      target = target,
      pressMap = utils.TwoDMap:new()
   }

   return setmetatable(result, self)
end

--[[--
  Route a button press. If the object (or object heirarchy) handles
  the press, remember the object and location so that a release can be correctly
  routed to match.

  @param x the X coordinate
  @param y the Y coordinate
  @param how `1` for press, `0` for release
]]

function PressManager:press(x, y, how)
   self:release(x, y)           -- TODO can we unit test this?

   if how ~= 0 then
      local press00 = self.target:routePress00(x, y)

      if press00 then
         self.pressMap:put(x, y, press00)
      end
   end
end

--[[--
  Route a button release. We look for a stored button press
  in the same physical location.

  @param x the X coordinate
  @param y the Y coordinate
]]

function PressManager:release(x, y)
   local routeResult00 = self.pressMap:get00(x, y)

   if routeResult00 ~= nil then
      routeResult00:release()
      self.pressMap:remove(x, y)
   end
end

--[[--
  A new routing result.

  @param target the `shado` object handling the press
  @param x the X coordinate
  @param y the Y coordinate
  @return a route result
]]

function RouteResult:new(target, x, y)
   local result = {target = target, x = x, y = y}
   return setmetatable(result, self)
end

--[[--
  Handle a button release. Action the release at the
  correct location on the correct object.
]]

function RouteResult:release()
   self.target:press(self.x, self.y, 0)
end

return {
   PressManager = PressManager,
   RouteResult = RouteResult
}
