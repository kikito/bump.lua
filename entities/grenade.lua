--[[
-- Grenade Class
-- Grenades are tiny balls (squares) that bounce and roll around until they explode.
-- They don't directly destroy anything - when they die, they spawn an instance of Explosion, which
-- is in charge of destroying & pushing things around. The variables that regulate how long does it
-- take to explode are liveTime and self.lived
--
-- Grenades need to have a camera parameter on their constructor because the Explosion they spawn
-- needs to know it (to make the camera shake)
--
-- Grenades bounce using collision:getBounce(). Two points of interest:
-- * Grenades won't collide with the Guardian that created them (their "parent") at the beginning -
--   they need to "exit their parent" first. That's what the self.insideParent attribute controls.
-- * Grenades explode instantly if they touch the Player. They will bounce over Blocks and Guardians
--   (except their parent, until they exit it for the first time)
-- ]]

local class      = require 'lib.middleclass'
local Entity     = require 'entities.entity'
local Explosion  = require 'entities.explosion'
local media      = require 'media'

local Grenade = class('Grenade', Entity)

Grenade.static.updateOrder = 2
Grenade.static.radius = 8

local width             = math.sqrt(2 * Grenade.radius * Grenade.radius)
local height            = width
local bounciness        = 0.4 -- How much energy is lost on each bounce. 1 is perfect bounce, 0 is no bounce
local lifeTime          = 4   -- Lifetime in seconds
local bounceSoundSpeed  = 30  -- How fast must a grenade go to make bouncing noises

local grenadeFilter = function(other)
  local cname = other.class.name
  return cname == 'Block' or cname == 'Guardian' or cname == 'Player'
end

function Grenade:initialize(world, parent, camera, x, y, vx, vy)
  Entity.initialize(self, world, x, y, width, height)
  self.parent = parent
  self.camera = camera
  self.vx, self.vy  = vx, vy
  self.lived = 0
  self.insideParent = true
end

function Grenade:getBounceSpeed(nx, ny)
  if nx == 0 then return math.abs(self.vy) else return math.abs(self.vx) end
end

function Grenade:emitCollisionSound(nx, ny)
  local speed = self:getBounceSpeed(nx, ny)
  if speed >= bounceSoundSpeed then
    media.sfx.grenade_wall_hit:play()
  end
end

function Grenade:moveColliding(dt)
  local world = self.world
  local isTouchingParent = false

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t, grenadeFilter)
  local col = cols[1]
  if col and col.other == self.parent and self.insideParent then
    isTouchingParent = true
    table.remove(cols, 1)
    len = len - 1
  end
  if len == 0 then
    self:move(future_l, future_t)
  else
    local tl, tt, nx, ny, bl, bt
    local visited = {}

    while len > 0 do
      col = cols[1]
      if col.other.class.name == 'Player' then
        self:destroy()
        return
      end
      tl,tt,nx,ny,sl,st = col:getBounce()

      self:changeVelocityByCollisionNormal(nx, ny, bounciness)
      self:emitCollisionSound(nx, ny)

      self:move(tl, tt)

      if visited[col.other] then return end -- stop iterating when we collide with the same item twice
      visited[col.other] = true

      cols, len = world:check(self, sl, st, grenadeFilter)
      if len == 0 then
        self:move(sl, st)
      end
    end
  end

  if not isTouchingParent then self.insideParent = false end
end

function Grenade:update(dt)
  self.lived = self.lived + dt
  if self.lived >= lifeTime then
    self:destroy()
  else
    self:changeVelocityByGravity(dt)
    self:moveColliding(dt)
  end
end

function Grenade:draw(drawDebug)

  local r,g,b = 255,0,0
  love.graphics.setColor(r,g,b)

  local cx, cy = self:getCenter()
  love.graphics.circle('line', cx, cy, Grenade.radius)

  local percent = self.lived / lifeTime

  g = math.floor(255 * percent)
  b = g
  love.graphics.setColor(r,g,b)

  love.graphics.circle('fill', cx, cy, Grenade.radius)

  if drawDebug then
    love.graphics.setColor(255,255,255,200)
    love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
  end
end

function Grenade:destroy()
  Entity.destroy(self)
  Explosion:new(self.world, self.camera, self:getCenter())
end

return Grenade
