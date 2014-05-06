local class  = require 'lib.middleclass'
local util   = require 'util'

local Turret = class('Player')

local width  = 50
local height = 110
local activeRadius = 400

function Turret:initialize(world, target, x, y)
  self.world, self.target, self.l, self.t = world, target, x, y

  -- remove any blocks it touches on creation
  world:add(self, x,y, width, height)
  local cols, len = world:check(self)
  for i=1,len do
    world:remove(cols[i].other)
  end
end

function Turret:getCenter()
  return self.l + width / 2, self.t + height / 2
end

function Turret:draw()
  local r,g,b = 255,0,255
  util.drawFilledRectangle(self.l, self.t, width, height, r,g,b)

  local cx,cy = self:getCenter()
  love.graphics.setColor(255,0,0)
  love.graphics.circle('line', cx, cy, 8)

  love.graphics.setColor(255,255,255,100)
  love.graphics.circle('line', cx, cy, activeRadius)

  if self.isNearTarget then
    local tx,ty = self.target:getCenter()
    love.graphics.line(cx, cy, tx, ty)
    love.graphics.setColor(255,0,0)
    love.graphics.line(cx, cy, self.laserX, self.laserY)
  end
end

function Turret:update()
  local cx,cy = self:getCenter()
  local tx,ty = self.target:getCenter()

  local dx,dy = cx-tx, cy-ty
  local distance2 = dx*dx + dy*dy

  if distance2 <= activeRadius * activeRadius then
    self.isNearTarget = true
    local itemInfo, len = self.world:querySegmentWithCoords(cx,cy,tx,ty)
    -- ignore itemsInfo[1] because that's always self
    local info = itemInfo[2]
    if info then
      self.laserX = info.x1
      self.laserY = info.y1
      self.canSeeTarget = info.item == self.target
    end
  else
    self.isNearTarget = false
    self.canSeeTarget = false
    self.laserX, self.laserY = nil,nil
  end
end

return Turret


