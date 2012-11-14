local bump = require 'lib.bump'

local bump_debug = {}

local function _getCellBoundingBox(x,y)
  local cellSize = bump.getCellSize()
  return (x - 1)*cellSize, (y-1)*cellSize, cellSize, cellSize
end

local function _countItems(cell)
  local count = 0
  for _,_ in pairs(cell.items) do count = count + 1 end
  return count
end

local function _drawCell(cell)
  local l,t,w,h   = _getCellBoundingBox(cell.gx, cell.gy)
  local count = _countItems(cell)
  local intensity = count * 40 + 30
  love.graphics.setColor(intensity, intensity, intensity)
  love.graphics.print(count, l+12, t+12)
  love.graphics.rectangle('line', l,t,w,h)
end

function bump_debug.draw(l,t,w,h)
  bump.cells.each(_drawCell, bump.geom.gridBox(bump.getCellSize(), l,t,w,h))
end

return bump_debug
