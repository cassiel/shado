-- -*- lua-indent-level: 4; -*-

local types = require "shado.lib.types"

local ViewPort = { }
ViewPort.__index = ViewPort

function ViewPort.new(content, x, y, width, height)
    -- TODO
    return setmetatable({ }, ViewPort)
end

function ViewPort:getLamp(x, y)
    -- TODO
    return types.LampState.THRU
end

return {
    ViewPort = ViewPort
}
