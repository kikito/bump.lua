
local bump = require 'bump'

local bump_debug = {}

function bump_debug.draw(world)
  for cy, row in pairs(world.rows) do
    for cx, cell in pairs(row) do
      local l,t,w,h = world:toWorldBox(cell.x, cell.y, 1, 1)
      local intensity = cell.itemCount * 40 + 30
      love.graphics.setColor(intensity, intensity, intensity)
      love.graphics.print(cell.itemCount, l+12, t+12)
      love.graphics.rectangle('line', l,t,w,h)
    end
  end
end

return bump_debug
