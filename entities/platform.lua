local class  = require 'lib.middleclass'
local util   = require 'util'

local Entity = require 'entities.entity'

local Platform = class('Platform', Entity)
Platform.static.updateOrder = 0

local width = 64
local height = 16
local speed = 40

local function getDiffVectorToNextWaypoint(self)
  local nextWaypoint = self.waypoints[self.nextWaypointIndex]
  local x,y          = self:getCenter()
  local nx, ny       = nextWaypoint.x, nextWaypoint.y
  return nx-x, ny-y
end

local function getDistanceToNextWaypoint(self)
  local dx,dy = getDiffVectorToNextWaypoint(self)
  return math.sqrt(dx*dx + dy*dy)
end

local function gotoToNextWaypoint(self)
  local p = self.waypoints[self.nextWaypointIndex]
  self.x, self.y = p.x - self.w / 2, p.y - self.h / 2

  self.nextWaypointIndex = (self.nextWaypointIndex % #self.waypoints) + 1
  self.world:update(self, self.x, self.y)
end

local function advanceTowardsNextWaypoint(self, advance)
  local distanceToNext = getDistanceToNextWaypoint(self)
  local dx,dy = getDiffVectorToNextWaypoint(self)
  local mx,my = (dx / distanceToNext) * advance, (dy / distanceToNext) * advance

  self.x, self.y = self.x + mx, self.y + my
end



function Platform:initialize(world, waypoints)
  assert(#waypoints > 1, "must have at least 2 waypoints")

  Entity.initialize(self, world, 0, 0, width, height)

  self.waypoints = waypoints
  self.nextWaypointIndex = 1
  self.dx, self.dy = 0,0

  gotoToNextWaypoint(self)
end

function Platform:update(dt)
  local startX, startY = self.x, self.y

  local advance = speed * dt

  local distanceToNext = getDistanceToNextWaypoint(self)

  while advance > distanceToNext do
    advance = advance - distanceToNext
    gotoToNextWaypoint(self)
    distanceToNext = getDistanceToNextWaypoint(self)
  end

  advanceTowardsNextWaypoint(self, advance)

  self.dx = startX - self.x
  self.dy = startY - self.y

  self.world:update(self, self.x, self.y)
end

function Platform:draw(drawDebug)
  if drawDebug then
    love.graphics.setColor(0,200,200)

    for i=1,#self.waypoints do
      local p = self.waypoints[i]
      love.graphics.circle('line', p.x, p.y, 5)
    end

    local p = self.waypoints[self.nextWaypointIndex]

    love.graphics.rectangle('line', p.x - 8, p.y - 8, 16, 16)

    love.graphics.polygon('line', self:getPointCoords())

    local cx, cy = self:getCenter()
    love.graphics.circle('line', cx, cy, 3)
  end

  util.drawFilledRectangle(self.x, self.y, self.w, self.h, 220, 220, 0)
end

function Platform:getPointCoords()
  local coords = {}
  for i=1, #self.waypoints do
    local p = self.waypoints[i]
    coords[i*2 - 1] = p.x
    coords[i*2]     = p.y
  end
  return coords
end

return Platform
