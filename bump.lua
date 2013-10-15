local bump = {}

local abs, floor, ceil = math.abs, math.floor, math.ceil

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
  assertType('number', w, 'w')
  assertType('number', h, 'h')
end

local World = {}

local function liangBarsky(l,t,w,h, x1,y1,x2,y2, t0,t1)
  local dx, dy  = x2-x1, y2-y1
  local p, q, r

  for side = 1,4 do
    if     side == 1 then p,q = -dx, x1 - l
    elseif side == 2 then p,q =  dx, l + w - x1
    elseif side == 3 then p,q = -dy, y1 - t
    else                  p,q =  dy, t + h - y1
    end

    if p == 0 then
      if q < 0 then return nil end
    else
      r = q / p
      if p < 0 then
        if     r > t1 then return nil
        elseif r > t0 then t0 = r
        end
      else -- p > 0
        if     r < t0 then return nil
        elseif r < t1 then t1 = r
        end
      end
    end
  end

  return t0, t1
end

local function getMinkowskyDiff(l1,t1,w1,h1, l2,t2,w2,h2)
  return l2 - l1 - w1,
         t2 - t1 - h1,
         w1 + w2,
         h1 + h2
end

local function containsPoint(l,t,w,h, x,y)
  return x > l and y > t and x < l + w and y < t + h
end

local function nearest(x, a, b)
  return abs(a - x) < abs(b - x) and a or b
end

local function getNearestPointInPerimeter(l,t,w,h, x,y)
  return nearest(x, l, l+w), nearest(y, t, t+h)
end

local function sortByTi(a,b) return a.ti < b.ti end

local function collideBoxes(l1,t1,w1,h1, l2,t2,w2,h2, vx,vy)
  local ti

  local l,t,w,h = getMinkowskyDiff(l1-vx,t1-vy,w1,h1, l2, t2, w2, h2)

  if containsPoint(l,t,w,h, 0,0) then -- boxes are tunneling
    local dx, dy = getNearestPointInPerimeter(l,t,w,h, 0,0)
    return dx-vx, dy-vy, 0, false
  else                                -- boxes are not tunneling
    local t0,t1 = liangBarsky(l,t,w,h, 0,0,vx,vy, 0, 1)
    if     t0 and t0 > 0 and t0 < 1 then ti = t0
    elseif t1 and t1 > 0 and t1 < 1 then ti = t1
    end
    if ti then
      return vx*ti - vx, vy*ti - vy, ti, true
    end
  end
end

local function addItemToCell(self, item, cx, cy)
  self.rows[cy] = self.rows[cy] or setmetatable({}, {__mode = 'v'})
  local row = self.rows[cy]
  row[cx] = row[cx] or {itemCount = 0, items = setmetatable({}, {__mode = 'k'})}
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
end

function World:add(item, l,t,w,h)
  assertIsBox(l,t,w,h)

  self.items[item] = {l=l,t=t,w=w,h=h}

  local cl,ct,cw,ch = self:toCellBox(l,t,w,h)
  for cy = ct, ct+ch do
    for cx = cl, cl+cw do
      addItemToCell(self, item, cx, cy)
    end
  end

  return self:check(item)
end

function World:move(item, l,t,w,h)
  assertIsBox(l,t,w,h)

  local previousBox = self.items[item]

  if not previousBox then
    error('Item ' .. tostring(item) .. ' must be added to the world before being moved. Use world:add(item, l,t,w,h) to add it first.')
  end

  local pl, pt, pw, ph  = previousBox.l, previousBox.t, previousBox.w, previousBox.h
  local pcx, pcy        = pl + pw/2, pt + ph/2
  local cx, cy          = l + w/2, t + h/2
  local vx, vy          = cx - pcx, cy - pcy

  self.items[item] = {l=l,t=t,w=w,h=h}

  return self:check(item, vx, vy)
end

function World:check(item, vx, vy)
  vx, vy = vx or 0, vy or 0
  local box = self.items[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being checked for collisions. Use world:add(item, l,t,w,h) to add it first.')
  end
  local l,t,w,h = box.l, box.t, box.w, box.h
  local collisions, len = {}, 0

  for other, oBox in pairs(self.items) do
    if other ~= item then
      local dx, dy, ti, tunneling = collideBoxes(l,t,w,h, oBox.l, oBox.t, oBox.w, oBox.h, vx, vy)
      if dx then
        len = len + 1
        collisions[len] = {
          item       = other,
          dx         = dx,
          dy         = dy,
          ti         = ti,
          tunneling  = tunneling
        }
      end
    end
  end

  table.sort(collisions, sortByTi)

  return collisions, len
end

function World:remove(item)
  local box = self.items[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being removed. Use world:add(item, l,t,w,h) to add it first.')
  end
  self.items[item] = nil
  local cl,ct,cw,ch = self:toCellBox(box.l,box.t,box.w,box.h)
  for cy = ct, ct+ch do
    for cx = cl, cl+cw do
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

function World:toCell(x,y)
  local cellSize = self.cellSize
  return floor(x / cellSize) + 1, floor(y / cellSize) + 1
end

function World:toCellBox(l,t,w,h)
  if not (l and t and w and h) then return nil end
  local cl,ct = self:toCell(l, t)
  local cellSize = self.cellSize
  local cr,cb = ceil((l+w) / cellSize), ceil((t+h) / cellSize)
  return cl, ct, cr-cl, cb-ct
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  assertIsPositiveNumber(cellSize, 'cellSize')
  return setmetatable(
    { cellSize = cellSize,
      items = {},
      rows = {},
      nonEmptyCells = {}
    },
    {__index = World }
  )
end

bump.aabb = {
  getMinkowskyDiff = getMinkowskyDiff,
  liangBarsky = liangBarsky
}


return bump
