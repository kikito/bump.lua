require 'lib.middleclass'
local bump       = require 'lib.bump'
local bump_debug = require 'lib.bump_debug'
local gamera     = require 'lib.gamera'

local Map        = require 'map'
local Player     = require 'player'
local Turret     = require 'turret'

local drawDebug   = false  -- draw bump's debug info, fps and memory
local player               -- a reference to the player (so the camera can follow him)
local instructions = [[
  bump.lua demo

    left,right: move
    up:     jump/fly
    return: reset map
    delete: run garbage collection
    tab:         toggle debug info (%s)
    right shift: toggle fly (%s)
]]

local camera, world, map

local function reset()
  world  = bump.newWorld()
  player = Player:new(world, 60, 60)
  map    = Map:new(world, player)
  camera = gamera.new(0,0,map.width,map.height)
end

function love.load()
  reset()
end

-- Updating
-- Note that we only update elements that are visible to the camera. This is optional
function love.update(dt)

  player:update(dt)

  local visibleThings, len = world:queryBox(camera:getVisible())
  local turrets, turretsLen = {},0
  for i=1, len do
    if visibleThings[i]:isInstanceOf(Turret) then
      turretsLen = turretsLen + 1
      turrets[turretsLen] = visibleThings[i]
    end
  end

  for i=1, turretsLen do
    turrets[i]:update(dt)
  end

  camera:setPosition(player:getCenter())
end

-- Drawing
function love.draw()
  camera:draw(function(l,t,w,h)
    if drawDebug then bump_debug.draw(world) end
    local visibleThings, len = world:queryBox(l,t,w,h)
    for i=1, len do
      visibleThings[i]:draw()
    end
  end)

  love.graphics.setColor(255, 255, 255)

  local msg = instructions:format(tostring(drawDebug), tostring(player.canFly))
  love.graphics.print(msg, 550, 10)

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB"):format(love.timer.getFPS(), collectgarbage("count"))
    love.graphics.print(statistics, 630, 580 )
  end
end

-- Non-player keypresses

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    collectgarbage("collect")
  end
  if k=="return" then
    reset()
  end
  if k=="rshift" then
    player.canFly = not player.canFly
  end
end
