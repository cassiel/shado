--- ## shado-seam
-- shado demonstrator script.
-- Nick Rothwell, nick@cassiel.com.
-- github.com/cassiel/shado
-- https://llllllll.co/t/51408
--
-- Scratch copy of shado.lua in attempt to port to seamstress.
-- (No K2/K3 keys available.)
-- Clear with: `package.loaded["shado/shado-seam"] = nil` before reloading.
--
-- Source: [https://github.com/cassiel/shado](https://github.com/cassiel/shado).
--
-- Introduction and description [here](https://github.com/cassiel/shado/blob/master/README.MANUAL.org).

-- For development, purge any shado scripts/libraries from the cache on reload:
for k, _ in pairs(package.loaded) do
    if k:find("shado/") == 1 then
        print("purge " .. k)
        package.loaded[k] = nil
    end
end

local types = require "shado/lib/types"
local blocks = require "shado/lib/blocks"
local frames = require "shado/lib/frames"
local renderers = require "shado/lib/renderers"
local manager = require "shado/lib/manager"

-- Build list of apps (and stack their content in a frame):
local frame = frames.Frame:new()

-- local appFiles = util.scandir(_path.code .. "shado/apps")
-- local appFiles = util.scandir("shado/apps")
-- Problem with scandir, so:

appFiles = {
   "shado/apps/counter.lua",
   "shado/apps/nugget.lua",
   "shado/apps/pyramids.lua",
   "shado/apps/square.lua"
}

local apps = { }

for _, v in ipairs(appFiles) do
   local _, _, name = string.find(v, "([%a_]+)%.lua$")
   print("inserting app" .. "shado/apps/" .. name)
   local app = require("shado/apps/" .. name)
   table.insert(apps, app)
   frame:add(app.layer, 1, 9)   -- All apps are visually sitting below the actual grid, at y = 9.
end

-- Keep track of currently selected/running app:
local currentAppIndex = 1
local currentApp = apps[currentAppIndex]

-- Attach shado machinery to grid:
local g = grid.connect()
local renderer = renderers.VariableBlockRenderer:new(16, 8, g)
