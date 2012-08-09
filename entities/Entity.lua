-- An entity is anything "interesting" for the game: the player, each block...

local entities = {} -- this will hold the list of entities

local Entity = class('Entity')

local entityCounter = 0

local function copy(t)
  local c = {}
  for k,v in pairs(t) do c[k] = v end
  return c
end


function Entity:initialize(l,t,w,h)
  self.l, self.t, self.w, self.h = l,t,w,h
  entities[self] = true
  self.id = entityCounter
  entityCounter = entityCounter + 1
end

function Entity:destroy()
  entities[self] = nil
end


function Entity:update()
end



function Entity:collision(other, dx, dy)
end

function Entity:endCollision(other)
end

function Entity:shouldCollide(other)
  return true
end

function Entity:getBBox()
  return self.l, self.t, self.w, self.h
end

function Entity:getCenter()
  return self.l + self.w/2, self.t + self.h/2
end

function Entity:__tostring()
  return ("%d -> [%d, %d, %d, %d]"):format(self.id, self:getBBox())
end

function Entity.static:destroyAll()
  for entity,_ in pairs(copy(entities)) do
    entity:destroy()
  end
end

return Entity
