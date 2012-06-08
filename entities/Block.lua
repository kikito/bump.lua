-- represents the walls, floors and platforms of the level

local Entity = require 'entities.Entity'

local Block = class('Block', Entity)

function Block:initialize(l,t,w,h)
  Entity.initialize(self, l,t,w,h)
end

function Entity:draw()
  love.graphics.setColor(220,150,150,100)
  love.graphics.rectangle('fill', self:getBBox())
  love.graphics.setColor(220,150,150)
  love.graphics.rectangle('line', self:getBBox())
end

function Block:shouldCollide(other)
  return false
end

return Block
