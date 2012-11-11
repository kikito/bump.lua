local intersect = {}

local function abs(x)
  return x<0 and -x or x
end

function intersect.quick(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

function intersect.displacement(l1,t1,w1,h1, l2,t2,w2,h2)
  local c1x, c2x = (l1+w1) * .5, (l2+w2) * .5
  local c1y, c2y = (t1+h1) * .5, (t2+h2) * .5
  return l2 - l1 + (c1x < c2x and -w1 or w2),
         t2 - t1 + (c1y < c2y and -h1 or h2)
end

function intersect.areaAndDisplacement(l1,t1,w1,h1, l2,t2,w2,h2)
  local dx, dy = intersect.displacement(l1,t1,w1,h1, l2,t2,w2,h2)
  return abs(dx*dy), dx, dy
end


return intersect
