local class = require 'lib.middleclass'
local util  = require 'util'

local Explosion = class('Explosion')

local width = 75
local height = width

local shouldBeDestroyedByBombs = function(other)
  return other.class.name == 'Guardian'
      or (other.class.name == 'Block'
          and not other.indestructible)
end

local explosionFilter = function(other)
  return not shouldBeDestroyedByBombs(other)
end

function Explosion:initialize(world, x, y)
  self.world, self.l, self.t = world, x-width/2, y-width/2
  world:add(self, self.l, self.t, width,height)
end

function Explosion:getUpdateOrder()
  return 0
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
  -- todo: ignore player, indestructible blocks, grenades
  -- todo: spawn puffs
  -- todo: camera shake?
  -- todo: push stuff out
  self:destroy()
end

function Explosion:destroy()
  self.world:remove(self)
end

return Explosion
