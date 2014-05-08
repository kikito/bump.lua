local class  = require 'lib.middleclass'
local util   = require 'util'

local Ball = class('Ball')

Ball.static.radius = 8

local gravityAccel  = 500 -- pixels per second^2
local width         = math.sqrt(2 * Ball.radius * Ball.radius)
local height        = width
local bounciness    = 0.4 -- How much energy is lost on each bounce. 1 is perfect bounce, 0 is no bounce
local lifeTime      = 5

function Ball:initialize(world, parent, x, y, vx, vy)
  self.world, self.l, self.t, self.w, self.h = world, x,y, width, height
  self.parent = parent
  self.vx, self.vy  = vx, vy
  self.lived = 0
  world:add(self, x,y,width,height)
end

function Ball:getUpdateOrder()
  return 2
end

function Ball:changeVelocityByGravity(dt)
  self.vy = self.vy + gravityAccel * dt
end

function Ball:changeVelocityByCollisionNormal(nx, ny)
  local min, max = math.min, math.max
  local vx, vy = self.vx, self.vy

  if (nx < 0 and vx > 0) or (nx > 0 and vx < 0) then
    vx = -vx * bounciness
  end

  if (ny < 0 and vy > 0) or (ny > 0 and vy < 0) then
    vy = -vy * bounciness
  end

  self.vx, self.vy = vx, vy
end

function Ball:collideBouncing(col)
  local tl,tt,nx,ny,bl,bt = col:getBounce()

  -- Make the ball contact the surface
  self:changeVelocityByCollisionNormal(nx, ny)
  self.l, self.t = tl, tt

  -- And then make the ball "bounce"
  self.world:teleport(self, self.l, self.t, self.w, self.h)
  self.l, self.t = bl, bt
end

function Ball:collideTouching(col)
  local tl, tt, nx, ny = col:getTouch()

  self:changeVelocityByCollisionNormal(nx, ny)
  self.l, self.t = tl, tt
end

function Ball:collide(dt)
  local world = self.world

  local cols, len = world:move(self, self.l, self.t, {self.parent})
  if len > 0 then
    self:collideBouncing(cols[1])

    cols, len = world:move(self, self.l, self.t, {self.parent})
    for i=1,len do
      self:collideTouching(cols[i], i)
    end
    world:teleport(self, self.l, self.t, self.w, self.h)
  end
end

function Ball:update(dt)
  self.lived = self.lived + dt
  if self.lived >= lifeTime then
    self:destroy()
  else
    self:changeVelocityByGravity(dt)

    self.l = self.l + self.vx * dt
    self.t = self.t + self.vy * dt

    self:collide(dt)
  end
end

function Ball:draw(drawDebug)
  local r,g,b = 255,0,0
  love.graphics.setColor(r,g,b)
  local cx, cy = self:getCenter()
  love.graphics.circle('line', cx, cy, Ball.radius)

  if drawDebug then
    love.graphics.setColor(255,255,255,200)
    love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
  end
end

function Ball:getCenter()
  return self.l + self.w / 2,
         self.t + self.h / 2
end

function Ball:destroy()
  self.world:remove(self)
end

return Ball
