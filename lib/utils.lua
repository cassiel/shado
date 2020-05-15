-- -*- lua-indent-level: 4; -*-

local TwoDMap = { }
TwoDMap.__index = TwoDMap

function TwoDMap:new()
end

function TwoDMap:put(x, y, item)
end

function TwoDMap:get00(x, y)
end

return {
   TwoDMap = TwoDMap
}
