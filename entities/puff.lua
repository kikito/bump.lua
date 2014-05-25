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

function Puff:update(dt)
  self.lived = self.lived + dt

  if self.lived >= self.lifeTime  then
    self:destroy()
  else

    self.l = self.l + self.vx * dt
    self.t = self.t + self.vy * dt

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

    self.world:remove(self)
    self.world:add(self, self.l, self.t, self.w, self.h)
  end
end

function Puff:draw()
  local percent = math.min(1, (self.lived / self.lifeTime) * 1.8)

  local r = 255 - math.floor(155*percent)
  local g = 255 - math.floor(155*percent)
  local b = 100

  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

return Puff



