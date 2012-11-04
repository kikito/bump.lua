local bump = {}

local path = (...):gsub("%.init$","")

local nodes = require(path .. '.nodes')
local cells = require(path .. '.cells')
local grid  = require(path .. '.grid')


function bump.initialize(newCellSize)
  nodes.reset()
  grid.reset(newCellSize)
  cells.reset()
end

function bump.getCellSize()
  return grid.getCellSize()
end

function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

function bump.add(item)
  local l,t,w,h = bump.getBBox(item)
  local gl,gt,gw,gh = grid.getBox(l,t,w,h)

  nodes.create(item)
  cells.addItem(item, gl,gt,gw,gh)
end

function bump.countItems()
  return nodes.count()
end

function bump.countCells()
  return cells.count()
end

return bump
