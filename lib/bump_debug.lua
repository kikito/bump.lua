
local bump = require 'lib.bump'

local bump_debug = {}

-- transform grid coords into world coords
local function _getCellBoundingBox(x,y)
  local cellSize = bump.getCellSize()
  return (x - 1)*cellSize, (y-1)*cellSize, cellSize, cellSize
end

local function _drawCell(cell, gx, gy)
  local l,t,w,h   = _getCellBoundingBox(gx, gy)
  local intensity = cell.itemCount * 40 + 30
  love.graphics.setColor(intensity, intensity, intensity)
  love.graphics.print(cell.itemCount, l+12, t+12)
  love.graphics.rectangle('line', l,t,w,h)
end

function bump_debug.draw(l,t,w,h)
  bump.eachCell(_drawCell, l,t,w,h)
end

return bump_debug
