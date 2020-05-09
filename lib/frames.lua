-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local Frame = { }
Frame.__index = Frame

function Frame.new()
   return setmetatable({contentStack = { }}, Frame)
end

function Frame:add(item, x, y)
    -- Stacking order: [1] is lowest, [#len] is highest. "add" adds to "top".
    table.insert(self.contentStack, {item = item, x = x, y = y})
    return self
end

function Frame:get(i)
    if i < 1 or i > #self.contentStack then
        error("shado: frame index out of range: " .. i)
    else
        return self.contentStack[i].item
    end

end

function Frame:getLamp(x, y)
    local result = types.LampState.THRU

    for i = 1, #self.contentStack do
        local entry = self.contentStack[i]
        result = entry.item:getLamp(x - entry.x + 1, y - entry.y + 1):cover(result)
    end

    return result
end

return {
   Frame = Frame
}
