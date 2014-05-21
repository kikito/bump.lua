local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Explosion = class('Explosion', Entity)
Explosion.static.updateOrder = 0

local width = 75
local height = width

local explosionFilter = function(other)
  return other.class.name == 'Guardian'
      or (other.class.name == 'Block'
          and not other.indestructible)
end

function Explosion:initialize(world, x, y)
  Entity.initialize(self, world, x-width/2, y-height/2, width, height)
end

function Explosion:draw()
  local r,g,b = 255,255,0
  love.graphics.setColor(r,g,b)
  util.drawFilledRectangle(self.l, self.t, width, height, r,g,b)
end

function Explosion:update()
  local cols, len = self.world:check(self, nil, nil, explosionFilter)
  for i=1,len do
    cols[i].other:destroy()
  end
  -- todo: spawn puffs
  -- todo: camera shake?
  -- todo: push stuff out
  self:destroy()
end

function Explosion:destroy()
  Entity.destroy(self)
end

return Explosion
