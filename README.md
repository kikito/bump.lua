## bump.lua

Lua collision-detection library for axis-aligned rectes. Its main features are:

* Bump only does axis-aligned bounding-box (AABB) collisions. If you need anything more complicated than that (circles, polygons, etc.) give HardonCollider a look.
* Handles tunnelling - all items are treated as "bullets". The fact that we only use AABBs allows doing this fast.
* Strives to be fast and have a small memory footprint
* It's centered on *detection*, but it also offers *minimal collision resolution*
* Can also return the items that touch a point, a segment or a rectangular zone.
* bump.lua is _gameistic_ instead of realistic.

Feel free to poke around!

## Example

```lua
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
local collisions, len = world:check(B)
assert(len == 0)

-- check whether moving B to 100, 100 would make it collide with A
local collisions, len = world:check(B, 50, 0, 100, 100)

-- prints "Collision with A."
for _,col in ipairs(collision) do -- If more than one simultaneous collision, they are sorted out by proximity
  print(("Collision with %s"):format(col.item.name)
end

-- Move B only until it starts touching A on its way to 100, 100
local dx, dy = collisions[1]:getTouch()
world:move(B, dx, dy)

local collisions, len = world:check(B)
assert(len == 0)

-- remove A and B from the world
world:remove(A)
world:remove(B)
```

## Demos

There is a demo showing movement, collision detection and basic touch-based resolution in this branch:

http://github.com/kikito/bump.lua/tree/simpledemo

There's a more complex demo showing more advanced movement mechanics (i.e. acceleration, bouncing) in this other
repo:

http://github.com/kikito/bump.lua/tree/demo

You will need "LÖVE":http://love2d.org in order to try any of them.

## API

### Requiring the library

``` lua
local bump = require 'bump'
```

### Creating a world

``` lua
local world = bump.newWorld()
```

The first thing to do with bump is creating a world. That is done with `bump.newWorld`.

 `bump.newWorld` has one optional parameter, called `cellSize`. It must be a number. It represents the size of the sides
 of the (squared) cells that will be used internally to provide the data. In tile based games, it's usually a multiple of
 the tile side size. So in a game where tiles are 32x32, `cellSize` will be 32, 64 or 128. In more sparse games, it can be
 higher.

 Don't worry too much about that number at the beginning, you can tweak it later on to see if bigger/smaller numbers
 give you better results (you can't change the value of cellSize in runtime, but you can create as many worlds as you need,
 each one with a different cellsize, if the need arises.)

`cellSize`'s default value is 64.

The rest of the methods we have are for the worlds that we create.

### Adding items to the world

``` lua
world:add(item, l,t,w,h)
```

`world:add` is what you need to insert a new item in a world. "Items" are "anything that matters to your collision". It can be the player character,
a tile, a missile etc. In fact, you can insert items that don't participate in the collision at all - like puffs of smoke or background tiles. This
can be handy if you want to use the bump world as a spatial database in addition to a collision detector (see the "queries section" below for mode details).

* `item` is the new item being inserted (usually a table representing a game object, like `player` or `ground_tile`).
* `l,t,w,h` are the dimensions of the item: left, top, width, height. They are all mandatory.

`world:add` returns no values. It generates no collisions - you can call `world:check(item)` after adding the item if that's what you desire.

If you try to add an item to a world that already contains it, you will get an error.


### Removing items from the world

``` lua
world:remove(item)
```

Removes the item from the world.

* `item` must be something previously inserted in the world with `world:add(item, l,t,w,h)`. If this is not the case, `world:remove` will raise an error.

Once removed from the world, the item will stop existing in that world. It won't trigger any collisions with other objects any more. Attempting to move it
with `world:move` or checking collisions with `world:check` will raise an error.

It is ok to remove an object from the world and later add it again. In fact, some bump methods do this internally.

### Moving items in the world

``` lua
world:move(item, l,t,w,h)
```

Moves the item inside the world.

* `item` must be something previously inserted in the world with `world:add(item, l,t,w,h)`. Otherwise, `world:move` will raise an error.
* `l,t,w,h` are the new left, top, width and height coordinates of `item` inside `world`. `l,t` are mandatory, but `w,h` are optional (the width and height will
   remain unchanged if not passed)

This function returns no values.

It is equivalent to doing

``` lua
world:remove(item)
world:add(item, l,t,w,h)
```

except that `w` and `h` will be automatically filled with their existing values if not provided.


### Collision detection

``` lua
local collisions, len = world:check(item, future_l, future_t, filter)
```

It returns an array of collisions, indicating which items collide with `item`

* `item` is the item being checked for collisions. Must be something previously inserted in the world with `world:add(item, l,t,w,h)`, or an error will be raised.
* `future_l` means "next left". It is an optional value. It will be explained with more detail below.
* `future_t` means "next top". It is also optional. It will be explained later.
* `filter` is an optional function. The function only takes one parameter, called `other`, which will be every object with which `item` collides. If `filter` returns `false` or `nil`,
  then `other` will be ignored. The order in which filter is called is not guaranteed. By default all items collide. It is recommended that `filter` executes fast.
