require 'lib.middleclass'
local gamera     = require 'lib.gamera'
local shakycam   = require 'lib.shakycam'
local Map        = require 'map'

local drawDebug   = false  -- draw bump's debug info, fps and memory
local instructions = [[
  bump.lua demo

    left,right: move
    up:     jump/fly
    return: reset map
    delete: run garbage collection
    tab:         toggle debug info (%s)
    right shift: toggle fly (%s)
]]

local camera, map
local Phi = 0.61803398875

local function reset()
  local width, height = 4000, 2000
  local gamera_cam = gamera.new(0,0, width, height)
  camera = shakycam.new(gamera_cam)
  map    = Map:new(width, height, camera)
end

function love.load()
  reset()
end

-- Updating
-- Note that we only update elements that are visible to the camera. This is optional
function love.update(dt)
  map:update(dt, camera:getVisible())
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

  local msg = instructions:format(tostring(drawDebug), tostring(map.player.canFly))
  love.graphics.printf(msg, w - 200, 10, 200, 'left')

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB"):format(love.timer.getFPS(), collectgarbage("count"))
    love.graphics.printf(statistics, w - 200, h - 20, 200, 'right')
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
    reset()
  end
  if k=="rshift" then
    map.player.canFly = not map.player.canFly
  end

end
