-- bump.lua - v1.2 (2012-08)
-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local bump = {}

local _weakKeys   = {__mode = 'k'}
local _weakValues = {__mode = 'v'}
local _defaultCellSize = 128

local abs, floor, ceil = math.abs, math.floor, math.ceil

local function newWeakTable(t, mt)
  return setmetatable(t or {}, mt or _weakKeys)
end

-- a bit faster than math.min
local function min(a,b) return a < b and a or b end

-- private bump properties
local  __cellSize, __cells, __occupiedCells, __items, __collisions, __prevCollisions, __tested

-- given a table, return its keys organized as an array (values are ignored)
local function _getKeys(t)
  local keys, length = {},0
  for k,_ in pairs(t) do
    length = length + 1
    keys[length] = k
  end
  return keys, length
end

-- fast check that returns true if 2 boxes are intersecting
local function _boxesIntersect(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

-- returns the area & minimum displacement vector given two intersecting boxes
local function _getOverlapAndDisplacementVector(l1,t1,w1,h1,c1x,c1y, l2,t2,w2,h2,c2x,c2y)
  local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
  local dy = t2 - t1 + (c1y < c2y and -h1 or h2)
  local ax, ay = abs(dx), abs(dy)
  local area = ax * ay

  if ax < ay then return area, dx, 0 end
  return area, 0, dy
end

-- given a world coordinate, return the coordinates of the cell that would contain it
local function _toGrid(wx, wy)
  return floor(wx / __cellSize) + 1, floor(wy / __cellSize) + 1
end

-- Same as _toGrid, but useful for calculating the right/bottom borders of a rectangle (so they are still inside the cell when touching borders)
local function _toGridFromInside(wx,wy)
  return ceil(wx / __cellSize), ceil(wy / __cellSize)
end

-- given a box in world coordinates, return a box in grid coordinates that contains it
-- returns the x,y coordinates of the top-left cell, the number of cells to the right and the number of cells down.
local function _toGridBox(l, t, w, h)
  if not (l and t and w and h) then return nil end
  local gl,gt = _toGrid(l, t)
  local gr,gb = _toGridFromInside(l+w, t+h)
  return gl, gt, gr-gl, gb-gt
end

-- returns, given its coordinates (on grid terms)
-- If createIfNil is true, it creates the cells if they don't exist
local function _getCell(gx, gy, createIfNil)
  if not createIfNil then return __cells[gy] and __cells[gy][gx] end
  __cells[gy]     = __cells[gy]     or newWeakTable({}, _weakValues)
  __cells[gy][gx] = __cells[gy][gx] or newWeakTable({itemCount = 0, items = newWeakTable()})
  return __cells[gy][gx]
end

-- applies a function to all cells in a given region. The region must be given in the form of gl,gt,gw,gh
-- (if the region desired is on world coordinates, it must be transformed in grid coords with _toGridBox)
-- if the last parameter is true, the function will also create the cells as it moves
local function _eachCellInRegion(f, gl,gt,gw,gh, createIfNil)
  local cell
  for y=gt, gt+gh do
    for x=gl, gl+gw do
      cell = _getCell(x,y, createIfNil)
      if cell then f(cell, x, y) end
    end
  end
end

-- applies a function to all cells in bump
local function _eachCell(f)
  for _,row in pairs(__cells) do
    for _,cell in pairs(row) do
      f(cell)
    end
  end
end

-- returns the items in a region, as keys in a table
-- if no region is specified, returns all items in bump
local function _collectItemsInRegion(gl,gt,gw,gh)
  if not (gl and gt and gw and gh) then return __items end
  local items = {}
  _eachCellInRegion(function(cell)
    if cell.itemCount > 0 then
      for item,_ in pairs(cell.items) do
        items[item] = true
      end
    end
  end, gl,gt,gw,gh)
  return items
end

-- applies f to all the items in the specified region
-- if no region is specified, apply to all items in bump
local function _eachInRegion(f, gl,gt,gw,gh)
  for item,_ in pairs(_collectItemsInRegion(gl,gt,gw,gh)) do f(item) end
end

-- parses the cells touching one item, and removes the item from their list of items
-- does not create new cells
local function _unregisterItem(item)
  local info = __items[item]
  if info and info.gl then
    info.unregister = info.unregister or function(cell)
      cell.items[item] = nil
      cell.itemCount = cell.itemCount - 1
      if cell.itemCount == 0 then
        __occupiedCells[cell] = nil
      end
    end
    _eachCellInRegion(info.unregister, info.gl, info.gt, info.gw, info.gh)
  end
end

-- parses all the cells that touch one item, adding the item to their list of items
-- creates cells if they don't exist
local function _registerItem(item, gl, gt, gw, gh)
  local info = __items[item]
  info.register = info.register or function(cell)
    cell.items[item] = true
    cell.itemCount = cell.itemCount + 1
    __occupiedCells[cell] = true
  end
  _eachCellInRegion(info.register, info.gl, info.gt, info.gw, info.gh, true)
end

-- updates the information bump has about one item - its boundingbox, and containing region, center
local function _updateItem(item)
  local info = __items[item]
  if not info or info.static then return end

  -- if the new bounding box is different from the stored one
  local l,t,w,h = bump.getBBox(item)
  if l ~= info.l or t ~= info.t or w ~= info.w or h ~= info.h then

    local gl, gt, gw, gh = _toGridBox(l, t, w, h)
    if gl ~= info.gl or gt ~= info.gt or gw ~= info.gw or gh ~= info.gh then
      -- remove this item from all the cells that used to contain it
      _unregisterItem(item)
      -- update the grid info
      info.gl, info.gt, info.gw, info.gh = gl, gt, gw, gh
      -- then add it to the new cells
      _registerItem(item)
    end

    info.l, info.t, info.w, info.h = l, t, w, h
    info.cx, info.cy = l+w*.5, t+h*0.5
  end
end

-- given an item and the neighbor which is colliding with it the most,
-- store the result in the collisions and tested tables
-- invoke the bump collision callback and mark the collision as "still happening"
local function _collideItemWithNeighbor(item, neighbor, dx, dy)
  -- store the collision
  __collisions[item] = __collisions[item] or newWeakTable()
  __collisions[item][neighbor] = true

  -- invoke the collision callback
  bump.collision(item, neighbor, dx, dy)

  -- remove the collison from the "previous collisions" list. The collisions that remain there will trigger the "endCollision" callback
  if __prevCollisions[item] then __prevCollisions[item][neighbor] = nil end

  -- recalculate the item & neighbor (in case they have moved)
  _updateItem(item)
  _updateItem(neighbor)

  -- mark the couple item-neighbor as tested, so the inverse is not calculated
  __tested[item] = __tested[item] or newWeakTable()
  __tested[item][neighbor] = true
end


-- Obtain the list of neighbors (list of items touching the cells touched by item)
-- minus the already visited ones
-- The neighbors are returned as keys in a table
local function _getNeighbors(item, visited)
  local info = __items[item]
  local neighbors = _collectItemsInRegion(info.gl, info.gt, info.gw, info.gh)
  neighbors[item] = nil
  for n,_ in pairs(visited) do neighbors[n] = nil end
  return neighbors
end

-- Given an item and a list of neighbors,
-- find the overlaps between the item and each neighbor. The resulting table has this structure:
-- { {neighbor=n1, area=1, dx=1, dy=1}, {neighbor=n2, ...} }
local function _getOverlaps(item, neighbors)
  local overlaps, overlapsLength = {},0
  local info = __items[item]
  local area, dx, dy, ninfo
  for neighbor,_ in pairs(neighbors) do
    ninfo = __items[neighbor]
    if ninfo
    and not (__tested[neighbor] and __tested[neighbor][item])
    and _boxesIntersect(info.l, info.t, info.w, info.h, ninfo.l, ninfo.t, ninfo.w, ninfo.h)
    and bump.shouldCollide(item, neighbor)
    then
      area, dx, dy = _getOverlapAndDisplacementVector(info.l, info.t, info.w, info.h, info.cx, info.cy,
                                                      ninfo.l, ninfo.t, ninfo.w, ninfo.h, ninfo.cx, ninfo.cy)
      overlapsLength = overlapsLength + 1
      overlaps[overlapsLength] = {neighbor=neighbor, area=area, dx=dx, dy=dy}
    end
  end
  return overlaps, overlapsLength
end

-- Given a table of overlaps in the form { {area=1, ...}, {area=2, ...} } and its length,
-- find the element with the biggest area, and return element.neighbor, element.dx, element.dy
-- returns nil if the table is empty
local function _getMaximumAreaOverlap(overlaps, overlapsLength)
  if overlapsLength == 0 then return nil end
  local maxOverlap = overlaps[1]
  local overlap
  for i=2,overlapsLength do
    overlap = overlaps[i]
    if maxOverlap.area < overlap.area then
      maxOverlap = overlap
    end
  end
  return maxOverlap.neighbor, maxOverlap.dx, maxOverlap.dy
end

-- Given an item and a list of items to ignore (already visited),
-- find the neighbor (if any) which is colliding with it the most
-- (the one who occludes more surface)
-- returns neighbor, dx, dy or nil if no collisions happen
local function _getNextCollisionForItem(item, visited)
  return _getMaximumAreaOverlap(_getOverlaps(item, _getNeighbors(item, visited)))
end

-- given an item, parse all its neighbors, updating the collisions & tested tables, and invoking the collision callback
-- if there is a collision, the list of neighbors is recalculated. However, the same
-- neighbor is not checked for collisions twice
-- static items are ignored
local function _collideItemWithNeighbors(item)
  local info = __items[item]
  if not info or info.static then return end

  local visited  = {}
  local finished = false
  local neighbor, dx, dy
  while __items[item] and not finished do
    neighbor, dx, dy = _getNextCollisionForItem(item, visited)
    if neighbor then
      visited[neighbor] = true
      _collideItemWithNeighbor(item, neighbor, dx, dy)
    else
      finished = true
    end
  end
end

-- fires bump.endCollision with the appropiate parameters
local function _invokeEndCollision()
  for item,neighbors in pairs(__prevCollisions) do
    if __items[item] then
      for neighbor, d in pairs(neighbors) do
        if __items[neighbor] then
          bump.endCollision(item, neighbor)
        end
      end
    end
  end
end

-- public interface

-- (Optional) Initializes the lib with a cell size (see detault at the begining of file)
function bump.initialize(cellSize)
  __cellSize       = cellSize or _defaultCellSize
  __cells          = newWeakTable()
  __occupiedCells  = {} -- stores strong references to cells so that they are not gc'ed
  __items          = newWeakTable()
  __prevCollisions = newWeakTable()
  bump.items = __items
end

-- (Overridable). Called when two objects start colliding
-- dx, dy is how much you have to move item1 so it doesn't
-- collide any more
function bump.collision(item1, item2, dx, dy)
end

-- (Overridable) Called when two objects stop colliding
function bump.endCollision(item1, item2)
end

-- (Overridable) Returns true if two objects can collide, false otherwise
-- Useful for making categories, and groups of objects that don't collide
-- Between each other
function bump.shouldCollide(item1, item2)
  return true
end

-- (Overridable) Given an item, return its bounding box (l,t,w,h)
function bump.getBBox(item)
  return item:getBBox()
end

-- Adds an item to bump
function bump.add(item)
  __items[item] = __items[item] or {}
  _updateItem(item)
end

-- Adds a static item to bump. Static items never change their bounding box, and never
-- receive collision checks (other items can collision with them, but they don't collide with
-- others)
function bump.addStatic(item)
  bump.add(item)
  __items[item].static = true
end

-- Removes an item from bump
function bump.remove(item)
  _unregisterItem(item)
  __items[item] = nil
end

-- Performs collisions and invokes bump.collision and bump.endCollision callbacks
-- If a world region is specified, only the items in that region are updated. Else all items are updated
function bump.collide(l,t,w,h)
  bump.each(_updateItem, l,t,w,h)

  __collisions, __tested = newWeakTable(), newWeakTable()
  bump.each(_collideItemWithNeighbors, l,t,w,h)

  _invokeEndCollision()

  __prevCollisions = __collisions
end

-- Applies a function (signature: function(cell) end) to all the cells that "touch"
-- the specified rectangle. If no rectangle is specified, use all cells instead
function bump.eachCell(f, l,t,w,h)
  if l and t and w and h then
    _eachCellInRegion(f, _toGridBox(l,t,w,h))
  else
    _eachCell(f)
  end
end

-- Applies a function (signature: function(item) end) to all the items that "touch"
-- the cells specified by a rectangle. If no rectangle is given, the function
-- is applied to all items
function bump.each(f, l,t,w,h)
  _eachInRegion(f, _toGridBox(l,t,w,h))
end

function bump.collect(l,t,w,h)
  return _getKeys(_collectItemsInRegion(_toGridBox(l,t,w,h)))
end

-- returns the size of the cell that bump is using
function bump.getCellSize()
  return __cellSize
end

bump.initialize()

return bump