* `collisions` is an array of zero or more collisions between `item` and other objects inserted in the world. Each collision has an attribute called `.other`, which
  points to the colliding item. Only one collision per "other" object will be returned. When the item is moving (see below) the collisions will be returned "in order":
  the ones which happen "first along the movement of `item`" will be first in `collisions`.
* `len` is the length of `collisions`. Exactly equivalent to `#collisions` (but a bit more efficient).

`world:check` is the core method of the library, so it requires further explanations.

The only mandatory parameter this method requires is `item`. With no other parameters, this method will return the collisions of the object "as it is in the world".

``` lua
-- Check if the player is colliding with anything in his current position
local collisions, len = world:check(player)
```

In this case, `item` is not moving, and we want to know which other items in the `world` collide with it. The object that "collides" the most (has the most surface overlap)
with item will appear in `collisions[1].other`. The second will appear in `collisions[2].other`, etc. If no object collides with `item`, then `collisions` will
be empty and `len` will be 0.

`future_l` and `future_t` are "possible future values for the left top coordinates of the item". When you pass them, you get "the collisions that will be produced if `item` moves
from its current position to `future_l`, `future_t`".

``` lua
-- Check if the player would collide with anything while it moves to 100, 200
local collisions, len = world:check(player, 100, 200)
```

In this case, `item` (the player) wants to move to `{100, 200}`. If `len` is 0, that means that there are no collisions and it can move there freely. Otherwise, `len` will be
greater than 0, and the `collisions` table can be used to sort out exactly what happens with the player (more about this on the "Resolution" section). This form of collision
detection is able to detect tunnelling (even if `item` moves "very fast", it will still collide with other objects).

Note that `world:check` does *not* move the item at all - you will have to move it with `world:move`.

The last parameter is straightforward: any "possible candidate" to collide with `item` will be passed to this
function if it exists. If the function returns `true`, then the candidate will be ignored.

``` lua
-- Check if the player would collide with anything while it moves to 100, 200
-- Ignore enemies if the player is invincible (will still collide with the ground, walls, etc)
local collisions, len = world:check(player, 100, 200, function(other)
  return player.invincible and other.isEnemy
end)
```

### Collision resolution

`world:check()` returns a list of zero or more `Collision` objects. A `Collision` object is a Lua table with at least the
following attributes:

* `col.item`: the item that was being tested for collisions (the first parameter passed to `world:check(item, ...)`)
* `col.other`: the item that has been found colliding with `item`
* `col.future_l` & `col.future_t`: the `future_l` and `future_t` parameters passed to `world:check`.
* `col.itemRect` & `col.otherRect`: the bounding rectes of the items, in the form `{l=...,t=...,w=...,h=...}`.
* `col.is_intersection`: `true` if `item` and `other` are currently intersecting in the world. `false` if the collision
  is a "tunnelling collision" - `item` will collides with `other` when it travels from its current position to `{future_l, future_t}`,
  but it is not presently intersecting with `other`.
* `col.vx`: the difference between `item`'s "current `left`" and `future_l`
* `col.vy`: the difference between `item`'s "current `top`" and `future_t`

The most interesting attribute is `col.other`. In some cases it is more than enough - for example if `item` is one of those bullets
that disappear when impacting the player, you don't need to know more - you must make the bullet disappear. But in other cases you
need to *resolve* the collision.

Bump collisions have 3 ways of resolving collisions: touch, slide and bounce.

``` lua
local tl, tt, nx, ny = col:getTouch()
```
Returns the coordinates to which you would have to move `item` so that it "touches" (without colliding) `other`.

