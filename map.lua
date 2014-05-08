local class       = require 'lib.middleclass'
local bump        = require 'lib.bump'
local bump_debug  = require 'lib.bump_debug'

local Player      = require 'player'
local Block       = require 'block'
local Guardian    = require 'guardian'

local random = math.random

local sortByUpdateOrder = function(a,b)
  return a:getUpdateOrder() < b:getUpdateOrder()
end

local Map = class('Map')

function Map:initialize(width, height)
  self.width  = width
  self.height = height

  self.world  = bump.newWorld()
  self.player = Player:new(self.world, 60, 60)

  -- walls & ceiling
  Block:new(self.world,        0,         0, width,        32)
  Block:new(self.world,        0,        32,    32, height-64)
  Block:new(self.world, width-32,        32,    32, height-64)

  -- tiled floor
  local tilesOnFloor = 40
  for i=0,tilesOnFloor - 1 do
    Block:new(self.world, i*width/tilesOnFloor, height-32, width/tilesOnFloor, 32)
  end

  -- random blocks
  for i=1,500 do
    Block:new( self.world,
               random(100, width-200),
               random(100, height-150),
               random(32, 100),
               random(32, 100) )
  end

  for i=1,5 do
    Guardian:new( self.world,
                  self.player,
                  random(100, width-200),
                  random(100, height-150) )
  end
end

function Map:getDimensions()
  return self.width, self.height
end

function Map:update(dt, l,t,w,h)
  local visibleThings, len = self.world:queryBox(l,t,w,h)

  table.sort(visibleThings, sortByUpdateOrder)

  for i=1, len do
    visibleThings[i]:update(dt)
  end
end

function Map:draw(drawDebug, l,t,w,h)
  if drawDebug then bump_debug.draw(self.world, l,t,w,h) end

  local visibleThings, len = self.world:queryBox(l,t,w,h)

  for i=1, len do
    visibleThings[i]:draw(drawDebug)
  end
end


return Map
