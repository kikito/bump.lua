-- bump.lua - v0.1 (2012-05)
-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local bump = {}

local _weakmt = {mode = 'k'}
local abs = math.abs

local _items, _collisions, _prevCollisions, _cellSize, _cells

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

local function _getNeighbors(item)
  local neighbors, len = {}, 0
  for neighbor,_ in pairs(_items) do
    if neighbor ~= item then
      len = len + 1
      neighbors[len] = neighbor
    end
  end
  return neighbors, len
end

local function _calculateCollisions()
  local collisions = setmetatable({}, _weakmt)

  local getBBox = bump.getBBox
  local l1,t1,w1,h1
  local neighbor, neighbors, neighborsLength
  local collision, dx, dy

  for item,_ in pairs(_items) do
    l1, t1, w1, h1 = bump.getBBox(item)
    neighbors, neighborsLength = _getNeighbors(item)
    for i=1, neighborsLength do
      neighbor = neighbors[i]
      assert(neighbor, i)

      if not (collisions[neighbor] and collisions[neighbor][item]) then
        collision, dx, dy = _boxCollision(l1,t1,w1,h1, getBBox(neighbor))

        if collision then
          collisions[item] = collisions[item] or setmetatable({}, _weakmt)
          collisions[item][neighbor] = {x=dx, y=dy}
        end

      end
    end
  end

  return collisions
end

local function _invokeStartCollisionCallbacks(collisions)
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

local function _invokeStopCollisionCallbacks()
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
  _items[item] = true
end

function bump.remove(item)
  _items[item] = nil
end

function bump.check()
  local collisions = _calculateCollisions(collisions)

  _invokeStartCollisionCallbacks(collisions)
  _invokeStopCollisionCallbacks()

  _prevCollisions = collisions
end

bump.initialize(32)


return bump
