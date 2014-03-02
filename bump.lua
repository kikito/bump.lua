local bump = {
  _VERSION     = 'bump v2.0.0',
  _URL         = 'https://github.com/kikito/bump.lua',
  _DESCRIPTION = 'A collision detection library for Lua',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

------------------------------------------
-- Auxiliary functions
------------------------------------------

local abs, floor, ceil, min, max = math.abs, math.floor, math.ceil, math.min, math.max

local function clamp(x, lower, upper)
  return max(lower, min(upper, x))
end

local function sign(x)
  if x > 0 then return 1 end
  if x == 0 then return 0 end
  return -1
end

local function nearest(x, a, b)
  if abs(a - x) < abs(b - x) then return a else return b end
end

local function sortByTi(a,b) return a.ti < b.ti end

local function assertType(desiredType, value, name)
  if type(value) ~= desiredType then
    error(name .. ' must be a ' .. desiredType .. ', but was ' .. tostring(value) .. '(a ' .. type(value) .. ')')
  end
end

local function assertIsPositiveNumber(value, name)
  if type(value) ~= 'number' or value <= 0 then
    error(name .. ' must be a positive integer, but was ' .. tostring(value) .. '(' .. type(value) .. ')')
  end
end

local function assertIsBox(l,t,w,h)
  assertType('number', l, 'l')
  assertType('number', t, 'w')
  assertIsPositiveNumber(w, 'w')
  assertIsPositiveNumber(h, 'h')
end

------------------------------------------
-- Axis-aligned bounding box functions
------------------------------------------

local function aabb_getNearestCorner(l,t,w,h, x, y)
  return nearest(x, l, l+w), nearest(y, t, t+h)
end

-- This is a generalized implementation of the liang-barsky algorithm, which also returns
-- the normals of the sides where the segment intersects
local function aabb_getSegmentIntersectionIndices(l,t,w,h, x1,y1,x2,y2, t0,t1)
  t0, t1 = t0 or 0, t1 or 1
  local dx, dy = x2-x1, y2-y1
  local nx, ny
  local nx0, ny0, nx1, ny1 = -1,0,-1,0
  local p, q, r

  for side = 1,4 do
    if     side == 1 then nx,ny,p,q = -1,  0, -dx, x1 - l     -- left
    elseif side == 2 then nx,ny,p,q =  1,  0,  dx, l + w - x1 -- right
    elseif side == 3 then nx,ny,p,q =  0, -1, -dy, y1 - t     -- top
    else                  nx,ny,p,q =  0,  1,  dy, t + h - y1 -- bottom
    end

    if p == 0 then
      if q <= 0 then return nil end
    else
      r = q / p
      if p < 0 then
        if     r > t1 then return nil
        elseif r > t0 then t0,nx0,ny0 = r,nx,ny
        end
      else -- p > 0
        if     r < t0 then return nil
        elseif r < t1 then t1,nx1,ny1 = r,nx,ny
        end
      end
    end
  end

  return t0,t1, nx0,ny0, nx1,ny1
end

-- Calculates the minkowsky difference between 2 aabbs, which is another aabb
local function aabb_getDiff(l1,t1,w1,h1, l2,t2,w2,h2)
  return l2 - l1 - w1,
         t2 - t1 - h1,
         w1 + w2,
         h1 + h2
end

local function aabb_containsPoint(l,t,w,h, x,y)
  return x > l and y > t and x < l + w and y < t + h
end

local function aabb_isIntersecting(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l2 < l1+w1 and
         t1 < t2+h2 and t2 < t1+h1
end

------------------------------------------
-- Collision
------------------------------------------

local Collision = {}
local Collision_mt = {__index = Collision}

function Collision:resolve()
  local b1, b2          = self.itemBox, self.otherBox
  local vx, vy          = self.vx, self.vy
  local l1,t1,w1,h1     = b1.l, b1.t, b1.w, b1.h
  local l2,t2,w2,h2     = b2.l, b2.t, b2.w, b2.h
  local l,t,w,h         = aabb_getDiff(l1,t1,w1,h1, l2,t2,w2,h2)

  if aabb_containsPoint(l,t,w,h, 0,0) then -- b1 was intersecting b2
    self.is_intersection = true
    local px, py = aabb_getNearestCorner(l,t,w,h, 0, 0)
    local wi, hi = min(w1, abs(px)), min(h1, abs(py)) -- area of intersection
    self.ti      = -wi * hi -- ti is the negative area of intersection
    self.nx, self.ny = 0,0
    self.ml, self.mt, self.mw, self.mh = l,t,w,h
    return self
  else
    local ti,_,nx,ny = aabb_getSegmentIntersectionIndices(l,t,w,h, 0,0,vx,vy)
    -- b1 tunnels into b2 while it travels
    if ti and ti < 1 then
      -- local dx, dy = vx*ti-vx, vy*ti-vy
      self.is_intersection = false
      self.ti   = ti
      self.nx   = nx
      self.ny   = ny
      self.ml, self.mt, self.mw, self.mh = l,t,w,h
      return self
    end
  end
end

function Collision:getTouch()
  local vx,vy = self.vx, self.vy
  local itemBox = self.itemBox
  assert(self.is_intersection ~= nil, 'unknown collision kind. Have you called :resolve()?')

  local tl, tt, nx, ny

  if self.is_intersection then

    if vx == 0 and vy == 0 then
      -- intersecting and not moving - use minimum displacement vector
      local px,py = aabb_getNearestCorner(self.ml, self.mt, self.mw, self.mh, 0,0)
      if abs(px) < abs(py) then py = 0 else px = 0 end
      tl, tt, nx, ny = itemBox.l + px, itemBox.t + py, sign(px), sign(py)
    else
      -- intersecting and moving - move in the opposite direction
      local ti,_,nx2,ny2 = aabb_getSegmentIntersectionIndices(self.ml,self.mt,self.mw,self.mh, 0,0,vx,vy, -math.huge, 1)
      tl, tt, nx, ny = itemBox.l + vx * ti, itemBox.t + vy * ti, nx2, ny2
    end

  else -- tunnel
    tl, tt, nx, ny = itemBox.l + vx * self.ti, itemBox.t + vy * self.ti, self.nx, self.ny
  end

  return tl, tt, nx, ny
end

function Collision:getSlide()
  local tl, tt, nx, ny  = self:getTouch()
  local sl, st, sx, sy  = tl, tt, 0, 0

  if self.vx ~= 0 or self.vy ~= 0 then
    if nx == 0 then
      sl = self.target_l
      sx = sl - tl
    else
      st = self.target_t
      sy = st - tt
    end
  end

  return tl, tt, nx, ny, sl, st, sx, sy
end

function Collision:getBounce()
  local tl, tt, nx, ny  = self:getTouch()
  local bl, bt, bx,by = tl, tt, 0,0

  if self.vx ~= 0 or self.vy ~= 0 then
    bx, by = self.target_l - tl, self.target_t - tt
    if nx == 0 then by = -by else bx = -bx end
    bl, bt = tl + bx, tt + by
  end

  return tl, tt, nx, ny, bl, bt, bx, by
end

------------------------------------------
-- World
------------------------------------------

local function toCellBox(world, l,t,w,h)
  local cellSize = world.cellSize
  local cl,ct    = world:toCell(l, t)
  local cr,cb    = ceil((l+w) / cellSize), ceil((t+h) / cellSize)
  return cl, ct, cr-cl+1, cb-ct+1
end

local function addItemToCell(self, item, cx, cy)
  self.rows[cy] = self.rows[cy] or setmetatable({}, {__mode = 'v'})
  local row = self.rows[cy]
  row[cx] = row[cx] or {itemCount = 0, x = cx, y = cy, items = setmetatable({}, {__mode = 'k'})}
  local cell = row[cx]
  self.nonEmptyCells[cell] = true
  if not cell.items[item] then
    cell.items[item] = true
    cell.itemCount = cell.itemCount + 1
  end
end

local function removeItemFromCell(self, item, cx, cy)
  local row = self.rows[cy]
  if not row or not row[cx] or not row[cx].items[item] then return false end

  local cell = row[cx]
  cell.items[item] = nil
  cell.itemCount = cell.itemCount - 1
  if cell.itemCount == 0 then
    self.nonEmptyCells[cell] = nil
  end
  return true
end

local function getDictItemsInCellBox(self, cl,ct,cw,ch)
  local items_dict = {}
  for cy=ct,ct+ch-1 do
    local row = self.rows[cy]
    if row then
      for cx=cl,cl+cw-1 do
        local cell = row[cx]
        if cell and cell.itemCount > 0 then -- no cell.itemCount > 1 because tunneling
          for item,_ in pairs(cell.items) do
            items_dict[item] = true
          end
        end
      end
    end
  end

  return items_dict
end

local function getSegmentStep(cellSize, ct, t1, t2)
  local v = t2 - t1
  if     v > 0 then
    return  1,  cellSize / v, ((ct + v) * cellSize - t1) / v
  elseif v < 0 then
    return -1, -cellSize / v, ((ct + v - 1) * cellSize - t1) / v
  else
    return 0, math.huge, math.huge
  end
end

local function getCellsTouchedBySegment(self, x1,y1,x2,y2)

  local cx1,cy1        = self:toCell(x1,y1)
  local cx2,cy2        = self:toCell(x2,y2)
  local stepX, dx, tx  = getSegmentStep(self.cellSize, cx1, x1, x2)
  local stepY, dy, ty  = getSegmentStep(self.cellSize, cy1, y1, y2)
  local maxLen         = 2*(abs(cx2-cx1) + abs(cy2-cy1))
  local cx,cy          = cx1,cy1
  local coords, len = {{cx=cx,cy=cy}}, 1

  -- maxLen is a safety guard. In some cases this algorithm loops inf on the last step without it
  while len <= maxLen and (cx~=cx2 or y~=cy2) do
    if tx < ty then
      tx, cx, len = tx + dx, cx + stepX, len + 1
      coords[len] = {cx=cx,cy=cy}
    elseif ty < tx then
      ty, cy, len = ty + dy, cy + stepY, len + 1
      coords[len] = {cx=cx,cy=cy}
    else -- tx == ty
      local ntx,nty = tx+dx, dy+dy
      local ncx,ncy = cx+stepX, cy+stepY

      len = len + 1
      coords[len] = {cx=ncx,cy=cy}
      len = len + 1
      coords[len] = {cx=cx,cy=ncy}

      tx,ty = ntx,nty
      cx,cy = ncx,ncy
    end
  end

  local coord, row, cell
  local visited = {}
  local cells, cellsLen = {}, 0
  for i=1,len do
    coord = coords[i]
    row   = self.rows[coord.cy]
    if row then
      cell = row[coord.cx]
      if cell then
        if not visited[cell] then
          visited[cell] = true
          cellsLen = cellsLen + 1
          cells[cellsLen] = cell
        end
      end
    end
  end

  return cells, cellsLen
end


local World = {}
local World_mt = {__index = World}

function World:add(item, l,t,w,h, options)
  local box = self.boxes[item]
  if box then
    error('Item ' .. tostring(item) .. ' added to the world twice.')
  end
  assertIsBox(l,t,w,h)

  self.boxes[item] = {l=l,t=t,w=w,h=h}

  local cl,ct,cw,ch = toCellBox(self, l,t,w,h)
  for cy = ct, ct+ch-1 do
    for cx = cl, cl+cw-1 do
      addItemToCell(self, item, cx, cy)
    end
  end

  return self:check(item, options)
end

function World:move(item, l,t,w,h, options)
  local box = self.boxes[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being moved. Use world:add(item, l,t,w,h) to add it first.')
  end
  w,h = w or box.w, h or box.h

  assertIsBox(l,t,w,h)

  options        = options or {}
  options.target_l = l
  options.target_t = t

  if box.w ~= w or box.h ~= h then
    self:remove(item)
    self:add(item, box.l, box.t, w,h, {skip_collisions = true})
  end

  local collisions, len = self:check(item, options)

  if box.l ~= l or box.t ~= t then
    self:remove(item)
    self:add(item, l,t,w,h, {skip_collisions = true})
  end

  return collisions, len
end

function World:getBox(item)
  local box = self.boxes[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before getting its box. Use world:add(item, l,t,w,h) to add it first.')
  end
  return box.l, box.t, box.w, box.h
end

function World:check(item, options)
  local target_l, target_t, filter, skip_collisions, opt_visited
  if options then
    target_l, target_t, filter, skip_collisions, opt_visited =
      options.target_l, options.target_t, options.filter, options.skip_collisions, options.visited
  end
  local box = self.boxes[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being checked for collisions. Use world:add(item, l,t,w,h) to add it first.')
  end

  local collisions, len = {}, 0

  if not skip_collisions then
    local visited = {[item] = true}
    if opt_visited then
      for _,v in pairs(opt_visited) do visited[v] = true end
    end
    local l,t,w,h = box.l, box.t, box.w, box.h
    target_l, target_t = target_l or l, target_t or t


    -- TODO this could probably be done with less cells using a polygon raster over the cells instead of a
    -- bounding box of the whole movement. Conditional to building a queryPolygon method
    local tl, tt = min(target_l, l),       min(target_t, t)
    local tr, tb = max(target_l + w, l+w), max(target_t + h, t+h)
    local tw, th = tr-tl, tb-tt

    local cl,ct,cw,ch = toCellBox(self, tl,tt,tw,th)

    local dictItemsInCellBox = getDictItemsInCellBox(self, cl,ct,cw,ch)

    for other,_ in pairs(dictItemsInCellBox) do
      if not visited[other] then
        visited[other] = true
        if not (filter and filter(other)) then
          local oBox = self.boxes[other]
          local col  = bump.newCollision(item, other, box, oBox, target_l, target_t):resolve()
          if col then
            len = len + 1
            collisions[len] = col
          end
        end
      end
    end

    table.sort(collisions, sortByTi)
  end

  return collisions, len
end

function World:remove(item)
  local box = self.boxes[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being removed. Use world:add(item, l,t,w,h) to add it first.')
  end
  self.boxes[item] = nil
  local cl,ct,cw,ch = toCellBox(self, box.l,box.t,box.w,box.h)
  for cy = ct, ct+ch-1 do
    for cx = cl, cl+cw-1 do
      removeItemFromCell(self, item, cx, cy)
    end
  end
end

function World:countCells()
  local count = 0
  for _,row in pairs(self.rows) do
    for _,_ in pairs(row) do
      count = count + 1
    end
  end
  return count
end

function World:toWorld(cx, cy)
  local cellSize = self.cellSize
  return (cx - 1)*cellSize, (cy-1)*cellSize
end

function World:toCell(x,y)
  local cellSize = self.cellSize
  return floor(x / cellSize) + 1, floor(y / cellSize) + 1
end

function World:queryBox(l,t,w,h)

  local cl,ct,cw,ch = toCellBox(self, l,t,w,h)
  local dictItemsInCellBox = getDictItemsInCellBox(self, cl,ct,cw,ch)

  local items, len = {}, 0

  local box
  for item,_ in pairs(dictItemsInCellBox) do
    box = self.boxes[item]
    if aabb_isIntersecting(l,t,w,h, box.l, box.t, box.w, box.h) then
      len = len + 1
      items[len] = item
    end
  end

  return items, len
end

function World:queryPoint(x,y)
  local cx,cy = self:toCell(x,y)
  local dictItemsInCellBox = getDictItemsInCellBox(self, cx,cy,1,1)

  local items, len = {}, 0

  local box
  for item,_ in pairs(dictItemsInCellBox) do
    box = self.boxes[item]
    if aabb_containsPoint(box.l, box.t, box.w, box.h, x, y) then
      len = len + 1
      items[len] = item
    end
  end

  return items, len
end

function World:querySegment(x1,y1,x2,y2)
  local cells, len = getCellsTouchedBySegment(self, x1,y1,x2,y2)
  local cell, box, l,t,w,h, t0, t1
  local visited, items, itemsLen = {},{},0
  for i=1,len do
    cell = cells[i]
    for item in pairs(cell.items) do
      if not visited[item] then
        visited[item] = true
        box = self.boxes[item]
        l,t,w,h = box.l,box.t,box.w,box.h

        t0,t1 = aabb_getSegmentIntersectionIndices(l,t,w,h, x1,y1, x2,y2, 0, 1)
        if t0 and ((0 < t0 and t0 < 1) or (0 < t1 and t1 < 1)) then
          -- the sorting is according to the t of an infinite line, not the segment
          t0,t1 = aabb_getSegmentIntersectionIndices(l,t,w,h, x1,y1, x2,y2, -math.huge, math.huge)
          itemsLen = itemsLen + 1
          items[itemsLen] = {item=item, ti=min(t0,t1)}
        end
      end
    end
  end
  table.sort(items, sortByTi)
  for i=1,itemsLen do
    items[i] = items[i].item
  end
  return items, itemsLen
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  assertIsPositiveNumber(cellSize, 'cellSize')
  return setmetatable(
    { cellSize       = cellSize,
      boxes          = {},
      rows           = {},
      nonEmptyCells  = {}
    },
    World_mt
  )
end

bump.newCollision = function(item, other, itemBox, otherBox, target_l, target_t)
  return setmetatable({
    item      = item,
    other     = other,
    itemBox   = itemBox,
    otherBox  = otherBox,
    target_l  = target_l,
    target_t  = target_t,
    vx        = target_l - itemBox.l,
    vy        = target_t - itemBox.t
  }, Collision_mt)
end

return bump
