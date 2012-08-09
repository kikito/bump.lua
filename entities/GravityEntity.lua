-- this file has common behaviour for entities affected by gravity (The player and Coins)

local bump          = require 'lib.bump'
local Entity        = require 'entities.Entity'

local GravityEntity = class('GravityEntity', Entity)

local gravityAccel  =  500 -- gravity, in pixels per second per second
local minVelocity   =    5

local abs = math.abs

local function pad(x, min, max)
  return x < min and min or (x > max and max or x)
end

local function zero(x, limit)
  return abs(x) < limit and 0 or x
end

local function padVelocity(maxdt, vx, vy)
  local max = bump.getCellSize()/maxdt*0.5
  local min = -max
  return pad(vx, min, max), pad(vy, min, max)
end

function GravityEntity:initialize(x,y,w,h)
  Entity.initialize(self, x,y,w,h)
  self.vx, self.vy = 0,0
  bump.add(self)
end

function GravityEntity:destroy()
  bump.remove(self)
  Entity.destroy(self)
end


function GravityEntity:update(dt, maxdt)
  self.vy = self.vy + gravityAccel * dt
  self.vx, self.vy = padVelocity(maxdt, self.vx, self.vy)
  self.l, self.t   = self.l + self.vx * dt, self.t + self.vy * dt
end

return GravityEntity
