-- SHADO demo.
-- Nick Rothwell, nick@cassiel.com

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local renderers = require "shado.lib.renderers"

local block = blocks.Block:new(4, 4):fill(types.LampState.ON)

local g = grid.connect()

renderers.VariableBlockRenderer:new(16, 8, g):render(block)

--g:all(7)
--g:refresh()
