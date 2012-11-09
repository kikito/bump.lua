local nodes = {} -- (public/exported) holds the public methods of this module
local store      -- (private) holds the list of created nodes

local inspect = require('inspect')

function nodes.add(item, l,t,w,h, gl,gt,gw,gh)
  store[item] = {l=l,t=t,w=w,h=h, gl=gl,gt=gt,gw=gw,gh=gh}
end

function nodes.get(item)
  return store[item]
end

function nodes.reset()
  store = setmetatable({}, {__mode = "k"})
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
  if not n then
    print(inspect({n=n, item=item, store=store}))
  end
  n.l,n.t,n.w,n.h,n.gl,n.gt,n.gw,n.gh = l,t,w,h, gl,gt,gw,gh
end

nodes.reset()

return nodes
