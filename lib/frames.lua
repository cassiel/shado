-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"
local manager = require "shado.lib.manager"

local Frame = { }
Frame.__index = Frame

function Frame:new()
   return setmetatable({contentStack = { }}, self)
end

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

function Frame:remove(item)
    local _, i = find(self.contentStack, item)
    table.remove(self.contentStack, i)
end

-- TODO top/bottom/show/hide should cascade!

function Frame:top(item)
    local s = self.contentStack
    local v, i = find(s, item)

    table.remove(s, i)
    table.insert(s, v)
end

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

function Frame:hide(item)
    setVisibility(self.contentStack, item, false)
end

function Frame:show(item)
    setVisibility(self.contentStack, item, true)
end

function Frame:moveTo(item, x, y)
    local v, _ = find(self.contentStack, item)

    v.x = x
    v.y = y
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

        if entry.visible then
            result = entry.item:getLamp(x - entry.x + 1, y - entry.y + 1):cover(result)
        end
    end

    return result
end

function Frame:press(x, y, how)
    return false
end

function Frame:routePress00(x, y)
    -- TODO: optional local handling of presses
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
