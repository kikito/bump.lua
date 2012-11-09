local bump = {}

local path = (...):gsub("%.init$","")

local nodes = require(path .. '.nodes')
local cells = require(path .. '.cells')
local grid  = require(path .. '.grid')

bump.nodes, bump.cells, bump.grid = nodes, cells, grid

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
  assert(item, "item expected, got nil")
  local l,t,w,h = bump.getBBox(item)
  local gl,gt,gw,gh = grid.getBox(l,t,w,h)

  nodes.add(item, l,t,w,h, gl,gt,gw,gh)
  cells.add(item, gl,gt,gw,gh)
end

function bump.remove(item)
  assert(item, "item expected, got nil")

  nodes.remove(item)
  cells.remove(item, grid.getBox(bump.getBBox(item)))
end

function bump.update(item)
  assert(item, "item expected, got nil")
  local n = nodes.get(item)
  local l,t,w,h = bump.getBBox(item)
  if n.l ~= l or n.t ~= t or n.w ~= w or n.h ~= h then
    local gl,gt,gw,gh = grid.getBox(l,t,w,h)
    if n.gl ~= gl or n.gt ~= gt or n.gw ~= gw or n.gh ~= gh then
      cells.remove(item, n.gl, n.gt, n.gw, n.gh)
      cells.add(item, gl, gt, gw, gh)
    end
    nodes.update(item, l,t,w,h, gl,gt,gw,gh)
  end
end

function bump.countItems()
  return nodes.count()
end

function bump.countCells()
  return cells.count()
end

function bump.each(callback)
  return nodes.eachItem(callback)
end

return bump
