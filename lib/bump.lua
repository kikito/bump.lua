-- bump.lua - v0.1 (2012-05)
-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local bump = {}

local _weakKeys   = {__mode = 'k'}
local _weakValues = {__mode = 'v'}
local abs, floor, min = math.abs, math.floor, math.min

local function newWeakTable(t, mt)
  return setmetatable(t or {}, mt or _weakKeys)
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

-- given a world coordinate, return the coordinates of the cell that would contain it
local function _toGrid(wx, wy)
  return floor(wx / bump._cellSize) + 1, floor(wy / bump._cellSize) + 1
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
  bump._cells[y]    = bump._cells[y]    or newWeakTable({}, _weakValues)
  bump._cells[y][x] = bump._cells[y][x] or newWeakTable({itemCount = 0, items = newWeakTable()})
  return bump._cells[y][x]
end

-- parses the cells touching one item, and removes the item from their list of items
-- does not create new cells
local function _unlink(item, info)
  info = info or bump._items[item]
  if info then
    local row, cell
    for y=info.gt, info.gt+info.gh do
      row = bump._cells[y]
      if row then
        for x=info.gl, info.gl+info.gw do
          cell = row[x]
          if cell then
            cell.items[item] = nil
            cell.itemCount = cell.itemCount - 1
            if cell.itemCount == 0 then
              bump._occupiedCells[cell] = nil
            end
          end
        end
      end
    end
  end
end

-- parses all the cells that touch one item, adding the item to their list of items
-- creates cells if they don't exist
local function _link(item, gl, gt, gw, gh)
  local cell
  for y=gt, gt+gh do
    for x=gl, gl+gw do
     cell = _getCell(x,y)
     cell.items[item] = true
     cell.itemCount = cell.itemCount + 1
     bump._occupiedCells[cell] = true
    end
  end
end

-- updates the information bump has about one item - its boundingbox, and containing cells
local function _updateItem(item)
  local info = bump._items[item] or {}

  -- if the new bounding box is different from the stored one
  local l,t,w,h = bump.getBBox(item)
  if l ~= info.l or t ~= info.t or w ~= info.w or h ~= info.h then

    local gl, gt, gw, gh = _toGridBox(l, t, w, h)
    if gl ~= info.gl or gt ~= info.gt or gw ~= info.gw or gh ~= info.gh then
      -- remove this item from all the cells that used to contain it
      _unlink(item)
      -- then add it to the new cells
      _link(item, gl, gt, gw, gh)
      -- and update the grid info
      info.gl, info.gt, info.gw, info.gh = gl, gt, gw, gh
    end

    -- update the bounding box info
    info.l, info.t, info.w, info.h = l, t, w, h
    bump._items[item] = info
  end
end

-- updates the cell information (what cells every item is stepping in) - this takes care of moving items
local function _updateItems()
  for item,_ in pairs(bump._items) do
    _updateItem(item)
  end
end

-- Returns a new table containing references to all the calculated collisions
-- structure: { [item1] = { [item2] = {x=1,y=2} } }
-- so collisions[item1][item] = {x=1, y=2}
local function _calculateCollisions()
  _updateItems() -- refresh moving items info

  local collisions = newWeakTable()

  local l, t, w, h, gh, gt, gw, gh
  local row, cell
  local neighbor, ninfo
  local collision, dx, dy
  local tested = {}

  -- for each item stored in bump
  for item, info in pairs(bump._items) do
    l, t, w, h = info.l, info.t, info.w, info.h         -- bounding box, in world coordinates
    gl, gt, gw, gh = info.gl, info.gt, info.gw, info.gh -- indexes of the cells containing the bounding box
    tested[item] = {}

    -- parse the cells intersecting with item's boundingbox
    for y=gt, gt + gh do
      row = bump._cells[y]
      if row then
        for x=gl, gl + gw do
          cell = row[x]
          if cell and cell.itemCount > 0 then
            -- check if there are any neighbors on that group of cells
            for neighbor,_ in pairs(cell.items) do
              -- skip this neighbor if:
              -- a) It's the same item whose neighbors we are checking out
              -- b) The opposite collision (neighbor-item instead of item-neighbor) has already been calculated
              -- c) The pair item, neighbor returns true in bump.shouldCollide
              if neighbor ~= item
              and not (tested[neighbor] and tested[neighbor][item])
              and bump.shouldCollide(item, neighbor)
              then
                -- store the collision, if it happened
                ninfo = bump._items[neighbor]
                collision, dx, dy = _boxCollision(l, t, w, h, ninfo.l, ninfo.t, ninfo.w, ninfo.h)

                if collision then
                  collisions[item] = collisions[item] or newWeakTable()
                  collisions[item][neighbor] = {x=dx, y=dy}
                end

                -- mark the couple item-neighbor as tested, so the inverse is not calculated
                tested[item][neighbor] = true
              end
            end
          end
        end
      end
    end
  end

  return collisions
end

-- fires bump.Collision with the appropiate parameters
local function _invokeCollision(collisions)
  for item,neighbors in pairs(collisions) do
    if bump._items[item] then
      for neighbor, d in pairs(neighbors) do
        if bump._items[neighbor] then
          bump.collision(item, neighbor, d.x, d.y)
          if bump._prevCollisions[item] then bump._prevCollisions[item][neighbor] = nil end
        end
      end
    end
  end
end

-- fires bump.endCollision with the appropiate parameters
local function _invokeEndCollision()
  for item,neighbors in pairs(bump._prevCollisions) do
    if bump._items[item] then
      for neighbor, d in pairs(neighbors) do
        if bump._items[neighbor] then
          bump.endCollision(item, neighbor, d.x, d.y)
        end
      end
    end
  end
end


-- public interface

function bump.initialize(cellSize)
  bump._cellSize       = cellSize or 32
  bump._cells          = newWeakTable()
  bump._occupiedCells  = {} -- stores strong references to cells so that they are not gc'ed
  bump._items          = newWeakTable()
  bump._prevCollisions = newWeakTable()
end

function bump.collision(item1, item2, vx, vy)
end

function bump.endCollision(item1, item2)
end

function bump.shouldCollide(item1, item2)
  return true
end

function bump.getBBox(item)
  return item:getBBox()
end

function bump.add(item)
  _updateItem(item, {})
end

function bump.remove(item)
  _unlink(item, bump._items[item])
  bump._items[item] = nil
end

function bump.check()
  local collisions = _calculateCollisions()

  _invokeCollision(collisions)
  _invokeEndCollision()

  bump._prevCollisions = collisions
end

function bump.padVelocity(maxdt, vx, vy)
  if maxdt == 0 or (vx == 0 and vy == 0) then return 0,0 end
  local maxV = bump._cellSize/maxdt
  if abs(vx) > maxV then vx = vx < 0 and -maxV or maxV end
  if abs(vy) > maxV then vy = vy < 0 and -maxV or maxV end
  return vx, vy
end

bump.initialize(32)


return bump
