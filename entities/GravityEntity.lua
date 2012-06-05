local bump          = require 'lib.bump'
local Entity        = require 'entities.Entity'

local GravityEntity = class('GravityEntity', Entity)

local gravityAccel  =  500 -- gravity, in pixels per second per second

local function pad(x, min, max)
  return x < min and min or (x > max and max or x)
end

local function padVelocity(maxdt, vx, vy)
  local max = bump.getCellSize()/maxdt
  local min = -max
  return pad(vx, min, max), pad(vy, min, max)
end

function GravityEntity:initialize(x,y,w,h)
  Entity.initialize(self, x,y,w,h)
  self.vx, self.vy = 0,0
end


function GravityEntity:update(dt, maxdt)
  self.vy = self.vy + gravityAccel * dt
  self.vx, self.vy = padVelocity(maxdt, self.vx, self.vy)
  self.l, self.t   = self.l + self.vx * dt, self.t + self.vy * dt
end

return GravityEntity
