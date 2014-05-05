local class  = require 'lib.middleclass'
local Block  = require 'block'
local Turret = require 'turret'

local random = math.random

local Map = class('Map')

Map.static.WIDTH  = 4000
Map.static.HEIGHT = 2000

function Map:initialize(world, player)
  self.world  = world
  self.player = player
  self.width  = Map.WIDTH
  self.height = Map.HEIGHT

  local width, height = self.width, self.height

  -- walls & ceiling
  Block:new(world,        0,         0, width,        32)
  Block:new(world,        0,        32,    32, height-64)
  Block:new(world, width-32,        32,    32, height-64)

  -- tiled floor
  local tilesOnFloor = 40
  for i=0,tilesOnFloor - 1 do
    Block:new(world, i*width/tilesOnFloor, height-32, width/tilesOnFloor, 32)
  end

  -- random blocks
  for i=1,100 do
    Block:new( world,
               random(100, width-200),
               random(100, height-150),
               random(32, 100),
               random(32, 100) )
  end

  for i=1,5 do
    Turret:new( world,
                player,
                random(100, width-200),
                random(100, height-150) )
  end
end

return Map
