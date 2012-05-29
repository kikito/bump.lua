-- represents the walls, floors and platforms of the level

local Entity = require 'entities.Entity'

local Block = class('Block', Entity)

function Block:initialize(l,t,w,h)
  Entity.initialize(self, l,t,w,h)
end

return Block
