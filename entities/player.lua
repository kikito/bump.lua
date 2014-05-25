-- this file defines how the player moves/reacts to collisions
local class  = require 'lib.middleclass'
local util   = require 'util'
local media  = require 'media'

local Entity = require 'entities.entity'
local Debris = require 'entities.debris'

local Player = class('Player', Entity)
Player.static.updateOrder = 1


local deadDuration  = 3   -- seconds until res-pawn
local runAccel      = 500 -- the player acceleration while going left/right
local brakeAccel    = 2000
local jumpVelocity  = 400 -- the initial upwards velocity when jumping
local width         = 32
local height        = 64

local abs = math.abs

local playerFilter = function(other)
  local cname = other.class.name
  return cname == 'Guardian' or cname == 'Block'
end

function Player:initialize(map, world, x,y)
  Entity.initialize(self, world, x, y, width, height)
  self.canFly = false
  self.health = 1
  self.deadCounter = 0
  self.map = map
end

function Player:changeVelocityByKeys(dt)
  if self.isDead then return end

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
    if self.onGround then
      media.sfx.player_jump:play()
    end
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

function Player:collide(dt)
  self.onGround = false
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t, playerFilter)
  if len == 0 then
    self.l, self.t = future_l, future_t
    world:move(self, future_l, future_t)
  else
    local col, tl, tt, nx, ny, sl, st
    local visited = {}
    while len > 0 do
      col = cols[1]
      tl,tt,nx,ny,sl,st = col:getSlide()

      self:changeVelocityByCollisionNormal(nx, ny)
      self:checkIfOnGround(ny)

      self.l, self.t = tl, tt
      world:move(self, tl, tt)

      if visited[col.other] then return end -- prevent infinite loops
      visited[col.other] = true

      cols, len = world:check(self, sl, st, playerFilter)
      if len == 0 then
        self.l, self.t = sl, st
        world:move(self, sl, st)
      end
    end
  end
end

function Player:updateHealth(dt)
  if self.isDead then
    self.deadCounter = self.deadCounter + dt
    if self.deadCounter >= deadDuration then
      self.map:reset()
    end
  else
    self.health = math.min(1, self.health + dt / 10)
  end
end

function Player:update(dt)
  self:updateHealth(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)

  self:collide(dt)
  self:changeVelocityByBeingOnGround(dt)
end

function Player:takeHit()
  self.health = self.health - 0.5
  if self.health <= 0 then
    self:die()
  end
end

function Player:die()
  media.music:stop()

  self.isDead = true
  self.health = 0
  for i=1,20 do
    Debris:new(self.world,
               math.random(self.l, self.l + self.w),
               math.random(self.t, self.t + self.h),
               255,0,0)
  end
  local cx,cy = self:getCenter()
  self.w = math.random(8, 10)
  self.h = math.random(8, 10)
  self.l = cx + self.w / 2
  self.t = cy + self.h / 2
  self.vx = math.random(-100, 100)
  self.vy = math.random(-100, 100)
  self.world:remove(self)
  self.world:add(self, self.l, self.t, self.w, self.h)
end

function Player:getColor()
  local g = math.floor(255 * self.health)
  local r = 255 - g
  local b = 0
  return r,g,b
end

function Player:draw(drawDebug)
  local r,g,b = self:getColor()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
  if drawDebug then
    if self.onGround then
      util.drawFilledRectangle(self.l, self.t + self.h * 2/3, self.w, self.h/3, 255,255,255)
    end
  end
end

return Player
