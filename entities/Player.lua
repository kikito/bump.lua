-- this file defines how the player moves/reacts to collisions

local class   = require 'lib.middleclass'
local Gravity = require 'mixins.Gravity'
local Entity  = require 'entities.Entity'
local Block   = require 'entities.Block'
local Coin    = require 'entities.Coin'

local Player        = class('Player', Entity):include(Gravity)

local runAccel      =  500 -- the player acceleration while going left/right
local breakAccel    = 1000 -- the player acceleration when stopping/turning around
local jumpVelocity  =  400 -- the initial upwards velocity when jumping
local minVelocity   =    5 -- the velocity at which the player stops moving when no key is pressed

local abs = math.abs

local function sign(x)
  if x < 0 then return -1 end
  if x > 0 then return  1 end
  return 0
end

function Player:initialize(world, x,y)
  Entity.initialize(self, world, x,y,32,64, 255,255,255)
  self.underFeet = {}
  self.canFly = false
  self.coins = 0
  self.vx, self.vy = 0,0
end

function Player:isOnGround()
  return next(self.underFeet)
end

function Player:update(dt)
  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then -- left
    vx = vx - dt * (vx > 0 and breakAccel or runAccel)
  elseif love.keyboard.isDown("right") then -- right
    vx = vx + dt * (vx < 0 and breakAccel or runAccel)
  else -- break until stopping
    vx = vx - dt * breakAccel * sign(vx)
    if abs(vx) < minVelocity then vx = 0 end
  end

  if love.keyboard.isDown("up") and (self.canFly or self:isOnGround()) then -- jump/fly
    vy = -jumpVelocity
  end

  self.vx, self.vy = vx, vy

  self:addGravity(dt)
  self.l = self.l + self.vx *dt

  self.underFeet = {}

  local collisions, len = self.world:move(self, self.l, self.t, self.w, self.h, { filter = getOnlyBlocks })

  for i=1, len do
    local item = collisions[i].item
    if item:isInstanceOf(Coin) then
      item:destroy()
      self.coins = self.coins + 1
    else -- item can only be a block for now
      local dx, dy = collisions[i].dx, collisions[i].dy
      if dx~=0 and sign(self.vx) ~= sign(dx) then self.vx = 0 end
      if dy~=0 and sign(self.vy) ~= sign(dy) then self.vy = 0 end

      -- if we hit a floor, mark it as "under feet"
      if dy < 0 then
        self.underFeet[item] = true
      end

      -- update the player position so that the intersection stops occurring
      self.l, self.t = self.l + dx, self.t + dy
    end
  end

  if len > 0 then self.world:move(self, self.l, self.t, self.w, self.h, { skip_collisions = true }) end
end

function Player:draw()
  self.r,self.g,self.b = 0,255,255
  if self.canFly then self.r,self.g,self.b = 0,255,0 end
  Entity.draw(self)
end

return Player
