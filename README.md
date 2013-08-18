bump.lua
========

Lua collision-detection library for axis-aligned boxes. Its main features are:

* Handles axis-aligned boxes only (no circles, polygons, etc)
* Strives to be fast and have a very small memory footprint
* Detects collisions and collision stops
* When a collision occurs, the lib provides a minimal displacement vector

It tries to be a minimal [HardonCollider](http://vrld.github.com/HardonCollider/).

Bump only does axis-aligned box collisions. If you need anything more complicated than that (circles, polygons, etc.) give HardonCollider a look.

Other than that, feel free to poke around!

h1. Example

    local bump = require 'bump'

    -- The grid cell size can be specified via the initialize method
    -- By default, the cell size is 32
    bump.initialize(50)

    function bump.collision(item1, item2, col)
      print(item1.name, "collision with", item2.name, "displacement vector:", col.dx, col.dy)
    end

    function bump.endCollision(item1, item2)
      print(item1.name, "stopped colliding with", item2.name)
    end

    -- create two rectangles
    local rect1 = {name="rect1", l=0  , t=0, w=100, h=100} -- name, left, top, width, height
    local rect2 = {name="rect2", l=300, t=0, w=100, h=100}

    -- insert both rectangles into bump
    bump.add(rect1)
    bump.add(rect2)

    function bump.getBBox(item)
      return item.l, item.t, item.w, item.h
    end

    -- Now every time we call bump.collide() it will call bump.collision/endCollision appropiatedly.
    -- bump.collide() is usually called once per "update" cycle in a game. But you could also invoke it directly if
    -- you wanted. For example:

    bump.collide() -- nothing happens, there are no collisions

    rect2.l = 50 -- move rect2 so it collides with rect1

    bump.collide() -- prints "rect1 started colliding with rect2 displacement vector: -50 0"

    rect2.l = 100 -- move rect2 so it does not collide any more with rect1

    bump.collide()  -- prints "rect1 stopped colliding with rect2"


Installation
============

Just copy the bump.lua file wherever you want it. Then require it where you need it:

    local bump = require 'bump'

If you copied bump.lua to a file not accesible from the root folder (for example a lib folder), change the code accordingly:

    local bump = require 'lib.bump'

Please make sure that you read the license, too (for your convenience it's now included at the beginning of the bump.lua file.

Demo
====

There is a demo in the demo branch of this repository:

http://github.com/kikito/bump.lua/tree/demo

You will need "LÖVE":http://love2d.org in order to try it.
