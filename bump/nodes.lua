local nodes = {} -- (public/exported) holds the public methods of this module
local store      -- (private) holds the list of created nodes

function nodes.create(item, l,t,w,h, gl,gt,gw,gh)
  assert(item, "item expected, got nil")
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

function nodes.destroy(item)
  store[item] = nil
end

nodes.reset()

return nodes
