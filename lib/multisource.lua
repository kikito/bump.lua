--[[
-- multisource lib
-- A multisource is a wrapper on top of a LÖVE source. It allows
-- creating multiple sounds easily. It uses an internal pool of
-- resources.
-- * multisource:play() finds a stopped resource from the pool,
--   or creates a new one, and plays and returns it.
-- * multisouce:cleanup() liberates the memory of old unplayed sources.
]]

local multisource = {}

local MultiSource   = {}
local MultiSourceMt = {__index = MultiSource}

function MultiSource:cleanup(older_than)
  older_than = older_than or 5

  local now = love.timer.getTime()

  for instance, lastPlayed in pairs(self.instances) do
    local age = now - lastPlayed
    if age > older_than and instance:isStopped() then
      self.instances[instance] = nil
    end
  end
end

function MultiSource:getStoppedOrNewInstance()
  for instance in pairs(self.instances) do
    if instance:isStopped() then return instance end
  end
  return self.source:clone()
end

function MultiSource:play()
  local instance = self:getStoppedOrNewInstance()
  self.instances[instance] = love.timer.getTime()

  instance:play()

  return instance
end

function MultiSource:stop()
  for instance in pairs(self.instances) do
    instance:stop()
  end
end

function MultiSource:pause()
  for instance in pairs(self.instances) do
    instance:pause()
  end
end

function MultiSource:setLooping(looping)
  self.source:setLooping(looping)
end

function MultiSource:resume()
  for instance in pairs(self.instances) do
    instance:resume()
  end
end

function MultiSource:countPlayingInstances()
  local count = 0
  for instance in pairs(self.instances) do
    if instance:isPlaying() then
      count = count + 1
    end
  end
  return count
end

function MultiSource:countInstances()
  local count = 0
  for instance in pairs(self.instances) do
    count = count + 1
  end
  return count
end

----

multisource.new = function(source)
  return setmetatable({source = source, instances = {}}, MultiSourceMt)
end

return multisource
