local bump = {}

local path = (...):gsub("%.init$","")

local nodes = require(path .. '.nodes')
local cells = require(path .. '.cells')


function bump.initialize(newCellSize)
  nodes.reset()
  cells.reset(newCellSize)
end

function bump.getCellSize()
  return cells.getSize()
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

function bump.add(item)
  nodes.create(item)
end

function bump.countItems()
  return nodes.count()
end

return bump
