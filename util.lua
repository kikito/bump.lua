local util = {}

util.drawFilledRectangle = function(l,t,w,h, r,g,b)
  love.graphics.setColor(r,g,b,100)
  love.graphics.rectangle('fill', l,t,w,h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle('line', l,t,w,h)
end

return util
