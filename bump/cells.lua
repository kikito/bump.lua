local cells = {} -- (public/exported) holds the public cell interface
local store      -- (private) holds references to the individual rows and cells
local cellSize   -- (private) holds the size of each cell
local defaultCellSize = 64
local weakmt = {__mode='k'}
local floor  = math.floor
local ceil   = math.ceil

function cells.reset(newCellSize)
  cellSize = newCellSize or defaultCellSize
  store = { rows = {}, nonEmptyCells = {} }
end

function cells.getSize()
  return cellSize
end

function cells.create(x,y)
  store[y] = store[y] or setmetatable({}, weakmt)
  local cell = {}
  store[y][x] = cell
  return cell
end

function cells.getOrCreate(x,y)
  return store[y] and store[y][x] or cells.create(x,y)
end

function cells.toGridCoords(wx,wy)
  return floor(wx / cellSize) + 1, floor(wy / cellSize) + 1
end

function cells.toGridBox(wl,wt,ww,wh)
  local l,t = cells.toGridCoords(wl, wt)
  local r,b = ceil((wl+ww) / cellSize), ceil((wt+wh) / cellSize)
  return l, t, r-l, b-t
end

function cells.count()
  local count = 0
  for _,row in pairs(store) do
    for _,_ in pairs(row) do
      count = count + 1
    end
  end
  return count
end

cells.reset()

return cells
