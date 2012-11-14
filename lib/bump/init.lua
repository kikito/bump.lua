local bump = {}

local path = (...):gsub("%.init$","")

local nodes  = require(path .. '.nodes')
local cells  = require(path .. '.cells')
local geom   = require(path .. '.geom')
local util   = require(path .. '.util')

bump.nodes, bump.cells, bump.geom, bump.util = nodes, cells, geom, util

--------------------------------------
-- Locals for faster acdess

local nodes_get, nodes_add, nodes_remove, nodes_update =
      nodes.get, nodes.add, nodes.remove, nodes.update

local cells_eachItem, cells_add, cells_remove =
      cells.eachItem, cells.add, cells.remove

local geom_boxesDisplacement, geom_boxesIntersect, geom_gridBox =
      geom.boxesDisplacement, geom.boxesIntersect, geom.gridBox

local util_abs, util_newWeakTable = util.abs, util.newWeakTable

--------------------------------------
-- Private stuff

local defaultCellSize = 64
local cellSize, collisions, prevCollisions

local function _getBiggestIntersection(item, visited)
  local ni = nodes_get(item)
  if not ni then return end
  local nNeighbor, nMdx, nMdy, nDx, nDy, nArea = nil, 0,0,0,0,0
  local nn, mdx, mdy, dx, dy, area
  local compareNeighborIntersection = function(neighbor)
    if item == neighbor or not bump.shouldCollide(item, neighbor) then return end
    nn = nodes_get(neighbor)
    if not geom_boxesIntersect(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h) then return end

    mdx, mdy, dx, dy = geom_boxesDisplacement(ni.l, ni.t, ni.w, ni.h, nn.l, nn.t, nn.w, nn.h)
    area = util_abs(dx*dy)
    if area > nArea then
      nArea, nMdx, nMdy, nDx, nDy = area, mdx, mdy, dx, dy
      nNeighbor = neighbor
    end
  end
  cells_eachItem(compareNeighborIntersection, ni.gl, ni.gt, ni.gw, ni.gh, visited)
  return nNeighbor, nMdx, nMdy, nDx, nDy
end

local function _collideItemWithNeighbors(item)
  local ni = nodes_get(item)
  local visited = {}
  local neighbor, mdx, mdy, dx, dy
  repeat
    neighbor, mdx, mdy, dx, dy = _getBiggestIntersection(item, visited)
    if neighbor then
      if collisions[neighbor] and collisions[neighbor][item] then return end

      local nn = nodes_get(neighbor)

      bump.collision(item, neighbor, mdx, mdy, dx, dy)

      bump.update(item)
      bump.update(neighbor)

      collisions[item] = collisions[item] or util_newWeakTable()
      collisions[item][neighbor] = true

      if prevCollisions[item] then prevCollisions[item][neighbor] = nil end

      visited[neighbor] = true
    end
  until not neighbor
end

--------------------------------------
-- Public stuff

function bump.getCellSize()
  return cellSize
end

-- adds one or more items into bump
function bump.add(item1, ...)
  assert(item1, "at least one item expected, got nil")
  local items = {item1, ...}
  for i=1, #items do
    local item = items[i]
    local l,t,w,h = bump.getBBox(item)
    local gl,gt,gw,gh = geom_gridBox(cellSize, l,t,w,h)

    nodes_add(item, l,t,w,h, gl,gt,gw,gh)
    cells_add(item, gl,gt,gw,gh)
  end
end

-- removes an item from bump
function bump.remove(item)
  assert(item, "item expected, got nil")
  local node = nodes_get(item)
  if node then
    cells_remove(item, node.gl, node.gt, node.gw, node.gh)
    nodes_remove(item)
  end
end

-- Updates the cached information that bump has about an item (bounding boxes, etc)
function bump.update(item)
  assert(item, "item expected, got nil")
  local n = nodes_get(item)
  if not n then return end
  local l,t,w,h = bump.getBBox(item)
  if n.l ~= l or n.t ~= t or n.w ~= w or n.h ~= h then

    local gl,gt,gw,gh = geom_gridBox(cellSize, l,t,w,h)
    if n.gl ~= gl or n.gt ~= gt or n.gw ~= gw or n.gh ~= gh then
      cells_remove(item, n.gl, n.gt, n.gw, n.gh)
      cells_add(item, gl, gt, gw, gh)
    end

    nodes_update(item, l,t,w,h, gl,gt,gw,gh)
  end
end

-- Execute callback in all the items on the region (if no region specified, do it
-- in all items)
function bump.each(callback, l,t,w,h)
  local visited = {}
  if l then
    cells_eachItem(function(item)
      local node = nodes_get(item)
      if geom_boxesIntersect(l,t,w,h, node.l, node.t, node.w, node.h) then
        callback(item)
      end
    end, geom_gridBox(cellSize, l,t,w,h))
  else
    cells_eachItem(callback)
  end
end

-- Invoke this function inside your 'update' loop. It will invoke bump.collision and
-- bump.endCollision for all the pairs of items that should collide
-- By default it updates the information of all items before performing the checks.
-- You may choose to update the information manually by passing false in the param
-- and using bump.update() on each item that moves manually.
function bump.collide(globalUpdate)
  if globalUpdate ~= false then bump.each(bump.update) end

  collisions = util_newWeakTable()
  bump.each(_collideItemWithNeighbors)

  for item,neighbors in pairs(prevCollisions) do
    for neighbor,_ in pairs(neighbors) do
      bump.endCollision(item, neighbor)
    end
  end

  prevCollisions = collisions
end

-- This resets the library. You can use it to change the cell size, if you want
function bump.initialize(newCellSize)
  cellSize = newCellSize or defaultCellSize
  nodes.reset()
  cells.reset()
  prevCollisions = util_newWeakTable()
  collisions     = nil
end

--------------------------------------
-- Stuff that the user will probably want to override

-- called when two items collide. dx, dy is how much must item1 be moved to stop
-- intersecting with item2. Override this function to get a collision callback
function bump.collision(item1, item2, dx, dy)
end

-- called at the end of the bump.collide() function, if two items where collidng
-- before but not any more. Override this function to get a callback when a pair
-- of items stop colliding
function bump.endCollision(item1, item2)
end

-- This function must return true if item1 'interacts' with item2. If it returns
-- false, then they will not collide. Override this function if you want to make
-- 'groups of boxes that don't collide with each other', and that kind of thing.
-- By default, all items collide with all items
function bump.shouldCollide(item1, item2)
  return true
end

-- This is how the bounding box of an object is calculated. You might want to
-- override it if your items have a different way to calculate it. Must return
-- left, top, width and height, in that order.
function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

bump.initialize()

return bump
