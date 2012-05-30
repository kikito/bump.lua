require 'lib.middleclass'
local bump       = require 'lib.bump'
local bump_debug = require 'lib.bump_debug'

local Entity     = require 'entities.Entity'
local Block      = require 'entities.Block'
local Player     = require 'entities.Player'

local maxdt = 0.1          -- max dt; used to clamp max speed
local drawDebug = false

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
  return obj.l, obj.t, obj.w, obj.h
end

function love.load()
  Block:new(  0,   0, 800,  32)
  Block:new(  0, 568, 800,  32)
  Block:new(  0,  32,  32, 536)
  Block:new(768,  32,  32, 536)

  Block:new(368, 536,  32,  32)

  Player:new(100, 100, 32, 32)
end

function love.update(dt)
  dt = math.min(dt, maxdt)
  Entity:updateAll(dt, maxdt)
  bump.check()
end

function love.draw()
  if drawDebug then bump_debug.draw() end
  Entity:drawAll()
end

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    print("collecting garbage")
    collectgarbage("collect")
  end
end
