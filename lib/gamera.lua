-- gamera.lua v1.0.1

-- Copyright (c) 2012 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- Based on YaciCode, from Julien Patte and LuaObject, from Sebastien Rocca-Serra

local gamera = {}

-- Private attributes and methods

local gameraMt = {__index = gamera}
local abs, min, max = math.abs, math.min, math.max

local function clamp(x, minX, maxX)
  return x < minX and minX or (x>maxX and maxX or x)
end

local function checkNumber(value, name)
  if type(value) ~= 'number' then
    error(name .. " must be a number (was: " .. tostring(value) .. ")")
  end
end

local function checkPositiveNumber(value, name)
  if type(value) ~= 'number' or value <=0 then
    error(name .. " must be a positive number (was: " .. tostring(value) ..")")
  end
end

local function checkAABB(l,t,w,h)
  checkNumber(l, "l")
  checkNumber(t, "t")
  checkPositiveNumber(w, "w")
  checkPositiveNumber(h, "h")
end

local function getVisibleArea(self, scale)
  scale = scale or self.scale
  local sin, cos = abs(self.sin), abs(self.cos)
  local w,h = self.w / scale, self.h / scale
  w,h = cos*w + sin*h, sin*w + cos*h
  return min(w,self.ww), min(h, self.wh)
end

local function cornerTransform(self, x,y)
  local scale, sin, cos = self.scale, self.sin, self.cos
  x,y = x - self.x, y - self.y
  x,y = -cos*x + sin*y, -sin*x - cos*y
  return self.x - (x/scale + self.l), self.y - (y/scale + self.t)
end

local function adjustPosition(self)
  local wl,wt,ww,wh = self.wl, self.wt, self.ww, self.wh
  local w,h = getVisibleArea(self)
  local w2,h2 = w*0.5, h*0.5

  local left, right  = wl + w2, wl + ww - w2
  local top,  bottom = wt + h2, wt + wh - h2

  self.x, self.y = clamp(self.x, left, right), clamp(self.y, top, bottom)
end

local function adjustScale(self)
  local w,h,ww,wh = self.w, self.h, self.ww, self.wh
  local rw,rh     = getVisibleArea(self, 1)      -- rotated frame: area around the window, rotated without scaling
  local sx,sy     = rw/ww, rh/wh                 -- vert/horiz scale: minimun scales that the window needs to occupy the world
  local rscale    = max(sx,sy)

  self.scale = max(self.scale, rscale)
end

-- Public interface

function gamera.new(l,t,w,h)

  local sw,sh = love.graphics.getWidth(), love.graphics.getHeight()

  local cam = setmetatable({
    x=0, y=0,
    scale=1,
    angle=0, sin=math.sin(0), cos=math.cos(0),
    l=0, t=0, w=sw, h=sh, w2=sw*0.5, h2=sh*0.5
  }, gameraMt)

  cam:setWorld(l,t,w,h)

  return cam
end

function gamera:setWorld(l,t,w,h)
  checkAABB(l,t,w,h)

  self.wl, self.wt, self.ww, self.wh = l,t,w,h

  adjustPosition(self)
end

function gamera:setWindow(l,t,w,h)
  checkAABB(l,t,w,h)

  self.l, self.t, self.w, self.h, self.w2, self.h2 = l,t,w,h, w*0.5, h*0.5

  adjustPosition(self)
end

function gamera:setPosition(x,y)
  checkNumber(x, "x")
  checkNumber(y, "y")

  self.x, self.y = x,y

  adjustPosition(self)
end

function gamera:setScale(scale)
  checkNumber(scale, "scale")

  self.scale = scale

  adjustScale(self)
  adjustPosition(self)
end

function gamera:setAngle(angle)
  checkNumber(angle, "angle")

  self.angle = angle
  self.cos, self.sin = math.cos(angle), math.sin(angle)

  adjustScale(self)
  adjustPosition(self)
end

function gamera:getWorld()
  return self.wl, self.wt, self.ww, self.wh
end

function gamera:getWindow()
  return self.l, self.t, self.w, self.h
end

function gamera:getPosition()
  return self.x, self.y
end

function gamera:getScale()
  return self.scale
end

function gamera:getAngle()
  return self.angle
end

function gamera:getVisible()
  local w,h = getVisibleArea(self)
  return self.x - w*0.5, self.y - h*0.5, w, h
end

function gamera:getVisibleCorners()
  local x,y,w2,h2 = self.x, self.y, self.w2, self.h2

  local x1,y1 = cornerTransform(self, x-w2,y-h2)
  local x2,y2 = cornerTransform(self, x+w2,y-h2)
  local x3,y3 = cornerTransform(self, x+w2,y+h2)
  local x4,y4 = cornerTransform(self, x-w2,y+h2)

  return x1,y1,x2,y2,x3,y3,x4,y4
end

function gamera:draw(f)
  love.graphics.setScissor(self:getWindow())

  love.graphics.push()
    local scale = self.scale
    love.graphics.scale(scale)

    love.graphics.translate((self.w2 + self.l) / scale, (self.h2+self.t) / scale)
    love.graphics.rotate(-self.angle)
    love.graphics.translate(-self.x, -self.y)

    f(self:getVisible())

  love.graphics.pop()

  love.graphics.setScissor()
end

function gamera:toWorld(x,y)
  local scale, sin, cos = self.scale, self.sin, self.cos
  x,y = (x - self.w2 - self.l) / scale, (y - self.h2 - self.t) / scale
  x,y = cos*x - sin*y, sin*x + cos*y
  return x + self.x, y + self.y
end

function gamera:toScreen(x,y)
  local scale, sin, cos = self.scale, self.sin, self.cos
  x,y = x - self.x, y - self.y
  x,y = cos*x + sin*y, -sin*x + cos*y
  return scale * x + self.w2 + self.l, scale * y + self.h2 + self.t
end

return gamera




