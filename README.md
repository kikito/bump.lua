bump.lua
========

Lua collision-detection library for axis-aligned boxes. Its main features are:

* Bump only does axis-aligned bounding-box (AABB) collisions. If you need anything more complicated than that (circles, polygons, etc.) give HardonCollider a look.
* Handles tunnelling - all items are treated as "bullets". The fact that we only use AABBs allows doing this fast.
* Strives to be fast and have a small memory footprint
* Provides a minimal displacement vector.
* Can also return the items that touch a point, a segment or a rectangular zone.
* bump.lua is _gameistic_ instead of realistic.

Feel free to poke around!

Example
=======

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

Demo
====

There is a demo in the demo branch of this repository:

http://github.com/kikito/bump.lua/tree/demo

You will need "LÖVE":http://love2d.org in order to try it.

Interface
=========

world = bump.newWorld(cellSize)
------------------------------

The first thing to do with bump is creating a world. That is done with `bump.newWorld`.

    local bump = require 'bump'

    local world = bump.newWorld()

 `bump.newWorld` has one optional parameter, called `cellSize`. It must be a number. It represents the size of the sides
 of the (squared) cells that will be used internally to provide the data. In tile based games, it's usually a multiple of
 the tile side size. So in a game where tiles are 32x32, cellSize will be 32, 64 or 128. In more sparse games, it can be
 higher.

 Don't worry too much about that number at the beginning, you can tweak it later on to see if bigger/smaller numbers
 give you better results (you can't change the value of cellSize in runtime, but you can create as many worlds as you need,
 each one with a different cellsize, if the need arises.)

`cellSize`'s default value is 64.

The rest of the methods we have are for the worlds that we create.

collisions = world:add(item, l,t,w,h, options)
---------------------------------------------

`world:add` is what you need to insert a new item in a world.

    local player = <create the player table like you want>
    local collisions = world:add(player, 0,0,32,32)

* `collisions` is the result of this method. When you insert a new object, `bump` will try to detect the collisions it has with
  other existing objects in the world (this can be tweaked/deactivated using `options`, keep reading)
* `item` is the new item being inserted (usually a table representing a game object, like `player` or `ground_tile`).
* `l,t,w,h` are the dimensions of the item: left, top, width, height
* `options` is an optional table. It can have the following fields:
  * `options.skip_collisions`: set this to `true` if you don't want to compute the collisions for this insertion (an empty table will
    be returned). Defaults to false.
  * `options.visited`: An array of items to "ignore" when computing the collisions. Default: empty (collide with everything)
  * `options.filter`: A function to "filter out" items when computing collisions. Should return `true` if an item must be
    ignored. When the filtered items are known, using `visited` is faster. Default: don't filter anything (collide with everything)
  * `options.axis`: Can be the string `"x"` or the string `"y"`. When set to any of these strings, the collisions are forced to
    happen in one of the axes (instead of the minimum displacement vector). This is useful for modelling

collisions = world:move(item, l,t,w,h, options)
-----------------------------------------------

`world:move` is what you use to move items around in the world. It can also be used to change the shape of an item's AABB.

    local collisions = world:move(player, 20,20,32,32)

* `collisions` is again a list of collision objects (will describe this after the rest)
* `item` is the object being moved. You must have added it (with `world:add(item, ...)`) before attempting to move it, or you
  will receive an error.
* `l,t,w,h` are the new coordinates of the item's AABB. Notice that only `l` and `t` are mandatory. If unspecified, the previous
  `w` and `h` from the object will be taken from the internal database.
* `options` works exactly like in `world:move`.

The `collisions` table has 0 or more items with this format:

    collisions = {
      { item = <the item to which the object being moved is colliding with>,
        kind = <the type of collision. It can be either "intersection" or "tunnel"
        dx   = <the distance we should move the object to the right in order to make it stop colliding with item>,
        dy   = <same as dx, for the y coordinate>,
        ti   = <for intersections, it is 0. For tunnels, it's a number between 0 and 1 indicating "how long did the object travel before intersecting with item">
      },
      ... <zero or more of the above>
    }

