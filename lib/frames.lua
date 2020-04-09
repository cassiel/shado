-- -*- lua-indent-level: 4; -*-

local types = require "shado-lua.lib.types"

local Frame = { }
Frame.__index = Frame

function Frame.new()
   return setmetatable({contentStack = { }}, Frame)
end

function Frame:add(item)
    -- Stacking order: [1] is lowest, [#len] is highest. "add" adds to "top".
    table.insert(self.contentStack, item)
    return self
end

function Frame:get(i)
    if i < 1 or i > #self.contentStack then
        error("shado: frame index out of range: " .. i)
    else
        return self.contentStack[i]
    end

end

function Frame:getLamp(x, y)
    local result = types.LampState.THRU

    for i = 1, #self.contentStack do
        result = self.contentStack[i]:getLamp(x, y):cover(result)
    end

    return result
end

return {
   Frame = Frame
}
