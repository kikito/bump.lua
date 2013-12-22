local bump       = require 'bump'
local bump_debug = require 'bump_debug'

local instructions = [[
  bump.lua simple demo

    arrows: move
    tab: toggle debug info
    delete: run garbage collector
]]

-- helper function
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.l, box.t, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.l, box.t, box.w, box.h)
end

-- World creation
local world = bump.newWorld()


-- Player functions
local player = { l=50,t=50,w=20,h=20, speed = 80 }

local function updatePlayer(dt)
  local speed = player.speed
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

  local visited,    i   = {}, 1
  local collisions, len = world:move(player, player.l, player.t, player.w, player.h)

  while i <= len do
   local col = collisions[i]
   if not visited[col.item] then
     visited[col.item] = true
     local dx, dy       = col.dx, col.dy
     player.l, player.t = player.l + dx, player.t + dy
     collisions, len    = world:move(player, player.l, player.t, player.w, player.h)
     i = 0
   end
   i = i + 1
  end
end

local function drawPlayer()
  drawBox(player, 0, 255, 0)
end

-- Block functions

local blocks = {}

local function addBlock(l,t,w,h)
  local block = {l=l,t=t,w=w,h=h}
  blocks[#blocks+1] = block
  world:add(block, l,t,w,h)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end

-- Message/debug functions
local function drawMessage()
  local msg = instructions:format(tostring(shouldDrawDebug))
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(msg, 550, 10)
end

local function drawDebug()
  bump_debug.draw(world)

  local statistics = ("fps: %d, mem: %dKB"):format(love.timer.getFPS(), collectgarbage("count"))
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(statistics, 630, 580 )
end


function love.load()
  world:add(player, player.l, player.t, player.w, player.h)

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
  updatePlayer(dt)
end

function love.draw()
  drawBlocks()
  drawPlayer()
  if shouldDrawDebug then drawDebug() end
  drawMessage()
end

-- Non-player keypresses
function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then shouldDrawDebug = not shouldDrawDebug end
  if k=="delete" then collectgarbage("collect") end
end
