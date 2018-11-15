local bump_debug = {}

local function getCellRect(world, cx,cy)
  local cellSize = world.cellSize
  local l,t = world:toWorld(cx,cy)
  return l,t,cellSize,cellSize
end

function bump_debug.draw(world)
  for cy, row in pairs(world.rows) do
    for cx, cell in pairs(row) do
      local l,t,w,h = getCellRect(world, cx,cy)
      local intensity = (cell.itemCount * 16 + 16) / 255
      love.graphics.setColor(1,1,1,intensity)
      love.graphics.rectangle('fill', l,t,w,h)
      love.graphics.setColor(1,1,1,0.04)
      love.graphics.rectangle('line', l,t,w,h)
    end
  end
end

return bump_debug
