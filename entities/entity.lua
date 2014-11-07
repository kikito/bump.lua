--[[
-- Entity Class
-- This is the base class of all the "Objects" in the Demo (except Explosions)
-- It has some basic common methods:
-- * The constructor adds the object to the world, and the destructor removes it
-- * Some common velocity-related methods
-- * getCenter returns the center of the rectangle
-- * Finally, getUpdateOrder is used to sort the objects out before calling :update() on them
--]]

local class = require 'lib.middleclass'

local Entity = class('Entity')

local gravityAccel  = 500 -- pixels per second^2

function Entity:initialize(world, l,t,w,h)
  self.world, self.l, self.t, self.w, self.h = world, l,t,w,h
  self.vx, self.vy = 0,0
  self.world:add(self, l,t,w,h)
  self.created_at = love.timer.getTime()
end

function Entity:changeVelocityByGravity(dt)
  self.vy = self.vy + gravityAccel * dt
end

function Entity:changeVelocityByCollisionNormal(nx, ny, bounciness)
  bounciness = bounciness or 0
  local vx, vy = self.vx, self.vy

  if (nx < 0 and vx > 0) or (nx > 0 and vx < 0) then
    vx = -vx * bounciness
  end

  if (ny < 0 and vy > 0) or (ny > 0 and vy < 0) then
    vy = -vy * bounciness
  end

  self.vx, self.vy = vx, vy
end

function Entity:getCenter()
  return self.l + self.w / 2,
         self.t + self.h / 2
end

function Entity:destroy()
  self.world:remove(self)
end

function Entity:getUpdateOrder()
  return self.class.updateOrder or 10000
end

return Entity
