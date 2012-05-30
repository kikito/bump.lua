local map = {}

local width = 4000
local height = 4000

local Entity     = require 'entities.Entity'
local Block      = require 'entities.Block'
local Player     = require 'entities.Player'

local random = math.random

function map.reset()

  Entity:destroyAll()

  Block:new(       0,         0, width,        32)
  Block:new(       0, height-32, width,        32)
  Block:new(       0,        32,    32, height-64)
  Block:new(width-64,        32,    32, height-64)

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
