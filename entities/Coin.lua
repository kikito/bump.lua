-- This file represents coins. Coins can bounce around, and be taken by the player

local GravityEntity = require 'entities.GravityEntity'
local Block         = require 'entities.Block'

local Coin          = class('Coin', GravityEntity)

local bounceRate = 0.5
local abs = math.abs

local function sign(x)
  return x < 0 and -1 or (x > 0 and 1 or 0)
end

function Coin:initialize(x,y,vx,vy)
  GravityEntity.initialize(self,x,y,16,16)
  self.vx, self.vy = vx or 0, vy or 0
end

function Coin:shouldCollide(other)
  return instanceOf(Block, other)
end

function Coin:collision(other, dx, dy)
  if dx~=0 then
    self.l = self.l + dx
    self.vx = abs(self.vx) * sign(dx) * bounceRate
  end
  if dy~=0 then
    self.t = self.t + dy
    self.vy = abs(self.vy) * sign(dy) * bounceRate
  end
end

function Coin:draw()
  love.graphics.setColor(255,255,0,100)
  love.graphics.rectangle('fill', self:getBBox())
  love.graphics.setColor(255,255,0)
  love.graphics.rectangle('line', self:getBBox())
end

return Coin
