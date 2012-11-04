local cells = {} -- (public/exported) holds the public cell interface
local store      -- (private) holds references to the individual rows and cells

local function newWeakTable()
  return setmetatable({}, {__mode='k'})
end

function cells.reset(newCellSize)
  store = { rows = {}, nonEmptyCells = {} }
end

function cells.create(x,y)
  store[y] = store[y] or newWeakTable()
  local cell = {items = newWeakTable()}
  store[y][x] = cell
  return cell
end

function cells.getOrCreate(x,y)
  return store[y] and store[y][x] or cells.create(x,y)
end

function cells.addItem(item, gl,gt,gw,gh)
  local cell
  for x=gl,gl+gw do
    for y=gt,gt+gh do
      cell = cells.getOrCreate(x,y)
      cell.items[item] = true
    end
  end
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
