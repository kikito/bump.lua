-- represents the walls, floors and platforms of the level

local class  = require 'lib.middleclass'
local Entity = require 'entities.Entity'

local Block = class('Block', Entity)

function Block:initialize(world, l,t,w,h)
  Entity.initialize(self, world, l,t,w,h, 220,150,150)
end

return Block
