local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'
local Puff    = require 'entities.puff'

local Explosion = class('Explosion', Entity)
Explosion.static.updateOrder = 0

local width = 75
local height = width

local clamp = function(x, a, b)
  return math.max(a, math.min(b, x))
end

local destroyFilter = function(other)
  return other.class.name == 'Guardian'
      or (other.class.name == 'Block'
          and not other.indestructible)
end

local pushFilter = function(other)
  return other.class.name == 'Player' or other.class.name == 'Grenade'
end

function Explosion:initialize(world, x, y)
  Entity.initialize(self, world, x-width/2, y-height/2, width, height)
end

function Explosion:draw()
  local r,g,b = 255,0,0
  love.graphics.setColor(r,g,b)
  util.drawFilledRectangle(self.l, self.t, width, height, r,g,b)
end

function Explosion:push(other)
  local cx, cy = self:getCenter()
  local ox, oy = other:getCenter()
  local dx, dy = ox - cx, oy - cy

  dx, dy = clamp(dx, -300, 300),
           clamp(dy, -300, 300)
  if     dx > 0 then dx = 300 - dx
  elseif dx < 0 then dx = dx - 300
  end
  if     dy > 0 then dy = 300 - dy
  elseif dy < 0 then dy = dy - 300
  end

  other.vx = other.vx + dx
  other.vy = other.vy + dy
end

function Explosion:update()
  local cols, len = self.world:check(self, nil, nil, destroyFilter)
  for i=1,len do
    cols[i].other:destroy()
  end

  local items, len = self.world:queryRect(self.l - 100, self.t - 100, self.w + 200, self.h + 200, pushFilter)
  for i=1,len do
    self:push(items[i])
  end

  for i=1, math.random(10,20) do
    Puff:new( self.world,
              math.random(self.l, self.l + self.w),
              math.random(self.t, self.t + self.h) )
  end

  -- todo: camera shake?
  self:destroy()
end

function Explosion:destroy()
  Entity.destroy(self)
end

return Explosion
