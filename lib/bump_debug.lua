local bump_debug = {}

local function getCellRect(world, cx,cy)
  local l,t = world:toWorld(cx,cy)
  return l,t,world.cellSize,world.cellSize
end

function bump_debug.draw(world, l,t,w,h)

  local cellSize = world.cellSize
  local minx, miny = world:toCell(l,t)
  local maxx = math.ceil((l+w) / cellSize)
  local maxy = math.ceil((t+h) / cellSize)
  local rows = world.rows
  local row, cell, cl, ct, cw, ch, intensity

  for y = miny, maxy do
    row = rows[y]
    if row then
      for x = minx, maxx do
        cell = row[x]
        if cell then
          cl,ct,cw,ch = getCellRect(world, x,y)
          intensity = cell.itemCount * 40 + 30
          love.graphics.setColor(intensity, intensity, intensity)
          love.graphics.print(cell.itemCount, cl+12, ct+12)
          love.graphics.rectangle('line', cl,ct,cw,ch)
        end
      end
    end
  end
end

return bump_debug
