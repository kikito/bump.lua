local bump = require 'bump'


local w = bump.newWorld()

local A  = {l=-100, t=-100, w=200,h=200}
local B  = {l=200,t=200,w=100,h=100}
local B0 = {l=50,t=350,w=B.w,h=B.h}
local d = {x = B.l-B0.l, y = B.t - B0.t}

local cols = {}

function drawRect(l,t,w,h, r,g,b)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle('line', l, t, w, h)
end

function love.load()
  w:add(A, A.l, A.t, A.w, A.h)
  w:add(B, B.l, B.t, B.w, B.h)
end

function love.update(dt)
  local mx, my = love.mouse.getPosition()
  mx,my = mx - 400, my - 300

  B.l, B.t = mx - B.w / 2, my - B.h / 2
  B0.l, B0.t = B.l - d.x, B.t - d.y

  w:move(B, B.l, B.t, B.w, B.h)

  cols = w:check(B, d.x, d.y)
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(400,300)

  drawRect(A.l,A.t,A.w,A.h, 255, 0, 0)
  drawRect(B.l,B.t,B.w,B.h, 0, 255, 0)
  drawRect(B0.l,B0.t,B.w,B.h, 0, 100, 0)

  local l,t,w,h = bump.aabb.getMinkowskyDiff(B0.l, B0.t, B.w, B.h, A.l, A.t, A.w, A.h)

  drawRect(l,t,w,h, 0, 150, 150)
  love.graphics.line(0,0,d.x,d.y)

  local t0, t1 = bump.aabb.liangBarsky(l,t,w,h, 0,0, d.x, d.y, -math.huge,math.huge)

  if t0 then
    local x0,y0 = t0 * d.x, t0 * d.y
    local x1,y1 = t1 * d.x, t1 * d.y
    love.graphics.circle('line', x0,y0,10)
    love.graphics.circle('line', x1,y1,10)
  end

  local cx, cy = B.l + B.w / 2, B.t + B.h / 2

  for _,col in ipairs(cols) do
    love.graphics.setColor(0,255,255)
    love.graphics.line(cx,cy, cx + col.dx, cy + col.dy)
    love.graphics.setColor(0,100,100)
    love.graphics.rectangle('line', B.l + col.dx, B.t + col.dy, B.w, B.h)
  end

  love.graphics.pop()
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end
