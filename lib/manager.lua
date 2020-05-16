-- -*- lua-indent-level: 4; -*-

--[[
   Manage press and release events. Objects in the renderable heirarchy
   might move around between press and release, so that matching calls to
   press() on an object might have mismatched coordinates - or the calls
   may not occur in matching pairs at all. Hence, we retain the object
   and coordinates for every successful press-on, indexed against actual
   monome coordinates, so that we can always deliver the corresponding
   release.
]]

local utils = require "shado.lib.utils"
local inspect = require "inspect"

local PressManager = { }
PressManager.__index = PressManager

--[[
   The PressManager maintains a two-dimensional map from device (x, y) to
   RouteResult, which encapsulates a press: it holds the (x, y) position
   of the original press-down on the target object, and the target itself.
   It has a release() method to send through a release to the target
   at the same coordinates, even if the target has moved.
]]

local RouteResult = { }
RouteResult.__index = RouteResult

function PressManager:new(target)
   local result = {
      target = target,
      pressMap = utils.TwoDMap:new()
   }

   return setmetatable(result, self)
end

function PressManager:press(x, y, how)
   self:release(x, y)

   if how ~= 0 then
      local press00 = self.target:routePress00(x, y)

      if press00 then
         self.pressMap:put(x, y, press00)
      end
   end
end

function PressManager:release(x, y)
   local routeResult00 = self.pressMap:get00(x, y)

   if routeResult00 ~= nil then
      routeResult00:release()
      self.pressMap:remove(x, y)
   end
end

function RouteResult:new(target, x, y)
   local result = {target = target, x = x, y = y}
   return setmetatable(result, self)
end

function RouteResult:release()
   self.target:press(self.x, self.y, 0)
end

return {
   PressManager = PressManager,
   RouteResult = RouteResult
}
