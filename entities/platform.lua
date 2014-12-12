local class  = require 'lib.middleclass'
local util   = require 'util'

local Entity = require 'entities.entity'

local Platform = class('Platform', Entity)
Platform.static.updateOrder = 0

local width = 64
local height = 16
local speed = 40

function Platform:initialize(world, waypoints)
  assert(#waypoints > 1, "must have at least 2 waypoints")

  local x,y = waypoints[1].x, waypoints[1].y
  Entity.initialize(self, world, x,y, width, height)

  self.waypoints = waypoints
  self.nextWaypointIndex = 2
end

function Platform:getDiffVectorToNextWaypoint()
  local nextWaypoint = self.waypoints[self.nextWaypointIndex]
  local x,y          = self.x, self.y
  local nx, ny       = nextWaypoint.x, nextWaypoint.y
  return nx-x, ny-y
end

function Platform:getDistanceToNextWaypoint()
  local dx,dy = self:getDiffVectorToNextWaypoint()
  return math.sqrt(dx*dx + dy*dy)
end

function Platform:update(dt)
  local advance = speed * dt

  local distanceToNext = self:getDistanceToNextWaypoint()

  while advance > distanceToNext do
    advance = advance - distanceToNext

    local thisWaypoint = self.waypoints[self.nextWaypointIndex]
    self.x, self.y = thisWaypoint.x, thisWaypoint.y
    self.nextWaypointIndex = (self.nextWaypointIndex % #self.waypoints) + 1

    distanceToNext = self:getDistanceToNextWaypoint()
  end

  local dx,dy = self:getDiffVectorToNextWaypoint()
  local mx,my = (dx / distanceToNext) * advance, (dy / distanceToNext) * advance

  self.x, self.y = self.x + mx, self.y + my
  self.world:update(self, self.x, self.y)
end

function Platform:draw()
  util.drawFilledRectangle(self.x, self.y, self.w, self.h, 220, 220, 0)
end

return Platform
