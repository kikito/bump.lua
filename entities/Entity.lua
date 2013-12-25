-- An entity is anything "interesting" for the game: the player, each block...

local class = require 'lib.middleclass'
local bump  = require 'lib.bump'

local entities = {} -- this will hold the list of entities

local Entity = class('Entity')

function Entity:initialize(world, l,t,w,h, r,g,b)
  self.world                     = world
  self.l, self.t, self.w, self.h = l,t,w,h
  self.r, self.g, self.b         = r,g,b

  world:add(self, l,t,w,h, {skip_collisions = true})
  entities[self]  = true
end

function Entity:destroy()
  entities[self] = nil
  self.world:remove(self)
end

function Entity:update(dt)
end

function Entity:draw()
  love.graphics.setColor(self.r, self.g, self.b, 100)
  love.graphics.rectangle('fill', self:getBBox())
  love.graphics.setColor(self.r, self.g, self.b)
  love.graphics.rectangle('line', self:getBBox())
end

function Entity:getBBox()
  return self.l, self.t, self.w, self.h
end

function Entity:getCenter()
  return self.l + self.w/2, self.t + self.h/2
end

function Entity:__tostring()
  return ("[%d, %d, %d, %d]"):format(self:getBBox())
end

function Entity.static:destroyAll()
  for entity,_ in pairs(entities) do
    entity:destroy()
  end
end

return Entity
