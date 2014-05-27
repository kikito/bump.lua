--[[
-- media file
-- This file loads and controls all the sounds of the game.
-- * media.load() reads the sounds from the disk. It must be called before
--   the sounds or music are used
-- * media.music contains a source with the music
-- * media.sfx.* contains multisources (see lib/multisource.lua)
-- * media.cleanup liberates unused sounds.
-- * media.countInstances counts how many sound instances are there in the
--   system. This is used for debugging
]]

local multisource = require 'lib.multisource'
local media = {}

local function newSource(name)
  local path = 'sfx/' .. name .. '.ogg'
  local source = love.audio.newSource(path)
  return multisource.new(source)
end

media.load = function()
  local names = [[
    explosion
    grenade_wall_hit
    guardian_death guardian_shoot guardian_target_acquired
    player_jump player_full_health player_propulsion
  ]]

  media.sfx = {}
  for name in names:gmatch('%S+') do
    media.sfx[name] = newSource(name)
  end

  media.sfx.player_propulsion:setLooping(true)

  media.music = love.audio.newSource('sfx/wrath_of_the_djinn.xm')
  media.music:setLooping(true)
end

media.cleanup = function()
  for _,sfx in pairs(media.sfx) do
    sfx:cleanup()
  end
end

media.countInstances = function()
  local count = 0
  for _,sfx in pairs(media.sfx) do
    count = count + sfx:countInstances()
  end
  return count
end


return media
