-- this file defines how the player moves/reacts to collisions
local class  = require 'lib.middleclass'
local util   = require 'util'

local Player = class('Player')

local runAccel      = 500 -- the player acceleration while going left/right
local brakeAccel    = 2000
local jumpVelocity  = 400 -- the initial upwards velocity when jumping
local gravityAccel  = 500 -- pixels per second^2
local width         = 32
local height        = 64

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

  if love.keyboard.isDown("up") and (self.canFly or self.onGround) then -- jump/fly
    vy = -jumpVelocity
  end

  self.vx, self.vy = vx, vy
end

function Player:changeVelocityByGravity(dt)
  if self.onGround then
    self.vy = math.min(self.vy, 0)
  else
    self.vy = self.vy + gravityAccel * dt
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

function Player:checkIfOnGround(ny)
  if ny < 0 then self.onGround = true end
end

function Player:collide(dt)
  self.onGround = false
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t)
  if len == 0 then
    self.l, self.t = future_l, future_t
    world:move(self, future_l, future_t)
  else
    local col, tl, tt, nx, ny, sl, st
    while len > 0 do
      col = cols[1]
      tl,tt,nx,ny,sl,st = col:getSlide()

      self:changeVelocityByCollisionNormal(nx, ny)
      self:checkIfOnGround(ny)

      self.l, self.t = tl, tt
      world:move(self, tl, tt)

      cols, len = world:check(self, sl, st)
      if len == 0 then
        self.l, self.t = sl, st
        world:move(self, sl, st)
      end
    end
  end
end

function Player:getUpdateOrder()
  return 1
end

function Player:update(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)

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
