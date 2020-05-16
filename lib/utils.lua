-- -*- lua-indent-level: 4; -*-

local TwoDMap = { }
TwoDMap.__index = TwoDMap

function TwoDMap:new()
   return setmetatable({map = { }}, self)
end

function TwoDMap:put(x, y, item)
   if self.map[x] == nil then
      self.map[x] = { }
   end

   self.map[x][y] = item
end

function TwoDMap:get00(x, y)
   local col00 = self.map[x]

   if col00 then
      return col00[y]
   else
      return nil
   end
end

function TwoDMap:remove(x, y)
   local col00 = self.map[x]

   if col00 then
      col00[y] = nil
   end
end

return {
   TwoDMap = TwoDMap
}
