-- -*- lua-indent-level: 4; -*-

local types = require "shado-lua.lib.types"

local Frame = { }
Frame.__index = Frame

function Frame.new()
   return setmetatable({contentStack = { }}, Frame)
end

function Frame:add(item)
   return self
end

function Frame:get(i)
end

return {
   Frame = Frame
}
