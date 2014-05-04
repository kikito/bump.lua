-- this file defines how the player moves/reacts to collisions
local class  = require 'lib.middleclass'
local util   = require 'util'

local Player = class('Player')

local runAccel             = 500 -- the player acceleration while going left/right
local jumpVelocity         = 400 -- the initial upwards velocity when jumping
local width                = 32
local height               = 64
local gravityAcceleration  = 500 -- pixels per second^2

local abs = math.abs

function Player:initialize(world, x,y)
  self.world, self.l, self.t, self.w, self.h = world, x,y, width, height
  world:add(self, x,y,width,height)
  self.canFly       = false
  self.vx, self.vy  = 0,0
end

function Player:changeVelocityByKeys(dt)
  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then
    vx = vx - dt * (vx > 0 and breakAccel or runAccel)
  elseif love.keyboard.isDown("right") then
    vx = vx + dt * (vx < 0 and breakAccel or runAccel)
  else
    vx = 0
  end

  if love.keyboard.isDown("up") and (self.canFly or self.onGround) then -- jump/fly
    vy = -jumpVelocity
  end

  self.vx, self.vy = vx, vy
end

function Player:changeVelocityByGravity(dt)
  if self.onGround then
    self.vy = math.min(self.vy, 0)
  else
    self.vy = self.vy + gravityAcceleration * dt
  end
end

function Player:changeVelocityByCollisionNormal(nx, ny)
  local min, max = math.min, math.max
  if     nx < 0 then self.vx = min(self.vx, 0)
  elseif nx > 0 then self.vx = max(self.vx, 0)
  end

  if     ny < 0 then self.vy = min(self.vy, 0)
  elseif ny > 0 then self.vy = max(self.vy, 0)
  end
end

function Player:checkGroundByCollisionNormal(ny)
  if ny < 0 then self.onGround = true end
end

function Player:collideSliding(col)
  local tl,tt,nx,ny,sl,st = col:getSlide()

  -- Make the player contact the rock
  self:changeVelocityByCollisionNormal(nx, ny)
  self:checkGroundByCollisionNormal(ny)
  self.l, self.t = tl, tt

  -- And then make the player "slide" over the rock
  self.world:move(self, self.l, self.t, self.w, self.h, {skip_collisions = true})
  self.l, self.t = sl, st
end

function Player:collideTouching(col, i)
  local tl, tt, nx, ny = col:getTouch()

  self:changeVelocityByCollisionNormal(nx, ny)
  self:checkGroundByCollisionNormal(ny)
  self.l, self.t = tl, tt
end

function Player:collide(dt)
  self.onGround = false
  local world = self.world

  local cols, len = world:move(self, self.l, self.t)
  if len > 0 then
    self:collideSliding(cols[1])

    cols, len = world:move(self, self.l, self.t)
    for i=1,len do
      self:collideTouching(cols[i], i)
    end
    world:move(self, self.l, self.t, self.w, self.h, {skip_collisions = true})
  end
end

function Player:update(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)

  self.l = self.l + self.vx * dt
  self.t = self.t + self.vy * dt

  self:collide(dt)
end

function Player:draw()
  local r,g,b = 0,255,255
  if self.canFly then r,g,b = 0,255,0 end
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

function Player:getCenter()
  return self.l + self.w / 2, self.t + self.h / 2
end

return Player
