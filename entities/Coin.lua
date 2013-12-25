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
  return 1
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

  local options         = { filter = getOnlyBlocks }
  local visited,    i   = {}, 1
  local collisions, len = self.world:move(self, self.l, self.t, self.w, self.h, options)

  while i <= len do
   local col = collisions[i]
   if not visited[col.item] then
     visited[col.item] = true
     local dx, dy    = col.dx, col.dy
     self.l, self.t  = self.l + dx, self.t + dy
     self.vx         = abs(self.vx) * sign(dx) * bounceRate
     self.vy         = abs(self.vy) * sign(dy) * bounceRate
     collisions, len = self.world:move(self, self.l, self.t, self.w, self.h, options)
     i = 0
   end
   i = i + 1
  end
end

return Coin
