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

local function copy(t)
  local c = {}
  for k,v in pairs(t) do c[k] = v end
  return c
end

function bump.eachNeighbor(item, callback, visited)
  local node = nodes.get(item)
  assert(node, "Item must be added to bump before calculating its neighbors")
  visited = visited and copy(visited) or {}
  visited[item] = true -- don't visit the item, just its neighbors
  cells.eachItem(callback, node.gl, node.gt, node.gw, node.gh, visited)
end

function bump.collision(item1, item2, dx, dy)
end

function bump.collideItem(item, collidedPairs)
  collidedPairs = collidedPairs or {}
  local ni = nodes.get(item)
  local visited = {}
  local neighbor, dx, dy
  repeat
    neighbor, dx, dy = bump.getNearestIntersection(item, visited)
    if neighbor then
      if collidedPairs[neighbor] and collidedPairs[neighbor][item] then return end

      local nn = nodes.get(neighbor)

      if not intersect.quick(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h) then return end

      local dx, dy = intersect.displacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)

      bump.collision(item, neighbor, dx, dy)

      bump.update(item)
      bump.update(neighbor)

      collidedPairs[item] = collidedPairs[item] or {}
      collidedPairs[item][neighbor] = true

      visited[neighbor] = true
    end
  until not neighbor
end


function bump.getNearestIntersection(item, visited)
  visited = visited or {}
  local nNeighbor, nDx, nDy, nArea = nil, 0,0,0
  local ni = nodes.get(item)
  bump.eachNeighbor(item, function(neighbor)
    local nn = nodes.get(neighbor)
    local area, dx, dy = intersect.areaAndDisplacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)
    if area > nArea then
      nArea, nDx, nDy = area, dx, dy
      nNeighbor = neighbor
    end
  end, visited)
  return nNeighbor, nDx, nDy
end

function bump.collide()
  local collidedPairs = {}
  bump.each(function(item) bump.collideItem(item, collidedPairs) end)
end

return bump
