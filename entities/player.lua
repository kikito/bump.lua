--[[
-- Player Class
-- This entity collides "sliding" over walls and floors.
--]]
local class  = require 'lib.middleclass'
local util   = require 'util'

local Entity = require 'entities.entity'

local Player = class('Player', Entity)
Player.static.updateOrder = 1


local runAccel      = 500 -- the player acceleration while going left/right
local brakeAccel    = 2000
local jumpVelocity  = 400 -- the initial upwards velocity when jumping
local width         = 32
local height        = 64

local abs = math.abs

local delta         = 1 -- distance from which the player is allowed to "pop up" over a pass-through platform
                        -- needs to be greater than 0, or filter + player moving with platform + floating precision
                        -- make the player "fall"

function Player:initialize(world, x,y)
  Entity.initialize(self, world, x, y, width, height)

  self.filter = function(other)
    local kind = other.class.name
    if kind == 'Block'
    or (kind == 'Platform' and self.y + self.h - delta <= other.y)
    then
      return 'slide'
    end
  end
end

function Player:changeVelocityByKeys(dt)
  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then
    vx = vx - dt * (vx > 0 and brakeAccel or runAccel)
  elseif love.keyboard.isDown("right") then
    vx = vx + dt * (vx < 0 and brakeAccel or runAccel)
  else
    local brake = dt * (vx < 0 and brakeAccel or -brakeAccel)
    if math.abs(brake) > math.abs(vx) then
      vx = 0
    else
      vx = vx + brake
    end
  end

  if love.keyboard.isDown("up") and self.onGround then -- jump
    vy = -jumpVelocity
  end

  self.vx, self.vy = vx, vy
end

function Player:changeVelocityByBeingOnGround()
  if self.onGround then
    self.vy = math.min(self.vy, 0)
  end
end

function Player:checkIfOnGround(ny)
  if ny < 0 then self.onGround = true end
end

function Player:changePositionIfPlatform(other, actualX, actualY)
  local dx,dy = 0,0
  if other.class.name == 'Platform' then
    dx,dy = -other.dx, -other.dy
  end
  return actualX + dx, actualY + dy
end

function Player:moveColliding(dt)
  self.onGround = false
  local world = self.world

  local goalX = self.x + self.vx * dt
  local goalY = self.y + self.vy * dt

  local actualX, actualY, cols, len = world:check(self, goalX, goalY, self.filter)

  for i=1, len do
    local col = cols[i]
    self:changeVelocityByCollisionNormal(col.normal.x, col.normal.y, bounciness)
    self:checkIfOnGround(col.normal.y)
    actualX, actualY = self:changePositionIfPlatform(col.other, actualX, actualY)
  end

  self.x, self.y = actualX, actualY
  world:update(self, actualX, actualY)
end

function Player:update(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)

  self:moveColliding(dt)
  self:changeVelocityByBeingOnGround(dt)
end

function Player:draw(drawDebug)
  util.drawFilledRectangle(self.x, self.y, self.w, self.h, 0,255,0)

  if drawDebug then
    if self.onGround then
      util.drawFilledRectangle(self.x, self.y + self.h - 4, self.w, 4, 255,255,255)
    end
  end
end

return Player
