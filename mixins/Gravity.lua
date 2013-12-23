local Gravity = {}

local gravityAcceleration  =  500 -- pixels per second^2

function Gravity:addGravity(dt)
  self.vy = (self.vy or 0) + gravityAcceleration * dt
  self.t  = self.t + self.vy * dt
end

return Gravity
