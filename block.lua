-- represents the walls, floors and platforms of the level
local class = require 'lib.middleclass'
local util  = require 'util'

local Block = class('Block')

function Block:initialize(world, l,t,w,h, indestructible)
  self.world, self.l, self.t, self.w, self.h = world, l,t,w,h
  self.indestructible = indestructible
  world:add(self, l,t,w,h)
end

function Block:draw()
  local r,g,b = 220, 150, 150
  if self.indestructible then
    r,g,b = 150,150,220
  end
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

function Block:getUpdateOrder()
  return 1000
end

function Block:update(dt)
end

function Block:destroy()
  self.world:remove(self)
end

return Block
