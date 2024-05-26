-- Loose port of the old "spinner" Clojure app. Map arc knobs into
-- MIDI out, with animation.

for k, _ in pairs(package.loaded) do
   if k:find("shado.") == 1 then
      print("purge " .. k)
      package.loaded[k] = nil
   end
end

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"

local a = arc.connect()
local renderer = renderers.VariableArcRenderer:new(4, a)

local frame = frames.Frame:new()
renderer:render(frame)
