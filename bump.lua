local bump = {}

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

local World = {}

World.add = function(self, item, l,t,w,h)
  checkType('table',  item, 'item')
  checkType('number', l, 'l')
  checkType('number', t, 'w')
  checkType('number', w, 'w')
  checkType('number', h, 'h')
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  checkPositiveNumber(cellSize, 'cellSize')
  return setmetatable(
    { cellSize = cellSize },
    {__index = World }
  )
end


return bump
