local class = require 'lib.middleclass'

local Entity = class('Entity')

local gravityAccel  = 500 -- pixels per second^2

function Entity:initialize(world, l,t,w,h)
  self.world, self.l, self.t, self.w, self.h = world, l,t,w,h
  self.vx, self.vy = 0,0
  self.world:add(self, l,t,w,h)
end

function Entity:changeVelocityByGravity(dt)
  self.vy = self.vy + gravityAccel * dt
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
