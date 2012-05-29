-- this file defines how the player moves/reacts to collisions

local bump          = require 'lib.bump'
local Entity        = require 'entities.Entity'

local Player        = class('Player', Entity)

local runAccel      =  500 -- the player acceleration while going left/right
local breakAccel    = 1000 -- the player acceleration when stopping/turning around
local jumpVelocity  =  400 -- the initial upwards velocity when jumping
local gravityAccel  =  500 -- gravity, in pixels per second per second

function Player:initialize(x,y)
  Entity.initialize(self,x,y,32,64)
  self.underFeet = {}
  self.vx, self.vy = 0,0
end

function Player:blockCollision(block, dx, dy)
  -- if we hit a wall, floor or ceiling reset the corresponding velocity to 0
  if dx~=0 then self.vx = 0 end
  if dy~=0 then self.vy = 0 end

  -- if we hit a floor, mark it as "under feet"
  if dy < 0 then
    self.underFeet[block] = true
  end

  -- update the player position so that the intersection stops occurring
  self.l, self.t = self.l + dx, self.t + dy
end

function Player:endBlockCollision(block)
  self.underFeet[block] = nil
end

function Player:isOnGround()
  for _,_ in pairs(self.underFeet) do
    return true
  end
  return false
end

function Player:update(dt, maxdt)
  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then -- left
    vx = vx - dt * (vx > 0 and breakAccel or runAccel)
  elseif love.keyboard.isDown("right") then -- right
    vx = vx + dt * (vx < 0 and breakAccel or runAccel)
  elseif vx < -5 then -- break to the right
    vx = vx + dt * breakAccel
  elseif vx >  5 then -- break to the left
    vx = vx - dt * breakAccel
  else
    vx = 0
  end

  vy = vy + gravityAccel * dt
  if love.keyboard.isDown("up") and self:isOnGround() then -- jump
    vy = -jumpVelocity
  end

  self.vx, self.vy = bump.padVelocity(maxdt, vx, vy)
  self.l, self.t   = self.l + self.vx * dt, self.t + self.vy * dt
end

return Player
