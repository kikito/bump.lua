local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'
local Puff    = require 'entities.puff'

local Explosion = class('Explosion', Entity)
Explosion.static.updateOrder = 0

local width  = 150
local height = width
local maxPushSpeed = 300
local minPuffs = 15
local maxPuffs = 30

local clamp = function(x, a, b)
  return math.max(a, math.min(b, x))
end

local destroyFilter = function(other)
  local cname = other.class.name
  return cname == 'Guardian'
      or (cname == 'Block' and not other.indestructible)
end

local pushFilter = function(other)
  local cname = other.class.name
  return cname == 'Player' or cname == 'Grenade' or cname == 'Debris'
end

function Explosion:initialize(world, x, y)
  Entity.initialize(self, world, x-width/2, y-height/2, width, height)
end

function Explosion:draw()
  local r,g,b = 255,0,0
  love.graphics.setColor(r,g,b)
  util.drawFilledRectangle(self.l, self.t, width, height, r,g,b)
end

function Explosion:pushItem(other)
  local cx, cy = self:getCenter()
  local ox, oy = other:getCenter()
  local dx, dy = ox - cx, oy - cy

  dx, dy = clamp(dx, -maxPushSpeed, maxPushSpeed),
           clamp(dy, -maxPushSpeed, maxPushSpeed)
  if     dx > 0 then dx = maxPushSpeed - dx
  elseif dx < 0 then dx = dx - maxPushSpeed
  end
  if     dy > 0 then dy = maxPushSpeed - dy
  elseif dy < 0 then dy = dy - maxPushSpeed
  end

  other.vx = other.vx + dx
  other.vy = other.vy + dy
end

function Explosion:update()
  local cols, len = self.world:check(self, nil, nil, destroyFilter)
  for i=1,len do
    cols[i].other:destroy()
  end

  local cols, len = self.world:check(self, nil, nil, pushFilter)
  for i=1,len do
    self:pushItem(cols[i].other)
  end

  for i=1, math.random(minPuffs, maxPuffs) do
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
