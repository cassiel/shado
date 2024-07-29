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

function setup_arc()
   local a = arc.connect()
   local renderer = renderers.VariableArcRenderer:new(4, a)

   local frame = frames.Frame:new()
   renderer:render(frame)

   for k, v in pairs(a) do
      print(k)
   end

   a.delta = function (n, d)
      print("DELTA", n, d)
   end

   a.key = function (n, z)
      print("KEY", n, z)
   end
end

function setup_params()
   midi_devices = {}
   midi_device_names = {}

   for i = 1, #midi.vports do -- for each MIDI port:
      -- [//\\]
      midi_devices[i] = midi.connect(i) -- connect to the device
      -- [//\\]

      midi_devices[i].event = function(bytes) -- establish what to do with incoming MIDI messages

      end

      midi_device_names[i] = i .. ": " .. midi.vports[i].name -- log its name
   end

   params:add_separator("MIDI output")
   params:add_option("midi_output_device", "port", midi_device_names, 1)
end

function init()
   setup_params()
   setup_arc()
end
