-- represents the walls, floors and platforms of the level
local class = require 'lib.middleclass'
local util  = require 'util'
local Entity = require 'entities.entity'

local Block = class('Block', Entity)

function Block:initialize(world, l,t,w,h, indestructible)
  Entity.initialize(self, world, l,t,w,h)
  self.indestructible = indestructible
end

function Block:draw()
  local r,g,b = 220, 150, 150
  if self.indestructible then
    r,g,b = 150,150,220
  end
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

function Block:update(dt)
end

return Block
