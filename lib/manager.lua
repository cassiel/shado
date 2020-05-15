-- -*- lua-indent-level: 4; -*-

local PressManager = { }
PressManager.__index = PressManager

function PressManager:new(target)
   return setmetatable({target = target}, self)
end

function PressManager:press(x, y, how)
   -- TODO: incomplete
   self.target:routePress00(x, y)
end

return {
   PressManager = PressManager
}
