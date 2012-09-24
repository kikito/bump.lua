local bump = {}

local defaultCellSize = 64
local cellSize = defaultCellSize

function bump.initialize(newCellSize)
  cellSize = newCellSize or defaultCellSize
end

function bump.getCellSize()
  return cellSize
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

return bump
