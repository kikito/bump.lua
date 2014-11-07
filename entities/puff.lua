--[[
-- Puff Class
-- Represents a Puff of smoke, created either by explosions or by the Player's propulsion
-- Puffs don't interact with anything (they can be displaced by explosions)
-- They gradually change in shape & color until they disappear (lived & lifeTime are used for that)
-- Since puffs continuously change in size, we keep adding and removing them from the world (this is ok,
-- it's the same thing that bump does internally to move things around)
--]]

local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Puff = class('Puff', Entity)

local defaultVx      = 0
local defaultVy      = -10
local defaultMinSize = 2
local defaultMaxSize = 10

function Puff:initialize(world, x, y, vx, vy, minSize, maxSize)
  vx, vy = vx or defaultVx, vy or defaultVy
  minSize = minSize or defaultMinSize
  maxSize = maxSize or defaultMaxSize

  Entity.initialize(self,
    world,
    x, y,
    math.random(minSize, maxSize),
    math.random(minSize, maxSize)
  )
  self.lifeTime = 0.1 + math.random()
  self.lived = 0
  self.vx, self.vy = vx, vy
end

function Puff:expand(dt)
  local cx,cy = self:getCenter()
  local percent = self.lived / self.lifeTime
  if percent < 0.2 then
    self.w = self.w + (200 + percent) * dt
    self.h = self.h + (200 + percent) * dt
  else
    self.w = self.w + (20 + percent) * dt
  end

  self.l = cx - self.w / 2
  self.t = cy - self.h / 2
end

function Puff:update(dt)
  self.lived = self.lived + dt

  if self.lived >= self.lifeTime  then
    self:destroy()
  else
    self:expand(dt)
    local next_l = self.l + self.vx * dt
    local next_t = self.t + self.vy * dt
    self.world:update(self, next_l, next_t)
    self.l, self.t = next_l, next_t
  end
end

function Puff:getColor()
  local percent = math.min(1, (self.lived / self.lifeTime) * 1.8)

  return 255 - math.floor(155*percent),
         255 - math.floor(155*percent),
         100
end

function Puff:draw()
  local r,g,b = self:getColor()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

return Puff



