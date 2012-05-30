require 'lib.middleclass'
local bump       = require 'lib.bump'
local bump_debug = require 'lib.bump_debug'
local camera     = require 'lib.camera'

local map        = require 'map'
local Entity     = require 'entities.Entity'
local Player     = require 'entities.Player'

local maxdt       = 0.1          -- max dt; used to clamp max speed
local drawDebug   = false
local player

bump.initialize(64)

function bump.collision(obj1, obj2, dx, dy)
  obj1:collision(obj2,  dx,  dy)
  obj2:collision(obj1, -dx, -dy)
end

function bump.endCollision(obj1, obj2)
  obj1:endCollision(obj2)
  obj2:endCollision(obj1)
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
  bump.check()
  camera.lookAt(player:getCenter())
end

function love.draw()
  camera.draw(function()
    if drawDebug then bump_debug.draw() end
    Entity:drawAll()
  end)
end

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    print("collecting garbage")
    collectgarbage("collect")
  end
  if k=="return" then
    reset()
  end
end
