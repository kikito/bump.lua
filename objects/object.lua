-- This file holds the list of objects in the scene

local bump = require 'bump'

local object = {} -- the public functions this file exposes will be defined here

local objects = {} -- this will hold the list of objects


function object.new(class,l,t,w,h)
  local obj = {l=l, t=t, w=w, h=h, class=class, [class]=true}
  objects[obj] = true
  bump.add(obj)
  return obj
end

function object.delete(obj)
  objects[obj] = nil
  bump.remove(obj)
end

function object.drawAll()
  for obj,_ in pairs(objects) do
    love.graphics.rectangle('line', obj.l, obj.t, obj.w, obj.h)
  end
end

return object
