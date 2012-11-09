local intersect = {}

function intersect.quick(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

return intersect
