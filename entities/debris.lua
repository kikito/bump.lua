--[[
-- Debris Class
-- Debris are the little pieces that fall when a Block, a Guardian or the Player are destroyed by an Explosion
-- These little pieces bounce around (using collision:getBounce()) until their internal timer (self.lived)
-- expires. Then they simply disappear.
--]]

local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Debris = class('Debris', Entity)

local minSize = 5
local maxSize = 10
local minVel = -100
local maxVel = -1 * minVel
local bounciness = 0.1

function Debris:initialize(world, x, y, r,g,b)
  Entity.initialize(self,
    world,
    x, y,
    math.random(minSize, maxSize),
    math.random(minSize, maxSize)
  )
  self.r, self.g, self.b = r,g,b

  self.lifeTime = 1 + 3 * math.random()
  self.lived = 0
  self.vx = math.random(minVel, maxVel)
  self.vy = math.random(minVel, maxVel)
end

function Debris:filter(other)
  local kind = other.class.name
  if kind == 'Block' or kind == 'Guardian' then return "bounce" end
end

function Debris:moveColliding(dt)
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local next_l, next_t, cols, len = world:move(self, future_l, future_t, self.filter)

  for i=1, len do
    local col = cols[i]
    self:changeVelocityByCollisionNormal(col.normal.x, col.normal.y, bounciness)
  end

  self.l, self.t = next_l, next_t
end

function Debris:update(dt)
  self.lived = self.lived + dt

  if self.lived >= self.lifeTime  then
    self:destroy()
  else
    self:changeVelocityByGravity(dt)
    self:moveColliding(dt)
  end
end

function Debris:draw()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, self.r, self.g, self.b)
end

return Debris
