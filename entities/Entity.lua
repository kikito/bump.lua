-- An entity is anything "interesting" for the game: the player, each block...

local bump = require 'lib.bump'

local entities = {} -- this will hold the list of entities

local Entity = class('Entity')

local function copy(t)
  local c = {}
  for k,v in pairs(t) do c[k] = v end
  return c
end


function Entity:initialize(l,t,w,h)
  self.l, self.t, self.w, self.h = l,t,w,h
  entities[self] = true
  bump.add(self)
end

function Entity:destroy()
  bump.remove(self)
  entities[self] = nil
end

function Entity:draw()
  love.graphics.setColor(255,255,255)
  love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
end

function Entity:update()
end



function Entity:collision(other, dx, dy)
end

function Entity:endCollision(other)
end

function Entity:getBBox()
  return self.l, self.t, self.w, self.h
end

function Entity:getCenter()
  return self.l + self.w/2, self.t + self.h/2
end

function Entity.static:drawAll()
  for entity,_ in pairs(entities) do
    entity:draw()
  end
end

function Entity.static:updateAll(dt, maxdt)
  for entity,_ in pairs(entities) do
    entity:update(dt, maxdt)
  end
end

function Entity.static:destroyAll()
  for entity,_ in pairs(copy(entities)) do
    entity:destroy()
  end
end

return Entity
