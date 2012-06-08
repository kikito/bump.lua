-- this file defines how the player moves/reacts to collisions

local GravityEntity = require 'entities.GravityEntity'
local Block         = require 'entities.Block'
local Coin          = require 'entities.Coin'

local Player        = class('Player', GravityEntity)

local runAccel      =  500 -- the player acceleration while going left/right
local breakAccel    = 1000 -- the player acceleration when stopping/turning around
local jumpVelocity  =  400 -- the initial upwards velocity when jumping

local function sign(x)
  return x < 0 and -1 or (x > 0 and 1 or 0)
end

function Player:initialize(x,y)
  GravityEntity.initialize(self,x,y,32,64)
  self.underFeet = {}
  self.canFly = false
  self.coins = 0
end

function Player:shouldCollide(other)
  return instanceOf(Block, other) or instanceOf(Coin, other)
end

function Player:collision(other, dx, dy)
  if instanceOf(Coin, other) then
    other:destroy()
    self.coins = self.coins + 1
  elseif dx~=0 or dy~=0 then -- it can only be a block then
    -- if we hit a wall, floor or ceiling reset the corresponding velocity to 0
    if dx~=0 and sign(self.vx) ~= sign(dx) then self.vx = 0 end
    if dy~=0 and sign(self.vy) ~= sign(dy) then self.vy = 0 end

    -- if we hit a floor, mark it as "under feet"
    if dy < 0 then
      self.underFeet[other] = true
    end

    -- update the player position so that the intersection stops occurring
    self.l, self.t = self.l + dx, self.t + dy
  end
end

function Player:endCollision(block)
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
  else -- break until stopping
    vx = vx - dt * breakAccel * sign(vx)
  end

  if love.keyboard.isDown("up") and (self.canFly or self:isOnGround()) then -- jump/fly
    vy = -jumpVelocity
  end

  self.vx, self.vy = vx, vy

  GravityEntity.update(self, dt, maxdt)
end

function Player:draw()
  love.graphics.setColor(0,255,0)
  love.graphics.rectangle('line', self:getBBox())
end

return Player
