-- bump.lua - v1.0 (2012-06)
-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local bump = {}

local _weakKeys   = {__mode = 'k'}
local _weakValues = {__mode = 'v'}
local _defaultCellSize = 128

local abs, floor, sort = math.abs, math.floor, table.sort

local function newWeakTable(t, mt)
  return setmetatable(t or {}, mt or _weakKeys)
end

-- a bit faster than math.min
local function min(a,b) return a < b and a or b end

-- private bump properties
local  __cellSize, __cells, __occupiedCells, __items, __collisions, __prevCollisions, __tested


-- performs the collision between two bounding boxes
-- if no collision, it returns false
-- else, it returns true, dx, dy, where dx and dy are
-- the minimal direction to where the first box has to be moved
-- in order to not intersect with the second any more
-- prevDx and prevDy are previous collisions. They affect how the next dx and dy are calculated
local function _boxCollision(l1,t1,w1,h1, l2,t2,w2,h2, prevDx, prevDy)

  -- if there is a collision
  if l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2 then

    -- get box centers
    local c1x, c1y = l1 + w1 * .5, t1 + h1 * .5
    local c2x, c2y = l2 + w2 * .5, t2 + h2 * .5

    -- get the two overlaps
    local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
    local dy = t2 - t1 + (c1y < c2y and -h1 or h2)

    -- if there was a previous collision between these two items, keep pressing on the same direction
    if prevDx > 0 then return true, dx,  0 end
    if prevDy > 0 then return true,  0, dy end

    -- otherwise resolve using the smallest possible and set the other to 0
    if abs(dx) < abs(dy) then return true, dx, 0 end

    return true, 0, dy

  end
  -- no collision; return false
  return false
end

local function _monoDistance(c, lower, upper)
  return c < lower and lower-c or (c > upper and c-upper or min(c-lower, upper-c))
end

-- returns the squared distance between the center of item and the closest point in neighbor
local function _squareDistance(item, neighbor)
  local info, ninfo = __items[item], __items[neighbor]
  local cx,cy,l,t,w,h = info.cx, info.cy, ninfo.l, ninfo.t, ninfo.w, ninfo.h
  local dx,dy = _monoDistance(cx, l, l+w), _monoDistance(cy, t, t+h)
  return dx*dx + dy*dy
end

-- given a world coordinate, return the coordinates of the cell that would contain it
local function _toGrid(wx, wy)
  return floor(wx / __cellSize) + 1, floor(wy / __cellSize) + 1
end

-- given a box in world coordinates, return a box in cell coordinates that contains it
-- returns the x,y coordinates of the top-left cell, the number of cells to the right and the number of cells down.
local function _toGridBox(wl, wt, ww, wh)
  if not wl or not wt or not ww or not wh then return nil end
  local l,t = _toGrid(wl, wt)
  local r,b = _toGrid(wl+ww, wt+wh)
  return l, t, r-l, b-t
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

-- Applies f to all the items contained in the grid region described by gl,gt,gw,gh
-- Keeps an account of all the items in the region
local function _eachItemInRegion(f, gl,gt,gw,gh)
  local parsed = {}
  for y=gt, gt+gh do
    for x=gl, gl+gw do
      cell = _getCell(x,y)
      if cell and cell.itemCount > 0 then
        for item,_ in pairs(cell.items) do
          if not parsed[item] then
            f(item)
            parsed[item]=true
          end
        end
      end
    end
  end
end

-- applies f to all items in bump
local function _eachItem(f)
  for item,_ in pairs(__items) do
    f(item)
  end
end

-- Given an item and a cell, remove the item from the cell's list of items
local function _unlinkItemAndCell(item, cell)
  cell.items[item] = nil
  cell.itemCount = cell.itemCount - 1
  if cell.itemCount == 0 then
    __occupiedCells[cell] = nil
  end
end

-- parses the cells touching one item, and removes the item from their list of items
-- does not create new cells
local function _unlinkItem(item)
  local info = __items[item]
  if info and info.gl then
    info.unlinkCell = info.unlinkCell or function(cell) _unlinkItemAndCell(item, cell) end
    _eachCellInRegion(info.unlinkCell, info.gl, info.gt, info.gw, info.gh)
  end
end

-- Given an item and a cell, add the item to the items list of the cell. Mark the cell as "not empty"
local function _linkItemAndCell(item, cell)
  cell.items[item] = true
  cell.itemCount = cell.itemCount + 1
  __occupiedCells[cell] = true
