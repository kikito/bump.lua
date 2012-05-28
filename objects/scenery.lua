-- represents the rectangles that configure the level

local object = require 'objects.object'

local scenery = {}

function scenery.new(l,t,w,h)
  return object.new("scenery",l,t,w,h)
end

return scenery
