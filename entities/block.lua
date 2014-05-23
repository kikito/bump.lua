-- represents the walls, floors and platforms of the level
local class = require 'lib.middleclass'
local util  = require 'util'
local Entity = require 'entities.entity'
local Debris = require 'entities.debris'

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

function Block:destroy()
  Entity.destroy(self)

  local area = self.w * self.h
  local debrisNumber = math.floor(math.max(30, area / 100))

  for i=1, debrisNumber do
    Debris:new(self.world,
               math.random(self.l, self.l + self.w),
               math.random(self.t, self.t + self.h),
               220, 150, 150
    )
  end

end

return Block
