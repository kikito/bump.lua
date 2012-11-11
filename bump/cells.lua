local cells = {} -- (public/exported) holds the public cell interface
local store      -- (private) holds references to the individual rows and cells

local function newWeakTable(mode)
  return setmetatable({}, {__mode = mode or 'k'})
end


function cells.create(gx,gy)
  store.rows[gy] = store.rows[gy] or newWeakTable('v')
  local cell = {items = newWeakTable(), gx=gx, gy=gy}
  store.rows[gy][gx] = cell
  return cell
end

function cells.getOrCreate(gx,gy)
  return store.rows[gy] and store.rows[gy][gx] or cells.create(gx,gy)
end

function cells.add(item, gl,gt,gw,gh)
  local cell
  for gx=gl,gl+gw do
    for gy=gt,gt+gh do
      cell = cells.getOrCreate(gx,gy)
      cell.items[item] = true
      store.nonEmptyCells[cell] = store.nonEmptyCells[cell] or 0
      store.nonEmptyCells[cell] = store.nonEmptyCells[cell] + 1
    end
  end
end

function cells.remove(item, gl,gt,gw,gh)
  cells.each(function(cell)
    cell.items[item] = nil
    store.nonEmptyCells[cell] = store.nonEmptyCells[cell] - 1
    if store.nonEmptyCells[cell] == 0 then store.nonEmptyCells[cell] = nil end
  end)
end

function cells.each(callback, gl,gt,gw,gh)
  if gl then
    local row, cell
    for gy=gt,gt+gh do
      row = store.rows[gy]
      if row then
        for gx=gl,gl+gw do
          cell = row[gx]
          if cell then callback(cell) end
        end
      end
    end
  else
    for _,row in pairs(store.rows) do
      for _,cell in pairs(row) do
        callback(cell)
      end
    end
  end
end

local function copy(t)
  local c = {}
  for k,v in pairs(t) do c[k] = v end
  return c
end

function cells.eachItem(callback, gl,gt,gw,gh, visited)
  visited = visited and copy(visited) or {}
  cells.each(function(cell)
    for item,_ in pairs(cell.items) do
      if not visited[item] then
        visited[item] = true
        callback(item)
      end
    end
  end, gl, gt, gw, gh)
end

function cells.count()
  local count = 0
  cells.each(function() count = count + 1 end)
  return count
end

function cells.reset(newCellSize)
  store = { rows = {}, nonEmptyCells = {} }
  cells.store = store
end

cells.reset()

return cells
