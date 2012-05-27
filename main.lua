local bump = require 'bump'

-- array to hold collision messages
local text = {}

function bump.collision(a, b, dx, dy)
  text[#text+1] = string.format("Colliding. mtv = (%s,%s)", dx, dy)
end

function bump.endCollision(a, b)
  text[#text+1] = "Stopped colliding"
end

function bump.getBBox(item)
  return unpack(item)
end

function love.load()
  -- add a rectangle to the scene
  rect = { 200,400,400,20 }
  -- add a moving rectangle to the scene
  mouse = { 400, 300, 20, 20 }

  bump.add(rect)
  bump.add(mouse)
end

function love.update(dt)
  -- move circle to mouse position
  local x, y = love.mouse.getPosition()
  mouse[1] = x - mouse[3]/2
  mouse[2] = y - mouse[4]/2

  -- check for collisions
  bump.check()

  while #text > 40 do
    table.remove(text, 1)
  end
end

function love.draw()
  -- print messages
  for i = 1,#text do
    love.graphics.setColor(255,255,255, 255 - (i-1) * 6)
    love.graphics.print(text[#text - (i-1)], 10, i * 15)
  end

    -- shapes can be drawn to the screen
    love.graphics.setColor(255,255,255)
    love.graphics.rectangle('fill', unpack(rect))
    love.graphics.rectangle('fill', unpack(mouse))
end

function love.keypressed()
  love.event.quit()
end
