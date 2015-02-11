require 'lib.middleclass'
local gamera     = require 'lib.gamera'
local shakycam   = require 'lib.shakycam'
local media      = require 'media'
local Map        = require 'map'


local updateRadius = 100 -- how "far away from the camera" things stop being updated
local drawDebug   = false  -- draw bump's debug info, fps and memory
local instructions = [[
  bump.lua demo

    left,right: move
    up:     jump/fly
    return: reset map
    delete: run garbage collection
    tab:    toggle debug info (%s)
]]

local camera, map
local Phi = 0.61803398875

function love.load()
  media.load()

  local width, height = 4000, 2000
  local gamera_cam = gamera.new(0,0, width, height)
  camera = shakycam.new(gamera_cam)
  map    = Map:new(width, height, camera)
end

-- Updating
function love.update(dt)
  media.cleanup()
  -- Note that we only update elements that are visible to the camera. This is optional
  -- replace the map:update(dt, camera:getVisible()) with the following line to update everything
  -- map:update(dt)
  local l,t,w,h = camera:getVisible()
  l,t,w,h = l - updateRadius, t - updateRadius, w + updateRadius * 2, h + updateRadius * 2

  map:update(dt, l,t,w,h)
  camera:setPosition(map.player:getCenter())
  camera:update(dt)
end

-- Drawing
function love.draw()
  camera:draw(function(l,t,w,h)
    map:draw(drawDebug, l,t,w,h)
  end)

  love.graphics.setColor(255, 255, 255)

  local w,h = love.graphics.getDimensions()

  local msg = instructions:format(tostring(drawDebug))
  love.graphics.printf(msg, w - 200, 10, 200, 'left')

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB\n sfx: %d, items: %d"):format(love.timer.getFPS(), collectgarbage("count"), media.countInstances(), map:countItems())
    love.graphics.printf(statistics, w - 200, h - 40, 200, 'right')
  end
end

-- Non-player keypresses

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    collectgarbage("collect")
  end
  if k=="return" then
    map:reset()
  end
end
