local bump    = require 'bump'
local object  = require 'objects.object'
local player  = require 'objects.player'
local scenery = require 'objects.scenery'

local p                    -- the player instance
local maxdt = 0.1          -- max dt; used to clamp max speed

function bump.collision(obj1, obj2, dx, dy)
  if obj2.player then
    obj1,obj2,dx,dy = obj2,obj1,-dx,-dy
  end
  player.sceneryCollision(obj1, obj2, dx, dy)
end

function bump.endCollision(obj1, obj2)
  if obj2.player then
    obj1,obj2 = obj2,obj1
  end
  player.endSceneryCollision(obj1, obj2)
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

function love.load()
  scenery.new(  0,   0, 800,  32)
  scenery.new(  0, 568, 800,  32)
  scenery.new(  0,  32,  32, 536)
  scenery.new(768,  32,  32, 536)

  scenery.new(368, 536,  32,  32)

  p = player.new(100, 100, 32, 32)
end

function love.update(dt)
  dt = math.min(dt, maxdt)

  player.update(p, dt, maxdt)

  bump.check()
end

function love.draw()
  object.drawAll()
end

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
end
