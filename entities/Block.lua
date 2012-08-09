-- represents the walls, floors and platforms of the level

local bump   = require 'lib.bump'
local Entity = require 'entities.Entity'

local Block = class('Block', Entity)

function Block:initialize(l,t,w,h)
  Entity.initialize(self, l,t,w,h)
  bump.addStatic(self)
end

function Block:destroy()
  bump.remove(self)
  Entity.destroy(self)
end

function Block:draw()
  love.graphics.setColor(220,150,150,100)
  love.graphics.rectangle('fill', self:getBBox())
  love.graphics.setColor(220,150,150)
  love.graphics.rectangle('line', self:getBBox())
end

function Block:shouldCollide(other)
  return false
end

return Block
