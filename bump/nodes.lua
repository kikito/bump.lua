-- bump.nodes
-- A node in lua is 'the information bump has about that node'
-- Typically, its boundingbox & gridbox. This module deals with managing and storing
-- bump's nodes.

local nodes = {} -- (public/exported) holds the public methods of this module

local path = (...):gsub("%.nodes$","")
local util       = require(path .. '.util')

local store      -- (private) holds the list of created nodes

function nodes.add(item, l,t,w,h, gl,gt,gw,gh)
  store[item] = {l=l,t=t,w=w,h=h, gl=gl,gt=gt,gw=gw,gh=gh}
end

function nodes.get(item)
  return store[item]
end

function nodes.reset()
  store = util.newWeakTable()
end

function nodes.count()
  local count = 0
  for _,_ in pairs(store) do count = count + 1 end
  return count
end

function nodes.remove(item)
  store[item] = nil
end

function nodes.update(item, l,t,w,h, gl,gt,gw,gh)
  local n = store[item]
  n.l,n.t,n.w,n.h,n.gl,n.gt,n.gw,n.gh = l,t,w,h, gl,gt,gw,gh
end

nodes.reset()

return nodes
