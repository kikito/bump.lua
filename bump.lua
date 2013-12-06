local bump = {}

local abs, floor, ceil, min = math.abs, math.floor, math.ceil, math.min

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

local function isArray(tbl)
end

-----------------------------------------------

local function getLiangBarskyIndices(l,t,w,h, x1,y1,x2,y2, t0,t1)
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
  return x >= l and y >= t and x <= l + w and y <= t + h
end

local function nearest(x, a, b)
  return abs(a - x) < abs(b - x) and a or b
end

local function getNearestPointInPerimeter(l,t,w,h, x,y)
  return nearest(x, l, l+w), nearest(y, t, t+h)
end

-----------------------------------------------

local World = {}
local World_mt = {__index = World}

local function sortByTi(a,b) return a.ti < b.ti end

local function collideBoxes(b1, b2, vx,vy)
  local l1,t1,w1,h1 = b1.l, b1.t, b1.w, b1.h
  local l2,t2,w2,h2 = b2.l, b2.t, b2.w, b2.h
  local l,t,w,h = getMinkowskyDiff(l1-vx,t1-vy,w1,h1, l2, t2, w2, h2)

  if containsPoint(l,t,w,h, 0,0) then -- old a was intersecting with b
    local dx, dy = getNearestPointInPerimeter(l,t,w,h, 0,0)
    dx, dy = dx - vx, dy - vy
    if dx == 0 and dy == 0 then return 0, 0, math.huge, 'touch' end
    return dx, dy, 0, 'intersection'
  else                                -- old a was not intersecting with b
    local ti
    local ti0,ti1 = getLiangBarskyIndices(l,t,w,h, 0,0,vx,vy, 0, 1)
    if     ti0 and 0 < ti0 and ti0 < 1 then ti = ti0
    elseif ti1 and 0 < ti1 and ti1 < 1 then ti = ti1
    elseif ti0 == 1 or ti1 == 1 then ti = 1
    end
    if ti then                        -- a tunnels into B
      if ti == 1 then return 0, 0, math.huge, 'touch' end
      return vx*ti - vx, vy*ti - vy, ti, 'tunnel'
    end
  end
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

function World:add(item, l,t,w,h, options)
  local box = self.items[item]
  if box then
    error('Item ' .. tostring(item) .. ' added to the world twice.')
  end
  assertIsBox(l,t,w,h)

  self.items[item] = {l=l,t=t,w=w,h=h}

  local cl,ct,cw,ch = self:toCellBox(l,t,w,h)
  for cy = ct, ct+ch-1 do
    for cx = cl, cl+cw-1 do
      addItemToCell(self, item, cx, cy)
    end
  end

  return self:check(item, options)
end

function World:move(item, l,t,w,h, options)
  local box = self.items[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being moved. Use world:add(item, l,t,w,h) to add it first.')
  end

  w,h = w or box.w, h or box.h

  assertIsBox(l,t,w,h)

  if box.l ~= l or box.t ~= t or box.w ~= w or box.h ~= h then
    self:remove(item)
    self:add(item, l,t,w,h, options)
    options = options or {}
    if box.w ~= w or box.h ~= h then
      local prev_cx, prev_cy = box.l + box.w/2, box.t + box.h/2
      options.prev_l, options.prev_t = prev_cx - w/2, prev_cy - h/2
    else
      options.prev_l, options.prev_t = box.l, box.t
    end
  end

  return self:check(item, options)
end

function World:getBox(item)
  local box = self.items[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before getting its box. Use world:add(item, l,t,w,h) to add it first.')
  end
  return box.l, box.t, box.w, box.h
end

function World:check(item, options)
  local prev_l, prev_t, filter, skip_collisions, opt_visited
  if options then
    prev_l, prev_t, filter, skip_collisions, opt_visited =
      options.prev_l, options.prev_t, options.filter, options.skip_collisions, options.visited
  end
  local box = self.items[item]
  if not box then
    error('Item ' .. tostring(item) .. ' must be added to the world before being checked for collisions. Use world:add(item, l,t,w,h) to add it first.')
  end

  if skip_collisions then return {} end

  local visited = {[item] = true}
  if type(opt_visited) == 'table' then
    for _,v in pairs(opt_visited) do visited[v] = true end
  end
  local l,t,w,h = box.l, box.t, box.w, box.h
  prev_l, prev_t = prev_l or l, prev_t or t

  local vx, vy = l - prev_l, t - prev_t
  local collisions, len = {}, 0


  -- FIXME this could probably be done with less cells using a polygon raster over the cells instead of a
  -- bounding box of the whole movement
  local tl,tt,tw,th --touched cells, taking vx and vy into account
  if vx > 0 then
    tl, tw = l - vx, w + vx
  else
    tl, tw = l, w - vx
  end
  if vy > 0 then
    tt, th = t - vy, h + vy
  else
    tt, th = t, h - vy
  end

  local cl,ct,cw,ch = self:toCellBox(tl,tt,tw,th)

  for cy=ct,ct+ch-1 do
    local row = self.rows[cy]
    if row then
      for cx=cl,cl+cw-1 do
        local cell = row[cx]
        if cell and cell.itemCount > 0 then -- no cell.itemCount > 1 because tunneling
          for other,_ in pairs(cell.items) do
            if not visited[other] then
              visited[other] = true
              if not (filter and filter(other)) then
                local oBox = self.items[other]
                local dx, dy, ti, kind = collideBoxes(box, oBox, vx, vy)
                if dx then
                  len = len + 1
                  collisions[len] = {
                    item = other,
                    dx   = dx,
                    dy   = dy,
                    ti   = ti,
                    kind = kind
                  }
                end
              end
            end
          end
        end
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

function World:toWorldBox(cl, ct, cw, ch)
  local cellSize = self.cellSize
  local l,t = self:toWorld(cl, ct)
  return l,t, cw * cellSize, ch * cellSize
end

function World:toCell(x,y)
  local cellSize = self.cellSize
  return floor(x / cellSize) + 1, floor(y / cellSize) + 1
end

function World:toCellBox(l,t,w,h)
  if not (l and t and w and h) then return nil end
  local cellSize = self.cellSize
  local cl,ct    = self:toCell(l, t)
  local cr,cb    = ceil((l+w) / cellSize), ceil((t+h) / cellSize)
  return cl, ct, cr-cl+1, cb-ct+1
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  assertIsPositiveNumber(cellSize, 'cellSize')
  return setmetatable(
    { cellSize       = cellSize,
      items          = {},
      rows           = {},
      nonEmptyCells  = {}
    },
    World_mt
  )
end

bump.geom = {
  getMinkowskyDiff      = getMinkowskyDiff,
  getLiangBarskyIndices = getLiangBarskyIndices
}


return bump
