-- viewport and boundaries are expressed as left, top, width and height
local viewport = {
  l = 0,
  t = 0,
  w = love.graphics.getWidth(),
  h = love.graphics.getHeight()
}

local boundary = {
  l = 0,
  t = 0,
  w = viewport.width,
  h = viewport.height
}

local function clampNumber(v, min, max)
  if max < min then return 0 end -- this happens when viewport is bigger than boundary
  return v < min and min or (v > max and max or v)
end

local function clampCamera()
  viewport.l = clampNumber(viewport.l, boundary.l, boundary.l + boundary.w - viewport.w)
  viewport.t = clampNumber(viewport.t, boundary.t, boundary.t + boundary.h - viewport.h)
end

local function setViewport(l, t, w, h)
  viewport.l, viewport.t, viewport.w, viewport.h = l, t, w or viewport.w, h or viewport.h
  clampCamera()
end

local function setBoundary(l, t, w, h)
  boundary.l, boundary.t, boundary.w, boundary.h = l, t, w, h
  clampCamera()
end

local function lookAt(x,y)
  setViewport(math.floor(x - viewport.w / 2), math.floor(y - viewport.h / 2))
end

local function getViewport()
  return viewport.l, viewport.t, viewport.w, viewport.h
end

local function draw(f)
  love.graphics.push()
  love.graphics.translate(-viewport.l, -viewport.t)
  f(getViewport())
  love.graphics.pop()
end


return {
  setViewport = setViewport,
  setBoundary = setBoundary,
  getViewport = getViewport,
  lookAt      = lookAt,
  draw        = draw
}
