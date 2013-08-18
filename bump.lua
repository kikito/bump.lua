local bump = {}


local function checkPositiveInteger(value, name)
  if type(value) ~= 'number' or value <= 0 then
    error(name .. ' must be a positive integer, but was ' .. tostring(value) .. '(' .. type(value) .. ')')
  end
end

bump.newWorld = function(cellSize)
  cellSize = cellSize or 64
  checkPositiveInteger(cellSize, 'cellSize')
  return { cellSize = cellSize }
end

return bump
