--[[
-- skakycam lib
-- This is a small wrapper over gamera.lua that implements screen shake
-- * camera:shake() increases the intensity of the vibration
-- * camera:update(dt) decreases the intensity of the vibration slightly and moves the camera position according to the shake
-- ]]

local maxShake = 5
local atenuationSpeed = 4

local sakycam = {}

local ShakyCam = {}

function ShakyCam:draw(f)
  self.camera:draw(f)
end

function ShakyCam:getVisible()
  return self.camera:getVisible()
end

function ShakyCam:setPosition(x,y)
  self.camera:setPosition(x,y)
end

function ShakyCam:shake(intensity)
  intensity = intensity or 3
  self.shakeIntensity = math.min(maxShake, self.shakeIntensity + intensity)
end

function ShakyCam:update(dt)
  self.shakeIntensity = math.max(0 , self.shakeIntensity - atenuationSpeed * dt)

  if self.shakeIntensity > 0 then
    local x,y = self.camera:getPosition()

    x = x + (100 - 200*math.random(self.shakeIntensity)) * dt
    y = y + (100 - 200*math.random(self.shakeIntensity)) * dt
    self:setPosition(x,y)
  end
end

sakycam.new = function(camera)
  return setmetatable({camera = camera, shakeIntensity = 0}, {__index = ShakyCam})
end

return sakycam