The only way an object can get `tunnel` collisions is moving so fast it "traverses" other objects completely. So
`tunnel`-type collisions are much less frequent than `intersection`s.

A simple way to deal with these collisions is just taking the first one and ignoring the rest.

    local collisions = world:move(player, player.x,player.y)
    if collisions[1] then
      local dx,dy = collisions[1].dx, collisions[1].dy
      player.x, player.y = player.x + dx, player.y + dy
      world:move(player, player.x ,player.y, {skip_collisions = true})
    end

But it can get more complicated than that: one can iterate over all collisions, and `move` or `check` for new collisions, etc.

world:remove(item)
------------------

It removes one item from the world. Returns nothing.

    world:remove(player)

`item` is the only parameter needed. It must be an object previously inserted with `world:add(item, ...)`.


collisions = world:check(item, options)
---------------------------------------

This method checks an existing item for collisions, without moving it.

    local collisions = world:check(player)

* `collisions` works like in `world:move`.
* `item` is an element that must exist in the world (must have been added with `world:add(item, ...)`)
* `options` works like in `world:move` and `world:add`, but has two extra options:
  * `options.prev_l` is the previous value of the left coordinate of the box. Useful for calculating tunelling etc.
  * `options.prev_t` is the the same as `prev_l`, but for the "top" coordinate.

items = world:queryPoint(x,y)
-----------------------------

This method returns the items that touch a given point.

    local items = world:queryPoint(100,100)

It is useful for things like clicking with the mouse.

* `items` is the list items from the ones inserted on the world (like `player`) that contain the point `x,y`.
  If no items touch the point, then `items` will be an empty table. If not empty, then the order of these items is random.
* `x,y` are the coordinates of the point that is being checked

items = world:queryBox(l,t,w,h)
-------------------------------

This method returns the items that touch a given rectangle.

    local items = world:queryBox(0,0,640,480)

Useful for things like selecting what to display on
the screen, or selecting a group of units with the mouse in a strategy game.

* `items` is a list of items, like in `world:queryPoint`. But instead of for a point `x,y` for a retangle `l,t,w,h`.
* `l,t,w,h` is a rectangle. The items that insersect with it will be returned.

l,t,w,h = world:getBox(item)
----------------------------

Given an item, obtain the coordinates of its bounding box.

    local l,t,w,h = world:getBox(player)

Useful for debugging/testing things.

* `l,t,w,h` are the coordinates of the bounding box corresponding to `item`
* `item` is an item that must exist in world (it must have been inserted with `world:add(item ...)`). Otherwise this method will
  throw an error.

items = world:querySegment(x1,y1,x2,y2)
--------------------------------------

Returns the items that touch a segment.

    local items = world:querySegment(100,100,350,200)

It's useful for things like line-of-sight or modelling real-life bullets or lasers.

* `items` is a list of items, similar to `world:queryPoint`, intersecting with the given segment. The difference is that
  in `world:querySegment` the items are sorted by proximity. The ones closest to `x1,y1` appear first, while the ones farther
  away appear later.
* `x1,y1,x2,y2` are the start and end coordinates of the segment.

cx,cy = world:toCell(x,y)
-------------------------

Given a point, return the coordinates of the cell that containg it using the world's `cellSize`.

x,y = world:toWorld(x,y)
-------------------------

The inverse of `world:toCell`. Given the coordinates of a cell, return the coordinates of its top-left corner in the game world.

cell_count = world:countCells()
-------------------------------

Returns the number of cells being used. Useful for testing/debugging.


Installation
============

Just copy the bump.lua file wherever you want it. Then require it where you need it:

    local bump = require 'bump'

If you copied bump.lua to a file not accesible from the root folder (for example a lib folder), change the code accordingly:

    local bump = require 'lib.bump'

Please make sure that you read the license, too (for your convenience it's now included at the beginning of the bump.lua file.


