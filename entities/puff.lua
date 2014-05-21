local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Puff = class('Puff', Entity)

local upwardVelocity = 10

function Puff:initialize(world, x, y)
  Entity.initialize(self, world, x, y, math.random(2,10), math.random(2,10))
  self.duration = 0.5 + math.random()
  self.lifeTime = 0
end

function Puff:update(dt)
  self.lifeTime = self.lifeTime + dt

  if self.lifeTime >= self.duration  then
    self:destroy()
  else

    self.t = self.t - upwardVelocity * dt

    local cx,cy = self:getCenter()
    local percent = self.lifeTime / self.duration
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
  local percent = math.min(1, (self.lifeTime / self.duration) * 1.8)

  local r = 255 - math.floor(155*percent)
  local g = 255 - math.floor(155*percent)
  local b = 100

  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

return Puff



