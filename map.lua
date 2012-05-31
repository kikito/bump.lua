local map = {}

local width = 4000
local height = 4000

local Entity     = require 'entities.Entity'
local Block      = require 'entities.Block'

local random = math.random

function map.reset()

  Entity:destroyAll()

  -- walls & ceiling
  Block:new(       0,         0, width,        32)
  Block:new(       0,        32,    32, height-64)
  Block:new(width-64,        32,    32, height-64)

  -- tiled floor
  local tilesOnFloor = 40
  for i=0,tilesOnFloor - 1 do
    Block:new(i*width/tilesOnFloor, height-32, width/tilesOnFloor, 32)
  end

  -- random blocks
  for i=1,200 do
    Block:new(random(100, width-200),
              random(100, height-200),
              random(32, 100),
              random(32, 100))
  end

end

map.width = width
map.height = height


return map
