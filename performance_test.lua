local RNG_SEED = 69420731
local WORLD_SIZE = 10
local OBJECT_COUNT = 10
local MOVEMENT_GENERATIONS = 250
local MOVE_RANGE = 1
local TEST_COUNT = 10

local function clamp(lower, val, upper)
  if lower > upper then lower, upper = upper, lower end
  return math.max(lower, math.min(upper, val))
end

local function doTest(world)
  -- seed RNG
  math.randomseed(RNG_SEED)

  -- create OBJECT_COUNT random entities
  local entities = {}
  for i = 1, OBJECT_COUNT do
    local x = math.random() * WORLD_SIZE
    local y = math.random() * WORLD_SIZE
    local w = (math.random() * 1.5) + 0.5
    local h = (math.random() * 1.5) + 0.5
    local entity = {name = i}
    table.insert(entities, entity)
    world:add(entity, x, y, w, h)
  end

  -- Collect garbage and stop GC.
  collectgarbage('collect')
  collectgarbage('stop')

  -- move all entities for MOVEMENT_GENERATIONS generations.
  local collisions = 0
  for i = 1, MOVEMENT_GENERATIONS do
    for _, entity in ipairs(entities) do
      local x, y = world:getRect(entity)
      local goalX = clamp(0, x - MOVE_RANGE + (math.random() * MOVE_RANGE * 2), WORLD_SIZE)
      local goalY = clamp(0, y - MOVE_RANGE + (math.random() * MOVE_RANGE * 2), WORLD_SIZE)
      local _, _, _, len = world:move(entity, goalX, goalY)
      collisions = collisions + len
    end
  end

  -- restart GC and measure memory difference before and after.
  local kbBefore = collectgarbage('count')
  collectgarbage('restart')
  collectgarbage('collect')
  local kbAfter = collectgarbage('count')
  local kbGarbage = kbBefore - kbAfter

  -- -- Print stats.
  -- print(("Collisions: %d"):format(collisions))
  -- print(("Garbage: %.2fkB"):format(kbGarbage))

  return kbGarbage
end

local function doTests(label, bump)
  print(("============= %s ============="):format(label))
  local totalGarbage = 0
  for i = 1, TEST_COUNT do
    local world = bump.newWorld(1)
    local garbage = doTest(world)
    totalGarbage = totalGarbage + garbage
  end
  local averageGarbage = totalGarbage / TEST_COUNT
  print(("Garbage: %.2f kB"):format(averageGarbage))
  print(("(Average after %d tests.)"):format(TEST_COUNT))
end

doTests('Original', require 'bump-original')
print('')
doTests('Modded', require 'bump')
