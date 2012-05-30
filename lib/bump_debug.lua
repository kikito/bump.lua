
local bump = require 'lib.bump'


local bump_debug = {}


-- transform grid coords into world coords
local function _getCellBoundingBox(x,y)
  return (x - 1)*bump._cellSize, (y-1)*bump._cellSize, bump._cellSize, bump._cellSize
end

function bump_debug.draw()
  local intensity
  for y,row in pairs(bump._cells) do
    for x,cell in pairs(row) do
      intensity = cell.itemCount * 50 + 30
      love.graphics.setColor(intensity, intensity, intensity)
      love.graphics.rectangle('line', _getCellBoundingBox(x,y))
    end
  end
end

return bump_debug