![touch](https://raw.githubusercontent.com/kikito/bump.lua/2.0/img/touch.svg)

This type of collision resolution is the fastest one. It is useful for things like arrows that "get stuck" on their targets, or
as a complement to the other resolutions.

* `tl`, `tt`: The left, top coordinates to which `item` can be moved.
* `nx`, `ny`: The "normal" of the collision. `nx` can only be `1`(right), `0`(nothing) or `-1`(left). `ny` can be `1`(down), `0`(nothing) or `-1`(up).
  `nx` and `ny` can not be 0 at the same time.

``` lua
local tl, tt, nx, ny, sl, st = col:getSlide()
```
This is the type of collision resolution used by objects that "slide" over other objects after colliding with them.

A prime example of this is Super Mario (he "slides" over the floor instead of "getting stuck on it", like an arrow would).

![slide](https://raw.githubusercontent.com/kikito/bump.lua/2.0/img/slide.svg)

* `tl, tt, nx, ny`: Same as in `col:getTouch()`
* `sl, st`: The left,top coordinates of `item` after it finishes sliding over `other`.

This is a slightly more complex resolution: `item` first "touches" `other`, and then uses its remaining "displacement vector" to "slide over `other`".

``` lua
local tl, tt, nx, ny, bl, bt = col:getSlide()
```
This is the type of collision resolution used by objects that "bounce".

A good example of this behavior is Arkanoid's ball.

![bounce](https://raw.githubusercontent.com/kikito/bump.lua/2.0/img/slide.svg)

* `tl, tt, nx, ny`: Same as in `col:getTouch()`
* `bl, bt`: The left,top coordinates of `item` after it finishes bouncing. It is very possible that after bouncing, it doesn't touch `other` any more.

### Querying the world

Sometimes it is desirable to know "which items are in a certain area". This is called "querying the world".

Bump allows querying the world via a point, a rectangular zone, and a straight line segment.

``` lua
local items, len = world:queryPoint(x,y, filter)
```
Returns the items that touch a given point.

It is useful for things like clicking with the mouse.

* `x,y` are the coordinates of the point that is being checked
* `items` is the list items from the ones inserted on the world (like `player`) that contain the point `x,y`.
  If no items touch the point, then `items` will be an empty table. If not empty, then the order of these items is random.
* `filter` is an optional function. It takes one parameter (an item). `queryPoint` will not return the items that return
  `false` or `nil` on `filter(item)`. By default, all items touched by the point are returned.
* `len` is the length of the items list. It is equivalent to `#items`, but it's slightly faster to use `len` instead.

``` lua
local items, len = world:queryRect(l,t,w,h, filter)
```
Returns the items that touch a given rectangle.

Useful for things like selecting what to display on
the screen, or selecting a group of units with the mouse in a strategy game.

* `l,t,w,h` is a rectangle. The items that intersect with it will be returned.
* `filter` is an optional function. When provided, it is used to "filter out" which items are returned - if `filter(item)` returns
  `false` or `nil`, that item is ignored. By default, all items are included.
* `items` is a list of items, like in `world:queryPoint`. But instead of for a point `x,y` for a rectangle `l,t,w,h`.
* `len` is equivalent to `#items`

``` lua
local items, len = world:querySegment(x1,y1,x2,y2,filter)
```
Returns the items that touch a segment.

It's useful for things like line-of-sight or modelling real-life bullets.

* `x1,y1,x2,y2` are the start and end coordinates of the segment.
* `filter` is an optional function. When provided, it is used to "filter out" which items are returned - if `filter(item)` returns
  `false` or `nil`, that item is ignored. By default, all items are included.
* `items` is a list of items, similar to `world:queryPoint`, intersecting with the given segment. The difference is that
  in `world:querySegment` the items are sorted by proximity. The ones closest to `x1,y1` appear first, while the ones farther
  away appear later.
* `len` is equivalent to `#items`.


``` lua
local itemInfo, len = world:querySegmentWithCoords(x1,y1,x2,y2)
```
An extended version of `world:querySegment` which returns the collision points of the segment with the items,
in addition to the items.

It is useful if you need to **actually show** the lasers/bullets or if you need to show some impact effects (i.e. spawning some particles
where a bullet hits a wall). If you don't need the actual points of contact between the segment and the bounding rectes, use
`world:querySegment`, since it's faster.

* `x1,y1,x2,y2,filter` same as in `world:querySegment`
* `itemInfo` is a list of tables. Each element in the table has the following elements: `item`, `x1`, `y1`, `x2`, `y2`, `t0` and `t1`.
  * `info.item` is the item being intersected by the segment.
  * `info.x1,info.y1` are the coordinates of the first intersection between `item` and the segment
  * `info.x2,info.y2` are the coordinates of the second intersection between `item` and the segment
  * `info.ti1` & `info.ti2` are numbers between 0 and 1 which say "how far from the starting point of the segment did the impact happen"
* `len` is equivalent to `#itemInfo`.

Most people will only need `info.item`, `info.x1` and `info.y1`. `info.x2` and `info.y2` are useful if you also need to show "the exit point
of a shoot", for example. `info.ti1` and `info.ti2` give an idea about the distance to the origin, so they can be used for things like
calculating the intensity of a shooting that becomes weaker with distance.

### Misc functions

``` lua
local rect = world:getRect(item)
```

Given an item, obtain the coordinates of its bounding rect.
Useful for debugging/testing things.

* `item` is an item that must exist in world (it must have been inserted with `world:add(item ...)`). Otherwise this method will
  throw an error.
* `rect` is a lua table in the form `{l=... , t=... , w=... , h=...}`

``` lua
local cell_count = world:countCells()
```

Returns the number of cells being used. Useful for testing/debugging.

### Grid functions

``` lua
local cx,cy = world:toCell(x,y)
```

Given a point, return the coordinates of the cell that containg it using the world's `cellSize`. Useful mostly for debugging bump, or drawing
debug info.

``` lua
local x,y = world:toWorld(x,y)
```

The inverse of `world:toCell`. Given the coordinates of a cell, return the coordinates of its top-left corner in the game world.


## Installation

Just copy the bump.lua file wherever you want it. Then require it where you need it:

``` lua
local bump = require 'bump'
```

If you copied bump.lua to a file not accesible from the root folder (for example a lib folder), change the code accordingly:

``` lua
local bump = require 'lib.bump'
```

Please make sure that you read the license, too (for your convenience it's now included at the beginning of the bump.lua file.

## License

bump.lua is licensed under the MIT license.

## Specs

Specs for this project can be run using [busted](http://olivinelabs.com/busted).


