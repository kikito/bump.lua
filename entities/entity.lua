--[[
-- Entity Class
-- It has some basic common methods:
-- * The constructor adds the object to the world, and the destructor removes it
-- * Some common velocity-related methods
-- * getCenter returns the center of the rectangle
-- * Finally, getUpdateOrder is used to sort the objects out before calling :update() on them
--]]

local class = require 'lib.middleclass'

local Entity = class('Entity')

function Entity:initialize(world, x,y,w,h)
  self.world, self.x, self.y, self.w, self.h = world, x,y,w,h
  self.vx, self.vy = 0,0
  self.world:add(self, x,y,w,h)
  self.created_at = love.timer.getTime()
end

function Entity:getCenter()
  return self.x + self.w / 2,
         self.y + self.h / 2
end

function Entity:destroy()
  self.world:remove(self)
end

function Entity:getUpdateOrder()
  return self.class.updateOrder or 10000
end

return Entity
