require 'lib.middleclass'
local bump       = require 'lib.bump'
local bump_debug = require 'lib.bump_debug'
local camera     = require 'lib.camera'

local map        = require 'map'
local Entity     = require 'entities.Entity'
local Player     = require 'entities.Player'

local maxdt       = 0.1    -- if the window loses focus/etc, use this instead of dt
local drawDebug   = false  -- draw bump's cells
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

function bump.collision(obj1, obj2, dx, dy)
  obj1:collision(obj2,  dx,  dy)
  obj2:collision(obj1, -dx, -dy)
end

function bump.endCollision(obj1, obj2)
  obj1:endCollision(obj2)
  obj2:endCollision(obj1)
end

function bump.shouldCollide(obj1, obj2)
  return obj1:shouldCollide(obj2) or
         obj2:shouldCollide(obj1)
end

function bump.getBBox(obj)
  return obj:getBBox()
end

function reset()
  map.reset()
  player = Player:new(60, 60)
end

function love.load()
  camera.setBoundary(0,0,map.width,map.height)
  reset()
end

function love.update(dt)
  dt = math.min(dt, maxdt)
  Entity:updateAll(dt, maxdt)
  bump.collide()
  camera.lookAt(player:getCenter())
end

function love.draw()
  camera.draw(function(l,t,w,h)
    if drawDebug then bump_debug.draw() end
    Entity:drawAll(l,t,w,h)
  end)
  local msg = instructions:format(tostring(drawDebug), tostring(player.canFly))
  love.graphics.print(msg, 550, 10)

  local statistics = ("fps: %d, mem: %dKB"):format(love.timer.getFPS(), collectgarbage("count"))
  love.graphics.print(statistics, 630, 580 )
end

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
