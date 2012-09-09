local bump       = require 'bump'
local bump_debug = require 'bump_debug'

local maxdt       = 0.1    -- if the window loses focus/etc, use this instead of dt
local drawDebug   = false  -- draw bump's debug info, fps and memory
local instructions = [[
  bump.lua simple demo

    arrows: move
    delete: run garbage collection
    tab:    toggle debug info (%s)
]]

local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.l, box.t, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.l, box.t, box.w, box.h)
end


-- Player functions

local player = { l=50,t=50,w=20,h=20 }

local function updatePlayer(dt)
  local speed = 80
  if love.keyboard.isDown('up') then
    player.t = player.t - speed * dt
  elseif love.keyboard.isDown('down') then
    player.t = player.t + speed * dt
  end

  if love.keyboard.isDown('left') then
    player.l = player.l - speed * dt
  elseif love.keyboard.isDown('right') then
    player.l = player.l + speed * dt
  end
end

local function collidePlayerWithBlock(dx,dy)
  player.l = player.l + dx
  player.t = player.t + dy
end

local function drawPlayer()
  drawBox(player, 0, 255, 0)
end


-- Block functions

local blocks = {}

local function addBlock(l,t,w,h)
  local block = {l=l,t=t,w=w,h=h}
  blocks[#blocks+1] = block
  bump.add(block)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end


-- bump config

-- When a collision occurs, call collideWithBlock with the appropiate parameters
function bump.collision(obj1, obj2, dx, dy)
  if obj1 == player then
    collidePlayerWithBlock(dx,dy)
  elseif obj2 == player then
    collidePlayerWithBlock(-dx,-dy)
  end
end

-- only the player collides with stuff. Blocks don't collide with themselves
function bump.shouldCollide(obj1, obj2)
  return obj1 == player or obj2 == player
end

-- return the bounding box of an object - the player or a block
function bump.getBBox(obj)
  return obj.l, obj.t, obj.w, obj.h
end

-- love config

function love.load()
  player = { l=50,t=50,w=20,h=20 }
  bump.add(player)

  addBlock(0,       0,     800, 32)
  addBlock(0,      32,      32, 600-32*2)
  addBlock(800-32, 32,      32, 600-32*2)
  addBlock(0,      600-32, 800, 32)

  for i=1,30 do
    addBlock( math.random(100, 600),
              math.random(100, 400),
              math.random(10, 100),
              math.random(10, 100)
    )
  end
end

function love.update(dt)
  dt = math.min(dt, maxdt)

  updatePlayer(dt)

  bump.collide()
end

function love.draw()

  if drawDebug then
    bump_debug.draw(0,0,800,600)
  end

  drawBlocks()
  drawPlayer()

  love.graphics.setColor(255, 255, 255)

  local msg = instructions:format(tostring(drawDebug))
  love.graphics.print(msg, 550, 10)

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB"):format(love.timer.getFPS(), collectgarbage("count"))
    love.graphics.print(statistics, 630, 580 )
  end
end

-- Non-player keypresses
function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    collectgarbage("collect")
  end
end
