require 'lib.middleclass'
local bump       = require 'lib.bump'
local bump_debug = require 'lib.bump_debug'
local gamera     = require 'lib.gamera'

local Map        = require 'Map'
local Entity     = require 'entities.Entity'
local Player     = require 'entities.Player'
local Coin       = require 'entities.Coin'

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
  Entity:destroyAll()
  world  = bump.newWorld()
  map    = Map:new(world)
  player = Player:new(world, 60, 60)
  camera = gamera.new(0,0,map.width,map.height)
end

function love.load()
  reset()
end

-- Updating
-- Note that we only update elements that are visible to the camera. This is optional
function love.update(dt)
  player:update(dt)
  camera:setPosition(player:getCenter())
  local visibleEntities, len = world:queryBox(camera:getVisible())
  for i=1, len do
    local entity = visibleEntities[i]
    if entity:isInstanceOf(Coin) then entity:update(dt) end
  end
end

-- Drawing
function love.draw()
  camera:draw(function(l,t,w,h)
    if drawDebug then bump_debug.draw(world) end
    local visibleEntities, len = world:queryBox(l,t,w,h)
    for i=1, len do
      visibleEntities[i]:draw()
    end
  end)

  love.graphics.setColor(255, 255, 255)

  local msg = instructions:format(tostring(drawDebug), tostring(player.canFly))
  love.graphics.print(msg, 550, 10)
  love.graphics.print(("coins: %d"):format(player.coins), 10, 10)

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
