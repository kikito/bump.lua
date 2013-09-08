local bump = {}

local abs = math.abs

local function checkType(desiredType, value, name)
  if type(value) ~= desiredType then
    error(name .. ' must be a ' .. desiredType .. ', but was ' .. tostring(value) .. '(a ' .. type(value) .. ')')
  end
end

local function checkPositiveNumber(value, name)
  if type(value) ~= 'number' or value <= 0 then
    error(name .. ' must be a positive integer, but was ' .. tostring(value) .. '(' .. type(value) .. ')')
  end
end

local function checkBox(l,t,w,h)
  checkType('number', l, 'l')
  checkType('number', t, 'w')
  checkType('number', w, 'w')
  checkType('number', h, 'h')
end

local World = {}

local function box_overlap(l1,t1,w1,h1, l2,t2,w2,h2)
  -- check if there is a collision
  if l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2 then

    -- get the two centers
    local c1x, c1y = l1 + w1 * .5, t1 + h1 * .5
    local c2x, c2y = l2 + w2 * .5, t2 + h2 * .5

    -- get the two overlaps
    local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
    local dy = t2 - t1 + (c1y < c2y and -h1 or h2)

    return dx, dy
  end
  -- no collision; return nil
end

function World:add(item, l,t,w,h)
  checkBox(l,t,w,h)

  self.items[item] = nil

  local collisions, length = self:check(item, l,t,w,h)

  self.items[item] = {l=l,t=t,w=w,h=h}
  return collisions, length
end

function World:move(item, l,t,w,h)
  checkBox(l,t,w,h)

  local pBox = self.items[item]

  if not pBox then
    error('Item ' .. tostring(item) .. ' must be added to the world before being moved. Use world:add(item, l,t,w,h) to add it first.')
  end

  local collisions, length = self:check(item, l,t,w,h)

  self.items[item] = {l=l,t=t,w=w,h=h}
  return collisions, length
end

function World:check(item, l,t,w,h)
  checkBox(l,t,w,h)
  local collisions, length = {}, 0

  for other, hisBox in pairs(self.items) do
    local dx, dy = box_overlap(l,t,w,h, hisBox.l, hisBox.t, hisBox.w, hisBox.h)
    if dx then
      length = length + 1
      collisions[length] = {
        self   = item,
        other  = other,
        dx     = dx,
        dy     = dy
      }
    end
  end

  return collisions, length
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  checkPositiveNumber(cellSize, 'cellSize')
  return setmetatable(
    { cellSize = cellSize,
      items = {}
    },
    {__index = World }
  )
end


return bump
