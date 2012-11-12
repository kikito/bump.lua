local bump = {}

local path = (...):gsub("%.init$","")

local nodes      = require(path .. '.nodes')
local cells      = require(path .. '.cells')
local grid       = require(path .. '.grid')
local geometry   = require(path .. '.geometry')
local util       = require(path .. '.util')

bump.nodes, bump.cells, bump.grid, bump.geometry, bump.util = nodes, cells, grid, geometry, util

--------------------------------------
-- Private stuff

local collisions, prevCollisions

local function _getNearestIntersection(item, visited)
  local ni = nodes.get(item)
  local nNeighbor, nDx, nDy, nArea = nil, 0,0,0
  local nn, dx, dy, area
  local eachIntersection = function(neighbor)
    if item ~= neighbor and bump.shouldCollide(item, neighbor) then
      nn = nodes.get(neighbor)
      dx, dy = geometry.boxesDisplacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)
      area = util.abs(dx*dy)
      if area > nArea then
        nArea, nDx, nDy = area, dx, dy
        nNeighbor = neighbor
      end
    end
  end
  cells.eachItem(eachIntersection, ni.gl, ni.gt, ni.gw, ni.gh, visited)
  return nNeighbor, nDx, nDy
end

local function _collideItemWithNeighbors(item)
  local ni = nodes.get(item)
  local visited = {}
  local neighbor, dx, dy
  repeat
    neighbor, dx, dy = _getNearestIntersection(item, visited)
    if neighbor then
      if collisions[neighbor] and collisions[neighbor][item] then return end

      local nn = nodes.get(neighbor)

      if not geometry.boxesIntersect(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h) then return end

      local dx, dy = geometry.boxesDisplacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)

      bump.collision(item, neighbor, dx, dy)

      bump.update(item)
      bump.update(neighbor)

      collisions[item] = collisions[item] or util.newWeakTable()
      collisions[item][neighbor] = true

      if prevCollisions[item] then prevCollisions[item][neighbor] = nil end

      visited[neighbor] = true
    end
  until not neighbor
end

--------------------------------------
-- Public functions

function bump.getCellSize()
  return grid.getCellSize()
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

function bump.each(callback, l,t,w,h)
  local visited = {}
  if l then
    cells.eachItem(function(item)
      local node = nodes.get(item)
      if geometry.boxesIntersect(l,t,w,h, node.l, node.t, node.w, node.h) then
        callback(item)
      end
    end, grid.getBox(l,t,w,h))
  else
    cells.eachItem(callback)
  end
end

function bump.collide()
  collisions = util.newWeakTable()
  bump.each(_collideItemWithNeighbors)

  for item,neighbors in pairs(prevCollisions) do
    for neighbor,_ in pairs(neighbors) do
      bump.endCollision(item, neighbor)
    end
  end

  prevCollisions = collisions
end

function bump.initialize(newCellSize)
  grid.reset(newCellSize)
  nodes.reset()
  cells.reset()
  prevCollisions = util.newWeakTable()
  collisions     = nil
end

-- overridable functions
function bump.collision(item1, item2, dx, dy)
end

function bump.endCollision(item1, item2)
end

function bump.shouldCollide(item1, item2)
  return true
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

bump.initialize()

return bump
