local class  = require 'lib.middleclass'
local Entity = require 'entities.entity'
local Explosion = require 'entities.explosion'

local Grenade = class('Grenade', Entity)

Grenade.static.updateOrder = 1
Grenade.static.radius = 8

local width         = math.sqrt(2 * Grenade.radius * Grenade.radius)
local height        = width
local bounciness    = 0.4 -- How much energy is lost on each bounce. 1 is perfect bounce, 0 is no bounce
local lifeTime      = 5

function Grenade:initialize(world, parent, x, y, vx, vy)
  Entity.initialize(self, world, x, y, width, height)
  self.parent = parent
  self.vx, self.vy  = vx, vy
  self.lived = 0
  self.skipParent = function(other) return other ~= self.parent end
end



function Grenade:collide(dt)
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t, self.skipParent)
  if len == 0 then
    self.l, self.t = future_l, future_t
    world:move(self, future_l, future_t)
  else
    local col, tl, tt, nx, ny, bl, bt
    local visited = {}
    while len > 0 do
      col = cols[1]
      tl,tt,nx,ny,sl,st = col:getBounce()

      self:changeVelocityByCollisionNormal(nx, ny, bounciness)
      if visited[col.other] then return end -- stop iterating when we collide with the same item twice
      visited[col.other] = true

      self.l, self.t = tl, tt
      world:move(self, tl, tt)

      cols, len = world:check(self, sl, st, self.isMyParentFunc)
      if len == 0 then
        self.l, self.t = sl, st
        world:move(self, sl, st)
      end
    end
  end
end

function Grenade:update(dt)
  self.lived = self.lived + dt
  if self.lived >= lifeTime then
    self:destroy()
  else
    self:changeVelocityByGravity(dt)
    self:collide(dt)
  end
end

function Grenade:draw(drawDebug)
  local r,g,b = 255,0,0
  love.graphics.setColor(r,g,b)
  local cx, cy = self:getCenter()
  love.graphics.circle('line', cx, cy, Grenade.radius)

  if drawDebug then
    love.graphics.setColor(255,255,255,200)
    love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
  end
end

function Grenade:destroy()
  Entity.destroy(self)
  Explosion:new(self.world, self:getCenter())
end

return Grenade
