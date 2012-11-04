local cells = {} -- (public/exported) holds the public cell interface
local store      -- (private) holds references to the individual rows and cells

local function newWeakTable(mode)
  return setmetatable({}, {__mode = mode or 'k'})
end

function cells.reset(newCellSize)
  store = { rows = {}, nonEmptyCells = {} }
  cells.store = store
end

function cells.create(x,y)
  store.rows[y] = store.rows[y] or newWeakTable('v')
  local cell = {items = newWeakTable()}
  store.rows[y][x] = cell
  return cell
end

function cells.getOrCreate(x,y)
  return store.rows[y] and store.rows[y][x] or cells.create(x,y)
end

function cells.addItem(item, gl,gt,gw,gh)
  local cell
  for x=gl,gl+gw do
    for y=gt,gt+gh do
      cell = cells.getOrCreate(x,y)
      cell.items[item] = true
      store.nonEmptyCells[cell] = true
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
