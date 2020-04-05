local types = require "shado-lua/lib/types"

local Block = { }
Block.__index = Block

function Block.new(width, height)
   return setmetatable({ }, Block)
end

function Block:setLamp(x, y, lampState)
end

function Block:getLamp(x, y)
   return types.LampState.OFF
end

return {
   Block = Block
}
