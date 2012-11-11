local bump = {}

local path = (...):gsub("%.init$","")

local nodes      = require(path .. '.nodes')
local cells      = require(path .. '.cells')
local grid       = require(path .. '.grid')
local intersect  = require(path .. '.intersect')

bump.nodes, bump.cells, bump.grid = nodes, cells, grid

function bump.initialize(newCellSize)
  nodes.reset()
  grid.reset(newCellSize)
  cells.reset()
end

function bump.getCellSize()
  return grid.getCellSize()
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

function bump.add(item1, ...)
  assert(item1, "at least one item expected, got nil")
  local items = {item1, ...}
  for i=1, #items do
    local item = items[i]
    local l,t,w,h = bump.getBBox(item)
    local gl,gt,gw,gh = grid.getBox(l,t,w,h)

    nodes.add(item, l,t,w,h, gl,gt,gw,gh)
    cells.add(item, gl,gt,gw,gh)
  end
end

function bump.remove(item)
  assert(item, "item expected, got nil")

  nodes.remove(item)
  cells.remove(item, grid.getBox(bump.getBBox(item)))
end

function bump.update(item)
  assert(item, "item expected, got nil")
  local n = nodes.get(item)
  local l,t,w,h = bump.getBBox(item)
  if n.l ~= l or n.t ~= t or n.w ~= w or n.h ~= h then
    local gl,gt,gw,gh = grid.getBox(l,t,w,h)
    if n.gl ~= gl or n.gt ~= gt or n.gw ~= gw or n.gh ~= gh then
      cells.remove(item, n.gl, n.gt, n.gw, n.gh)
      cells.add(item, gl, gt, gw, gh)
    end
    nodes.update(item, l,t,w,h, gl,gt,gw,gh)
  end
end

function bump.countItems()
  return nodes.count()
end

function bump.countCells()
  return cells.count()
end

function bump.each(callback, l,t,w,h)
  local visited = {}
  if l then
    cells.eachItem(function(item)
      local node = nodes.get(item)
      if intersect.quick(l,t,w,h, node.l, node.t, node.w, node.h) then
        callback(item)
      end
    end, grid.getBox(l,t,w,h))
  else
    cells.eachItem(callback)
  end
end

function bump.eachNeighbor(item, callback)
  local node = nodes.get(item)
  assert(node, "Item must be added to bump before calculating its neighbors")

  cells.eachItem(function(neighbor)
    if item ~= neighbor then callback(neighbor) end
  end, node.gl, node.gt, node.gw, node.gh)
end

function bump.collision(item1, item2, dx, dy)
end

local function getNextCollisionForItem(item, visitedNeighbors)
  local node = nodes.get(item)
  cells.each(function(cell)
    for neighbor,_ in pairs(cell.items) do
      if not visitedNeighbors[neighbor] then
        visitedNeighbors[neighbor] = true
        return neighbor
      end
    end
  end,
  node.gl, node.gt, node.gw, node.gh)
end

function bump.collide()
  local collidedPairs = {}
  bump.each(function(item)
    local ni = nodes.get(item)
    bump.eachNeighbor(item, function(neighbor)
      if collidedPairs[neighbor] and collidedPairs[neighbor][item] then return end

      local nn = nodes.get(neighbor)

      if not intersect.quick(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h) then return end

      local dx, dy = intersect.displacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)

      bump.collision(item, neighbor, dx, dy)

      bump.update(item)
      bump.update(neighbor)

      collidedPairs[item] = collidedPairs[item] or {}
      collidedPairs[item][neighbor] = true
    end)
  end)
end

return bump
