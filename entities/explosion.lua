--[[
-- Explosion Class
-- Explosions are very special. They are inside the "Entities" folder, but
-- they are not a subclass of Entity, like the rest. This is because when an
-- explosion is created, it does its thing, and it immediatelly disappears!
--
-- "Its thing" is:
-- * Shakes the camera
-- * Destroying Guardians and destructible Blocks
-- * Pushing the Player, Grenades, Puffs and Debris around
-- * Damaging the player
-- * Spawning some Puffs
--
-- Then the explosion ceases to exist.
--
-- As a result, it doesn't have neither `update` or `draw` methods. All the work
-- is done in the constructor.
--
-- For detecting which items can be destroyed / pushed / damaged by a particular
-- explosion, this class uses bump's world:queryRect several times, with different
-- boxes (the box which destroys is smaller than the box that "pushes stuff around")
--
--]]

local class   = require 'lib.middleclass'
local media   = require 'media'
local Puff    = require 'entities.puff'

local Explosion = class('Explosion')

local width         = 150
local height        = width
local pushRadius    = 50
local maxPushSpeed  = 300
local minPuffs      = 15
local maxPuffs      = 30

local clamp = function(x, a, b)
  return math.max(a, math.min(b, x))
end

local damageFilter = function(other)
  local cname = other.class.name
  return cname == 'Player'
      or cname == 'Guardian'
      or (cname == 'Block' and not other.indestructible)
end

local pushFilter = function(other)
  local cname = other.class.name
  return cname == 'Player' or cname == 'Grenade' or cname == 'Debris' or cname == 'Puff'
end

function Explosion:damageItem(other)
  if other.class.name == 'Player' then
    other:takeHit()
  else
    other:destroy()
  end
end

function Explosion:pushItem(other)
  local cx, cy = self.l + self.w / 2, self.t + self.h / 2
  local ox, oy = other:getCenter()
  local dx, dy = ox - cx, oy - cy

  dx, dy = clamp(dx, -maxPushSpeed, maxPushSpeed),
           clamp(dy, -maxPushSpeed, maxPushSpeed)
  if     dx > 0 then dx = maxPushSpeed - dx
  elseif dx < 0 then dx = dx - maxPushSpeed
  end
  if     dy > 0 then dy = maxPushSpeed - dy
  elseif dy < 0 then dy = dy - maxPushSpeed
  end

  other.vx = other.vx + dx
  other.vy = other.vy + dy
end

function Explosion:initialize(world, camera, x, y)
  self.l,self.t,self.w,self.h = x-width/2, y-height/2, width, height

  media.sfx.explosion:play()
  camera:shake()

  local items, len = world:queryRect(self.l,self.t,self.w,self.h, damageFilter)
  for i=1,len do
    self:damageItem(items[i])
  end

  local items, len = world:queryRect(
    self.l - pushRadius,
    self.t - pushRadius,
    self.w + pushRadius + pushRadius,
    self.h + pushRadius + pushRadius,
    pushFilter
  )

  for i=1,len do
    self:pushItem(items[i])
  end

  for i=1, math.random(minPuffs, maxPuffs) do
    Puff:new( world,
              math.random(self.l, self.l + self.w),
              math.random(self.t, self.t + self.h) )
  end

end

return Explosion
