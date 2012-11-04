local grid = {}

local cellSize   -- (private) holds the size of each cell
local defaultCellSize = 64
local floor  = math.floor
local ceil   = math.ceil

local function getCoords(wx,wy)
  return floor(wx / cellSize) + 1, floor(wy / cellSize) + 1
end
grid.getCoords = getCoords

function grid.getBox(wl,wt,ww,wh)
  local l,t = getCoords(wl, wt)
  local r,b = ceil((wl+ww) / cellSize), ceil((wt+wh) / cellSize)
  return l, t, r-l, b-t
end

function grid.reset(newCellSize)
  cellSize = newCellSize or defaultCellSize
end

function grid.getCellSize()
  return cellSize
end


return grid
