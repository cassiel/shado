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

local appFiles = {
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

--[[
   Scrolling an app into view via a clock. We block the keys while
   scrolling to avoid confusion, and also clear the display to
   update it once the scroll has finished. (Refinement: we should
   scroll the display too!)
]]

local keysBlocked = false

local function scroller(oldFrom, oldTo, oldStep, newOffset, displayText)
   keysBlocked = true

   return function ()
      -- We've already brought the new app to the top (index 1):
      local oldAppLayer = frame:get(2)
      local newAppLayer = frame:get(1)

      -- Scroll the pair of app layers up or down:
      for i = oldFrom, oldTo, oldStep do
         frame:moveTo(oldAppLayer, 1, i)
         frame:moveTo(newAppLayer, 1, i + newOffset)
         renderer:render(frame)
         clock.sleep(0.02)
      end

      appDisplayText = displayText
      -- redraw()
      keysBlocked = false
   end
end

local function selectApp(app, sense)
    --[[
        sense == -1 to scroll "view" up, +1 for down, 0 for immediate select.
        TODO: we should really wrap each app in a mask to avoid it getting any
        out-of-bounds presses (or displaying out-of-bounds) when it's pushed away.
    ]]

    -- Immediately clear screen (we'll draw the new text on end of scroll):
    appDisplayText = ""
    redraw()

    local displayText = app.displayText or ""

    -- New application to top of display stack:
    frame:top(app.layer)

    if sense == 1 then
        -- Old app moves up, corner from (1, 0) to (1, -7).
        -- New app is below, offset 8:
        clock.run(scroller(0, -7, -1, 8, displayText))
    elseif sense == -1 then
        -- Old app moves down, corner from (1, 2) to (1, 9):
        -- New app is above, offset -8:
        clock.run(scroller(2, 9, 1, -8, displayText))
    else        -- Immediate move (launch of main script)
        frame:moveTo(frame:get(2), 1, 9)        -- Old top app out of line of sight.
        frame:moveTo(frame:get(1), 1, 1)        -- New top app into line of sight.
        renderer:render(frame)

        appDisplayText = displayText
        -- redraw()
    end
end

-- For seamstress, call `key` manually from REPL: `key(2, 1)` or `key(3, 1)`.

function key(n, z)
   if not keysBlocked then
      local newIndex, sense

      if z == 1 then
         if n == 3 then      -- Next app (and wrap):
            newIndex = currentAppIndex + 1
            if newIndex > #apps then newIndex = 1 end
            sense = 1
         elseif n == 2 then  -- Previous app (and wrap):
            newIndex = currentAppIndex - 1
            if newIndex < 1 then newIndex = #apps end
            sense = -1
         else                -- (Not reachable:)
            newIndex = currentAppIndex
            sense = 0
         end

         currentAppIndex = newIndex
         currentApp = apps[currentAppIndex]
         selectApp(currentApp, sense)
      end
   end
end


-- Service periodic counter, via app:count() if any:
local function service(i)
   if currentApp.count then
      currentApp:count(i)
      renderer:render(frame)
   end
end

function init()
   renderer:render(frame)

   local mgr = manager.PressManager:new(frame)

   g.key = function (x, y, how)
      mgr:press(x, y, how)
      renderer:render(frame)
   end

   -- Apps get serviced with a counter every 0.1 seconds
   local counter = metro.init()
   counter.time = 0.1
   counter.count = -1
   counter.event = service
   counter:start()

   selectApp(currentApp, 0)
end
