-- This file represents coins. Coins can bounce around, and be taken by the player
local class   = require 'lib.middleclass'
local Gravity = require 'mixins.Gravity'
local Entity  = require 'entities.Entity'
local Block   = require 'entities.Block'

local Coin    = class('Coin', Entity):include(Gravity)

local bounceRate = 0.5
local abs = math.abs

local function sign(x)
  if x < 0 then return -1 end
  if x > 0 then return  1 end
  return 0
end

local function getOnlyBlocks(x) return not x:isInstanceOf(Block) end

function Coin:initialize(world, x,y)
  Entity.initialize(self, world, x,y,16,16, 255, 255, 0)
  self.vx = math.random(-50,50)
  self.vy = math.random(-50,50)
end

function Coin:update(dt)
  self:addGravity(dt)
  self.l = self.l + self.vx *dt

  local collisions, len = self.world:move(self, self.l, self.t, self.w, self.h, { filter = getOnlyBlocks })

  for i=1, len do
    local dx, dy = collisions[i].dx, collisions[i].dy
    if dx ~= 0 then
      self.l  = self.l + dx
      self.vx = abs(self.vx) * sign(dx) * bounceRate
    end
    if dy ~= 0 then
      self.t  = self.t + dy
      self.vy = abs(self.vy) * sign(dy) * bounceRate
    end
  end

  if len > 0 then self.world:move(self, self.l, self.t, self.w, self.h, { skip_collisions = true }) end
end

return Coin
