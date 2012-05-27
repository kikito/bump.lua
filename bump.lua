-- bump.lua - v0.1 (2012-05)
-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local bump = {}

local _weakmt = {mode = 'k'}
local abs, floor = math.abs, math.floor

local _items, _collisions, _prevCollisions, _cellSize, _cells

-- given a world coordinate, return the coordinates of the cell that would contain it
local function _toGrid(wx, wy)
  return floor(wx / _cellSize) + 1, floor(wy / _cellSize) + 1
end

-- given a box in world coordinates, return a box in cell coordinates that contains it
-- returns the x,y coordinates of the top-left cell, the number of cells to the right and the number of cells down.
local function _toGridBox(wl, wt, ww, wh)
  local l,t = _toGrid(wl, wt)
  local r,b = _toGrid(wl+ww, wt+wh)
  return l, t, r-l, b-t
end

-- returns (or creates, if it doesn't exist) a cell, given its coordinates (on grid terms)
local function _getCell(x, y)
  _cells[y] = _cells[y] or {}
  _cells[y][x] = _cells[y][x] or setmetatable({}, _weakmt)
  return _cells[y][x]
end

-- returns all the cells contained in a box (specified as x and y of top-left cell, number of cells left and number of cells down)
local function _getCells(l,t,w,h)
  local cells, len = {}, 0
  for y=t,t+h do
    for x=l,l+w do
      len = len + 1
      cells[len] = _getCell(x,y)
    end
  end
  return cells, len
end

-- returns (and creates, if needed) the cell that contains a real-world coordinate
local function _getContainingCell(wx, wy)
  return _getCell(_toGrid(wx, wy))
end

-- returns the cells containing a world in real world term
local function _getContainingCellsFromBox(wl, wt, ww, wh)
  return _getCells(_toGridBox(wl, wt, ww, wh))
end


-- performs the collision between two bounding boxes
-- if no collision, it returns false
-- else, it returns true, dx, dy, where dx and dy are
-- the minimal direction to where the first box has to be moved
-- in order to not intersect with the second any more
local function _boxCollision(l1,t1,w1,h1, l2,t2,w2,h2)

  -- if there is a collision
  if l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2 then

    -- get box centers
    local c1x, c1y = l1 + w1 * .5, t1 + h1 * .5
    local c2x, c2y = l2 + w2 * .5, t2 + h2 * .5

    -- get the two overlaps
    local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
    local dy = t2 - t1 + (c1y < c2y and -h1 or h2)

    -- return the smallest overlap, and set the other to 0
    if abs(dx) < abs(dy) then return true, dx, 0 end

    return true, 0, dy

  end
  -- no collision; return false
  return false
end

-- removes the grid info of an item (what cells does it occupy)
local function _unlink(item)
  local info = _items[item]
  if info then
    local cells = info.cells
    if info.cells then
      for i=1, info.cellsLength do
        cells[item] = nil
      end
    end
  end
end

-- updates the information hump has about one item - its boundingbox, and containing cells
local function _updateItem(item)
  local info = _items[item] or {}

  -- if the new bounding box is different from the stored one
  local l,t,w,h = bump.getBBox(item)
  if l ~= info.l or t ~= info.t or w ~= info.w or h ~= info.h then
    -- remove this item from all the cells that used to contain it
    _unlink(item)

    -- link it with the new cells that contain it
    local cells, cellsLength = _getContainingCellsFromBox(l,t,w,h)
    for i=1, cellsLength do
      cells[i][item] = true
    end

    -- store the info so it will be available on the next iteration
    info.l, info.t, info.w, info.h = l, t, w, h
    info.cells, info.cellsLength   = cells, cellsLength
    _items[item] = info
  end
end

-- updates the cell information (what cells every item is stepping in) - this takes care of moving items
local function _updateItems()
  for item,_ in pairs(_items) do
    _updateItem(item, info)
  end
end

-- Returns a new table containing references to all the calculated collisions
-- structure: { [item1] = { [item2] = {x=1,y=2} } }
-- so collisions[item1][item] = {x=1, y=2}
local function _calculateCollisions()
  local collisions = setmetatable({}, _weakmt)

  local l, t, w, h, cells
  local neighbor, ninfo
  local collision, dx, dy
  local tested = {}

  -- for each item stored in bump
  for item, info in pairs(_items) do
    l, t, w, h, cells = info.l, info.t, info.w, info.h, info.cells
    tested[item] = {}

    -- parse the cells intersecting with item's boundingbox
    for i=1, info.cellsLength do

      -- check if there are any neighbors on that group of cells
      for neighbor,_ in pairs(cells[i]) do
        -- skip this neighbor if:
        -- a) It's the same item whose neighbors we are checking out
        -- b) The opposite collision (neighbor-item instead of item-neighbor) has already been calculated
        if neighbor ~= item
        and not (tested[neighbor] and tested[neighbor][item]) then
          -- store the collision, if it happened
          ninfo = _items[neighbor]
          collision, dx, dy = _boxCollision(l, t, w, h, ninfo.l, ninfo.t, ninfo.w, ninfo.h)

          if collision then
            collisions[item] = collisions[item] or setmetatable({}, _weakmt)
            collisions[item][neighbor] = {x=dx, y=dy}
          end

          tested[item][neighbor] = true
        end
      end
    end
  end

  return collisions
end

-- fires bump.beginCollision with the appropiate parameters
local function _invokeBeginCollision(collisions)
  for item,neighbors in pairs(collisions) do
    if _items[item] then
      for neighbor, d in pairs(neighbors) do
        if _items[neighbor] then
          bump.beginCollision(item, neighbor, d.x, d.y)
          if _prevCollisions[item] then _prevCollisions[item][neighbor] = nil end
        end
      end
    end
  end
end

-- fires bump.endCollision with the appropiate parameters
local function _invokeEndCollision()
  for item,neighbors in pairs(_prevCollisions) do
    if _items[item] then
      for neighbor, d in pairs(neighbors) do
        if _items[neighbor] then
          bump.endCollision(item, neighbor, d.x, d.y)
        end
      end
    end
  end
end


-- public interface

function bump.initialize(cellSize)
  _cellSize = cellSize or 32
  _cells          = setmetatable({}, _weakmt)
  _items          = setmetatable({}, _weakmt)
  _prevCollisions = setmetatable({}, _weakmt)
end

function bump.beginCollision(item1, item2, vx, vy)
end

function bump.endCollision(item1, item2)
end

function bump.getBBox(item)
  return item:getBBox()
end

function bump.add(item)
  _updateItem(item, {})
end

function bump.remove(item)
  unlink(item, _items[item])
  _items[item] = nil
end

function bump.check()
  _updateItems()

  local collisions = _calculateCollisions()

  _invokeBeginCollision(collisions)
  _invokeEndCollision()

  _prevCollisions = collisions
end

bump.initialize(32)


return bump