end

-- parses all the cells that touch one item, adding the item to their list of items
-- creates cells if they don't exist
local function _linkItem(item, gl, gt, gw, gh)
  local info = __items[item]
  info.linkCell = info.linkCell or function(cell) _linkItemAndCell(item, cell) end
  _eachCellInRegion(info.linkCell, info.gl, info.gt, info.gw, info.gh, true)
end

-- updates the information bump has about one item - its boundingbox, and containing cells
local function _updateItem(item)
  local info = __items[item]
  if not info then return end

  -- if the new bounding box is different from the stored one
  local l,t,w,h = bump.getBBox(item)
  if l ~= info.l or t ~= info.t or w ~= info.w or h ~= info.h then

    local gl, gt, gw, gh = _toGridBox(l, t, w, h)
    if gl ~= info.gl or gt ~= info.gt or gw ~= info.gw or gh ~= info.gh then
      -- remove this item from all the cells that used to contain it
      _unlinkItem(item)
      -- update the grid info
      info.gl, info.gt, info.gw, info.gh = gl, gt, gw, gh
      -- then add it to the new cells
      _linkItem(item)
    end

    -- update the bounding box, center, and neighbor sorting function
    info.l, info.t, info.w, info.h = l, t, w, h
    info.cx, info.cy = l+w*.5, t+h*0.5
  end
end

-- Returns the neighbors of an item, sorted by distance (closests first) & the list length
local function _getItemNeighborsSorted(item)
  local info = __items[item]
  local neighbors, length = {}, 0
  local collectNeighbor = function(neighbor)
    if neighbor ~= item then
      length = length + 1
      neighbors[length] = neighbor
    end
  end
  _eachItemInRegion(collectNeighbor, info.gl, info.gt, info.gw, info.gh)

  info.neighborSort    = info.neighborSort or function(a,b)  return _squareDistance(a, item) < _squareDistance(b,item) end
  sort(neighbors, info.neighborSort)

  return neighbors, length
end

-- given an item and one of its neighbors, see if they collide. If yes,
-- store the result in the collisions and tested tables
-- invoke the bump collision callback and mark the collision as happened
local function _collideItemWithNeighbor(item, neighbor)
  -- store the collision, if it happened
  local info, ninfo = __items[item], __items[neighbor]
  local prevDx, prevDy = 0,0
  if __prevCollisions[item] and __prevCollisions[item][neighbor] then
    local prevVector = __prevCollisions[item][neighbor]
    prevDx, prevDy = prevVector.dx, prevVector.dy
  end

  collision, dx, dy = _boxCollision(
    info.l,  info.t,  info.w,  info.h,
    ninfo.l, ninfo.t, ninfo.w, ninfo.h,
    prevDx, prevDy
  )

  if collision then
    -- store the collision
    __collisions[item] = __collisions[item] or newWeakTable()
    __collisions[item][neighbor] = {dx = dx, dy = dy}

    -- invoke the collision callback
    bump.collision(item, neighbor, dx, dy)

    -- mark the collision has "happened"
    if __prevCollisions[item] then __prevCollisions[item][neighbor] = nil end

    -- recalculate the item & neighbor (in case they have moved)
    _updateItem(item)
    _updateItem(neighbor)
  end

  -- mark the couple item-neighbor as tested, so the inverse is not calculated
  __tested[item] = __tested[item] or newWeakTable()
  __tested[item][neighbor] = true
end

-- given an item, parse all its neighbors, updating the collisions & tested tables, and invoking the collision callback
local function _collideItemWithNeighbors(item)
  local neighbor
  local neighbors, length = _getItemNeighborsSorted(item)

  -- check if there are any neighbors on that group of cells
  for i=1,length do
    neighbor = neighbors[i]
    if  __items[item] and __items[neighbor]
    and not (__tested[neighbor] and __tested[neighbor][item])
    and bump.shouldCollide(item, neighbor) then
      _collideItemWithNeighbor(item, neighbor)
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

-- Removes an item from bump
function bump.remove(item)
  _unlinkItem(item)
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
  if l and t and w and h then
    _eachItemInRegion(f, _toGridBox(l,t,w,h))
  else
    _eachItem(f)
  end
end

-- returns the size of the cell that bump is using
function bump.getCellSize()
  return __cellSize
end

bump.initialize()


return bump
