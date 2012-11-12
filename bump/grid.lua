-- bump.grid
-- This bump module contains basic operations about the underlaying grid
-- The individual cells, however, are managed in the bump.cells module

local grid = {}

local cellSize   -- (private) holds the size of each cell
local defaultCellSize = 64
local floor  = math.floor
local ceil   = math.ceil

local function grid_getCoords(wx,wy)
  return floor(wx / cellSize) + 1, floor(wy / cellSize) + 1
end
grid.getCoords = grid_getCoords

function grid.getBox(wl,wt,ww,wh)
  if not wl then return nil end
  local l,t = grid_getCoords(wl, wt)
  local r,b = ceil((wl+ww) / cellSize), ceil((wt+wh) / cellSize)
  return l, t, r-l, b-t
end

function grid.getCellSize()
  return cellSize
end

function grid.reset(newCellSize)
  cellSize = newCellSize or defaultCellSize
end

grid.reset()

return grid
