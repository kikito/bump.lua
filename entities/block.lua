--[[
-- Block Class
-- This is the class that represents the walls, floors and "rocks".
--]]
local class  = require 'lib.middleclass'
local util   = require 'util'
local Entity = require 'entities.entity'

local Block = class('Block', Entity)

function Block:initialize(world, l,t,w,h, indestructible)
  Entity.initialize(self, world, l,t,w,h)
  self.indestructible = indestructible
end

function Block:draw()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, 220, 150, 150)
end

function Block:update(dt)
end

return Block
