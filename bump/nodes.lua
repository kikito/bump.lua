local nodes = {}



function nodes.create(item)
  nodes[item] = {}
end

function nodes.get(item)
  return nodes[item]
end

return nodes
