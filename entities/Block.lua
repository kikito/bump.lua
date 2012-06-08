-- represents the walls, floors and platforms of the level

local Entity = require 'entities.Entity'

local Block = class('Block', Entity)

function Block:initialize(l,t,w,h)
  Entity.initialize(self, l,t,w,h)
end

function Entity:draw()
  love.graphics.setColor(220,150,150)
  love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
end

function Block:shouldCollide(other)
  return false
end

return Block
