local class    = require 'lib.middleclass'
local util     = require 'util'
local Entity   = require 'entities.entity'
local Grenade  = require 'entities.grenade'

local Guardian = class('Guardian', Entity)

local Phi           = 0.61803398875
local height        = 110
local width         = height * (1 - Phi)
local activeRadius  = 400
local coolDown      = 2

function Guardian:initialize(world, target, x, y)
  Entity.initialize(self, world, x, y, width, height)

  self.target = target
  self.fireTimer = 0

  -- remove any blocks it touches on creation
  local cols, len = world:check(self)
  for i=1,len do
    world:remove(cols[i].other)
  end
end

function Guardian:getUpdateOrder()
  return 3
end

function Guardian:getCenter()
  return self.l + width / 2,
         self.t + height * (1 - Phi)
end

function Guardian:draw(drawDebug)
  local r,g,b = 255,0,255
  util.drawFilledRectangle(self.l, self.t, width, height, r,g,b)

  local cx,cy = self:getCenter()
  love.graphics.setColor(255,0,0)
  local radius = Grenade.radius
  if self.isLoading then
    local percent = self.fireTimer / coolDown
    local alpha = 255 - math.floor(255 * percent)
    radius = radius * percent

    love.graphics.setColor(255,0,0,alpha)
    love.graphics.circle('fill', cx, cy, radius)
    love.graphics.setColor(255,0,0)
    love.graphics.circle('line', cx, cy, radius)
  else
    love.graphics.setColor(255,0,0)
    love.graphics.circle('line', cx, cy, radius)

    if drawDebug then
      love.graphics.setColor(255,255,255,100)
      love.graphics.circle('line', cx, cy, activeRadius)
    end

    if self.isNearTarget then
      local tx,ty = self.target:getCenter()

      if drawDebug then
        love.graphics.setColor(255,255,255,100)
        love.graphics.line(cx, cy, tx, ty)
      end

      love.graphics.setColor(255,0,0)
      love.graphics.line(cx, cy, self.laserX, self.laserY)
    end

  end
end

function Guardian:update(dt)
  self.isNearTarget         = false
  self.isLoading            = false
  self.laserX, self.laserY  = nil,nil

  if self.fireTimer < coolDown then
    self.fireTimer = self.fireTimer + dt
    self.isLoading = true
  else
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
        if info.item == self.target then
          self:fire()
        end
      end
    end
  end
end

function Guardian:fire()
  local cx, cy = self:getCenter()
  local tx, ty = self.target:getCenter()
  local vx, vy = (tx - cx) * 3, (ty - cy) * 3
  Grenade:new(self.world, self, cx, cy, vx, vy)
  self.fireTimer = 0
end

function Guardian:destroy()
  Entity.destroy(self)
end

return Guardian


