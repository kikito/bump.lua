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
    local world = bump.newWorld(50)

    -- create two rectangles
    local A = {name="A"}
    local B = {name="B"}

    -- insert both rectangles into bump
    world:add(A,   0, 0, 100, 100) -- left, top, width, height
    world:add(B, 300, 0, 100, 100)

    -- see if A is colliding with anything
    local collisions = world:check(B)
    assert(#collisions == 0)

    -- move B so it collides with A
    local collisions = world:move(B, 50, 0, 100, 100)

    -- parse the collisions.
    -- prints "Collision with A. dx: -50, dy: 0, t: 0"
    for _,col in ipairs(collision) do -- If more than one simultaneous collision, they are sorted out by proximity
      print(("Collision with %s. dx: %d, dy: %d, t: %d"):format(col.item.name, col.dx, col.dy, col.ti)
    end

    -- remove A and B from the world
    world:remove(A)
    world:remove(B)


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
