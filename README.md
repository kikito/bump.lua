# bump.lua

[![Build Status](https://travis-ci.org/kikito/bump.lua.svg?branch=master)](https://travis-ci.org/kikito/bump.lua)
[![Coverage Status](https://coveralls.io/repos/github/kikito/bump.lua/badge.svg?branch=master)](https://coveralls.io/github/kikito/bump.lua?branch=master)

Lua collision-detection library for axis-aligned rectangles. Its main features are:

* bump.lua only does axis-aligned bounding-box (AABB) collisions. If you need anything more complicated than that (circles, polygons, etc.) give [HardonCollider](https://github.com/vrld/HardonCollider) a look.
* Handles tunnelling - all items are treated as "bullets". The fact that we only use AABBs allows doing this fast.
* Strives to be fast while being economic in memory.
* It's centered on *detection*, but it also offers some (minimal & basic) *collision response*.
* Can also return the items that touch a point, a segment or a rectangular zone.
* bump.lua is _gameistic_ instead of realistic.

The demos are LÖVE based, but this library can be used in any Lua-compatible environment.

`bump` is ideal for:

* Tile-based games, and games where most entities can be represented as axis-aligned rectangles.
* Games which require some physics, but not a full realistic simulation - like a platformer.
* Examples of genres: top-down games (Zelda), shoot 'em ups, fighting games (Street Fighter), platformers (Super Mario).

`bump` is not a good match for:

* Games that require polygons for the collision detection.
* Games that require highly realistic simulations of physics - things "stacking up", "rolling over slides", etc.
* Games that require very fast objects colliding realistically against each other (in bump, being _gameistic_, objects are moved and collided _one at a time_).
* Simulations where the order in which the collisions are resolved isn't known.

## Example

```lua

local bump = require 'bump'

-- The grid cell size can be specified via the initialize method
-- By default, the cell size is 64
local world = bump.newWorld(50)

-- create two rectangles
local A = {name="A"}
local B = {name="B"}

-- insert both rectangles into bump
world:add(A,   0, 0,    64, 256) -- x,y, width, height
world:add(B,   0, -100, 32, 32)

-- Try to move B to 0,64. If it collides with A, "slide over it"
local actualX, actualY, cols, len = world:move(B, 0,64)

-- prints "Attempted to move to 0,64, but ended up in 0,-32 due to 1 collisions"
if len > 0 then
  print(("Attempted to move to 0,64, but ended up in %d,%d due to %d collisions"):format(actualX, actualY, len))
else
  print("Moved B to 100,100 without collisions")
end

-- prints the new coordinates of B: 0, -32, 32, 32
print(world:getRect(B))

-- prints "Collision with A"
for i=1,len do -- If more than one simultaneous collision, they are sorted out by proximity
  local col = cols[i]
  print(("Collision with %s."):format(col.other.name))
end

-- remove A and B from the world
world:remove(A)
world:remove(B)
```

## Demos

There is a demo showing movement, collision detection and basic slide-based resolution in this branch:

http://github.com/kikito/bump.lua/tree/simpledemo

![simpledemo](https://kikito.github.io/bump.lua/img/bump-simpledemo.gif)

There's a more complex demo showing more advanced movement mechanics (i.e. acceleration, bouncing) in this other
repo:

http://github.com/kikito/bump.lua/tree/demo

![demo](https://kikito.github.io/bump.lua/img/bump-demo.gif)

You will need [LÖVE](http://love2d.org) in order to try any of them.

## Basic API - Adding, removing and moving items

### Requiring the library

``` lua
local bump = require 'bump'
```

The following methods (`bump.newWorld`, `world:add`, `world:remove`, `world:update`, `world:move` & `world:check`) are *basic* for
working with bump, as well as the 4 collision responses. If you want to use bump.lua effectively, you will need to understand at least
these.

### Creating a world

``` lua
local world = bump.newWorld(cellSize)
```

The first thing to do with bump is creating a world. That is done with `bump.newWorld`.

* `cellSize`. Is an optional number. It defaults to 64. It represents the size of the sides
  of the (squared) cells that will be used internally to provide the data. In tile-based games, it's usually a multiple of
  the tile side size. So in a game where tiles are 32x32, `cellSize` will be 32, 64 or 128. In more sparse games, it can be
  higher.

Don't worry too much about `cellSize` at the beginning, you can tweak it later on to see if bigger/smaller numbers
give you better results (you can't change the value of `cellSize` in runtime, but you can create as many worlds as you want,
each one with a different `cellSize` if the need arises.)

The rest of the methods we have are for the worlds that we create.

### Adding items to the world

``` lua
world:add(item, x,y,w,h)
```

`world:add` is what you need to insert a new item in a world. "Items" are "anything that matters to your collision". It can be the player character,
a tile, a missile etc. In fact, you can insert items that don't participate in the collision at all - like puffs of smoke or background tiles. This
can be handy if you want to use the bump world as a spatial database in addition to a collision detector (see the "queries section" below for more details).

Each `item` will have an associated "rectangle" in the `world`.

* `item` is the new item being inserted (usually a table representing a game object, like `player` or `ground_tile`).
* `x,y,w,h`: the rectangle associated to `item` in the world. They are all mandatory. `w` & `h` are the "width" and "height"
  of the box. `x` and `y` depend on the host system's coordinate system. For example, in [LÖVE](http://love2d.org) &
  [Corona SDK](http://coronalabs.com/products/corona-sdk/) they represent "left" & "top", while in [Cocos2d-x](http://cocos2d-x.org/wiki/Lua)
  they represent "left" & "bottom".

`world:add` returns no values. It generates no collisions - you can call `world:check(item)` if you want to get the collisions it creates right after it's added.

If you try to add an item to a world that already contains it, you will get an error.


### Removing items from the world

``` lua
world:remove(item)
```

bump.lua stores *hard references* to any items that you add (with `world:add`). If you decide that a item is no longer necessary, in addition to removing it
from your "entity list", you must also remove it from the world using `world:remove`. Otherwise it will still be there, and other objects might still collide
with it.

* `item` must be something previously inserted in the world with `world:add(item, l,t,w,h)`. If this is not the case, `world:remove` will raise an error.

Once removed from the world, the item will stop existing in that world. It won't trigger any collisions with other objects any more. Attempting to move it
with `world:move` or checking collisions with `world:check` will raise an error.

It is OK to remove an object from the world and later add it again. In fact, some bump methods do this internally.

This method returns nothing.

### Changing the position and dimensions of items in the world

``` lua
world:update(item, x,y,<w>,<h>)
```

Even if your "player" has attributes like `player.x` and `player.y`, changing those will not automatically change them inside `world`. `update` is one of
the ways to do so: it changes the rect representing `item` inside `world`.

* `item` must be something previously inserted in the world with `world:add(item, l,t,w,h)`. Otherwise, `world:update` will raise an error.
* `x,y,w,h` the new dimensions of `item`. `x` and `y` are mandatory. `w` and `h` will default to the values the world already had for `item`.

This method always changes the rect associated to `item`, ignoring all collisions (use `world:move` for that). It returns nothing.

You may use `world:update` if you want to "teleport" your items around. A lot of time, however, you want to move them taking collisions into account.
In order to do that, you have `world:move`.


### Moving an item in the world, with collision resolution

``` lua
local actualX, actualY, cols, len = world:move(item, goalX, goalY, <filter>)
```

This is probably the most useful method of bump. It moves the item inside the world towards a desired position, but taking collisions into account.

* `item` must be something previously inserted in the world with `world:add(item, l,t,w,h)`. Otherwise, `world:move` will raise an error.
* `goalX, goalY` are the *desired* `x` and `y` coordinates. The item will end up in those coordinates if it doesn't collide with anything.
  If, however, it collides with 1 or more other items, it can end up in a different set of coordinates.
* `filter` is an optional function. If provided, it must have this signature: `local type = filter(item, other)`. By default, `filter` always returns `"slide"`.
  * `item` is the item being moved (the same one passed to `world:move` on the first param).
  * `other` is an item (different from `item`) which can collide with `item`.
  * `type` is a value which defines how `item` collides with `other`.
    * If `type` is `false` or `nil`, `item` will ignore `other` completely (there will be no collision).
    * If `type` is `"touch"`, `"cross"`, `"slide"` or `"bounce"`, `item` will respond to the collisions in different ways (explained below).
    * Any other value (unless handled in an advanced way) will provoke an error.

* `actualX, actualY` are the coordinates where the object ended up after colliding with other objects in the world while trying to get to
  `goalX, goalY`. They can be equal to `goalX, goalY` if, for example, no collisions happened.
* `len` is the amount of collisions produced. It is equivalent to `#cols`.
* `cols` is an array of all the collisions that were detected. Each collision is a table. The most important item in that table is `cols[i].other`, which
  points to the item that collided with `item`. A full description of what's inside of each collision can be found on the "Advanced API" section.

The usual way you would use move is: calculate a "desirable" `goalX, goalY` point for an item (maybe using its velocity), pass it to move, and then use `actualX, actualY`
as the real "updates". For example, here's how a player would move:

``` lua
function movePlayer(player, dt)
  local goalX, goalY = player.x + player.vx * dt, player.y + player.vy * dt
  local actualX, actualY, cols, len = world:move(player, goalX, goalY)
  player.x, player.y = actualX, actualY
  -- deal with the collisions
  for i=1,len do
    print('collided with ' .. tostring(cols[i].other))
  end
end
```

Notice that if `filter` returns `nil` or `false`, it is guaranteed that `other` will not produce a collision. But the opposite is not true: it is possible that `filter` returns
`"slide"`, and yet no collision is produced. This is because `filter` is applied to *all the neighbors of `item`*, that is, all the items that "touch" the same cells as item. Some
of them might be on the same cells, but still not collide with item..

#### Collision Resolution

For each of the collisions returned by `world:move`, the most interesting attribute is `cols[i].other`. Often it's enough with it - for example if `item`
is one of those bullets that disappear when impacting the player you must make the bullet disappear (and decrease the player's health).

`world:move()` returns a list (instead of a single collision element) because in some cases you might want to "skip" some
collisions, or react to several of them in a single frame.

For example, imagine a player which collides on the same frame with a coin first, an enemy fireball, and the floor.

* since `cols[1].other` will be a coin, you will want to make the coin disappear (maybe with a sound) and increase the player's score.
* `cols[2].other` will be a fireball, so you will want to decrease the player's health and make the fireball disappear.
* `cols[3].other` will be a ground tile, so you will need to stop the player from "falling down", and maybe align it with the ground.

The first two can be handled just by using `col.other`, but "aligning the player with the ground" requires *collision resolution*.

bump.lua comes with 4 built-in ways to handle collisions: `touch`, `cross`, `slide` & `bounce`. You can select which one is used on each collision by returning
their name in the `filter` param of `world:move` or `world:check`. You can also choose to ignore a collision by returning `nil` or `false`.

![touch](img/touch.png)

This is the type of collision for things like arrows or bullets; things that "get stuck" on their targets.

Collisions of this type have their `type` attribute set to `"touch"` and don't have any additional information apart from the the default one, shared by all collisions (see below).

![cross](img/cross.png)

This type of collision is for cases where you want to detect a collision but you don't want any response. It is useful for things like: detecting that the player has entered a new area,
or consumables (i.e. coins) which usually don't affect the player's trajectory, but it's still useful to know then they are collided with.

Collisions of this type have their `type` attribute set to `"cross"` and don't have any additional information apart from the the default one, shared by all collisions (see below).

![slide](img/slide.png)

This is the default collision type used in bump. It's what you want to use for solid objects which "slide over other objects", like Super Mario does over a platform or the ground.

Collisions of this type have their `type` attribute set to `"slide"`. They also have a special attribute called `col.slide`, which is a 2D vector with two components: `col.slide.x` &
`col.slide.y`. It represents the x and y coordinates to which the `item` "attempted to slide to". They are different from `actualX` & `actualY` since other collisions later on can
modify them.

![bounce](img/bounce.png)

A good example of this behavior is Arkanoid's ball; you can use this type of collision for things that "move away" after touching others.

Collisions of this type have their `type` attribute set to `"bounce"`. They also have a special attributes called `col.bounce`. It is a 2D vector which represents the x and y
coordinates to which the `item` "attempted to bounce".

The [Grenades](https://github.com/kikito/bump.lua/blob/demo/entities/grenade.lua) and the [Debris](https://github.com/kikito/bump.lua/blob/demo/entities/debris.lua) in the
demo use `"bounce"` to resolve their collisions.

Here's an example of a filter displaying all these behaviors:

```lua
local playerFilter = function(item, other)
  if     other.isCoin   then return 'cross'
  elseif other.isWall   then return 'slide'
  elseif other.isExit   then return 'touch'
  elseif other.isSpring then return 'bounce'
  end
  -- else return nil
end
```

The code above will make a character work more or less like super-mario, collision-wise. It'll go through coins, collide with walls, bounce over springs, etc., ignoring things it should
not collide with like clouds in the background.

You could then use the collisions returned like so:

``` lua
function movePlayer(player, dt)
  local goalX, goalY = player.vx * dt, player.vy * dt
  local actualX, actualY, cols, len = world:move(player, goalX, goalY, playerFilter)
  player.x, player.y = actualX, actualY
  for i=1,len do
    local other = cols[i].other
    if other.isCoin then
      takeCoin(other)
    elseif other.isExit then
      changeLevel()
    elseif other.isSpring then
      highJump()
    end
  end
end
```

### Checking for collisions without moving

``` lua
local actualX, actualY, cols, len = world:check(item, goalX, goalY, <filter>)
```

It returns the position where `item` would end up, and the collisions it would encounter, should it attempt to move to `goalX, goalY` with the specified `filter`.

Notice that `check` has the same parameters and return values as `move`. The difference is that the former does not update the position of `item` in the world - you
would have to call `world:update` in order to do that. In fact, `world:move` is implemented by calling `world:check` first, and then `world:update` immediately after.

The equivalent code to the previous example using `check` would be:

``` lua
function movePlayer(player, dt)
  local goalX, goalY = player.vx * dt, player.vy * dt
  local actualX, actualY, cols, len = world:check(player, goalX, goalY)
  world:update(player, actualX, actualY) -- update the player's rectangle in the world
  player.x, player.y = actualX, actualY
  ... <deal with the collisions as before>
end
```

`world:check` is useful for things like "planning ahead" or "studying alternatives", when moving is still not fully decided.


### Collision info

Here's the info contained on every collision item contained in the `cols` variables mentioned above:

```lua
cols[i] = {
  item  = the item being moved / checked
  other = an item colliding with the item being moved
  type  = the result of `filter(other)`. It's usually "touch", "cross", "slide" or "bounce"
  overlaps  = boolean. True if item "was overlapping" other when the collision started.
              False if it didn't but "tunneled" through other
  ti        = Number between 0 and 1. How far along the movement to the goal did the collision occur?
  move      = Vector({x=number,y=number}). The difference between the original coordinates and the actual ones.
  normal    = Vector({x=number,y=number}). The collision normal; usually -1,0 or 1 in `x` and `y`
  touch     = Vector({x=number,y=number}). The coordinates where item started touching other
  itemRect  = The rectangle item occupied when the touch happened({x = N, y = N, w = N, h = N})
  otherRect = The rectangle other occupied when the touch happened({x = N, y = N, w = N, h = N})
}
```

Note that collisions of type `slide` and `bounce` have some additional fields. They are described
on each response's section above.

Most of this info is useful only if you are doing semi-advanced stuff with collisions, but they could have some uses.

For example, `cols[i].normal` could be used to "detect if a player is on ground or not". `cols[i].touch` could be used to
"spawn a puff of dust when a player touches ground after a fall", and so on.

## Intermediate API - Querying the world

The following methods are not required for basic usage of bump.lua, but are quite handy, and you would be missing out some
nice features of this lib if you were not using it.

Sometimes it is desirable to know "which items are in a certain area". This is called "querying the world".

Bump allows querying the world via a point, a rectangular zone, and a straight line segment.

This makes it useful not only as a collision detection library, but also as a lightweight spatial dictionary. In particular,
you can use bump to "only draw the things that are needed" on the screen. In order to do this, you would have to add all your
"visible" objects into bump, even if they don't collide with anything (this is usually OK, just ignore them with your filters when
you do the collisions).

### Querying with a point

``` lua
local items, len = world:queryPoint(x,y, filter)
```
Returns the items that touch a given point.

It is useful for things like clicking with the mouse and getting the items affected.

* `x,y` are the coordinates of the point that is being checked
* `items` is the list items from the ones inserted on the world (like `player`) that contain the point `x,y`.
  If no items touch the point, then `items` will be an empty table. If not empty, then the order of these items is random.
* `filter` is an optional function. It takes one parameter (an item). `queryPoint` will not return the items that return
  `false` or `nil` on `filter(item)`. By default, all items touched by the point are returned.
* `len` is the length of the items list. It is equivalent to `#items`, but it's slightly faster to use `len` instead.

### Querying with a rectangle

``` lua
local items, len = world:queryRect(l,t,w,h, filter)
```
Returns the items that touch a given rectangle.

Useful for things like selecting what to display on the screen, as mentioned above, or selecting a group of units with the mouse in a strategy game.

* `l,t,w,h` is a rectangle. The items that intersect with it will be returned.
* `filter` is an optional function. When provided, it is used to "filter out" which items are returned - if `filter(item)` returns
  `false` or `nil`, that item is ignored. By default, all items are included.
* `items` is a list of items, like in `world:queryPoint`. But instead of for a point `x,y` for a rectangle `l,t,w,h`.
* `len` is equivalent to `#items`

### Querying with a segment

``` lua
local items, len = world:querySegment(x1,y1,x2,y2,filter)
```
Returns the items that touch a segment.

It's useful for things like line-of-sight or modelling bullets or lasers.

* `x1,y1,x2,y2` are the start and end coordinates of the segment.
* `filter` is an optional function. When provided, it is used to "filter out" which items are returned - if `filter(item)` returns
  `false` or `nil`, that item is ignored. By default, all items are included.
* `items` is a list of items, similar to `world:queryPoint`, intersecting with the given segment. The difference is that
  in `world:querySegment` the items are sorted by proximity. The ones closest to `x1,y1` appear first, while the ones farther
  away appear later.
* `len` is equivalent to `#items`.

### Querying with a segment (with more detailed info)

``` lua
local itemInfo, len = world:querySegmentWithCoords(x1,y1,x2,y2)
```
An extended version of `world:querySegment` which returns the collision points of the segment with the items,
in addition to the items.

It is useful if you need to **actually show** the lasers/bullets or if you need to show some impact effects (i.e. spawning some particles
where a bullet hits a wall). If you don't need the actual points of contact between the segment and the bounding rectangles, use
`world:querySegment`, since it's faster.

* `x1,y1,x2,y2,filter` same as in `world:querySegment`.
* `itemInfo` is a list of tables. Each element in the table has the following elements: `item`, `x1`, `y1`, `x2`, `y2`, `t0` and `t1`.
  * `info.item` is the item being intersected by the segment.
  * `info.x1,info.y1` are the coordinates of the first intersection between `item` and the segment.
  * `info.x2,info.y2` are the coordinates of the second intersection between `item` and the segment.
  * `info.ti1` & `info.ti2` are numbers between 0 and 1 which say "how far from the starting point of the segment did the impact happen".
* `len` is equivalent to `#itemInfo`.

Most people will only need `info.item`, `info.x1` and `info.y1`. `info.x2` and `info.y2` are useful if you also need to show "the exit point
of a shoot", for example. `info.ti1` and `info.ti2` give an idea about the distance to the origin, so they can be used for things like
calculating the intensity of a shooting that becomes weaker with distance.


## Advanced API

The following methods are advanced and/or used internally by the library; most people will not need them.

``` lua
local result = world:hasItem(item)
```
Returns whether the world contains the given item or not. This function does not throw an error if `item` is not included in `world`; it just returns `false`.

``` lua
local count = world:countItems()
```
Returns the number of items inserted in the world. Useful for debugging.

``` lua
local items, len = world:getItems()
```
Builds and returns an array containing all the items in the world (as well as its length). This can be useful if you want to draw or update all the items in the world, without
doing any queries. Notice that the order in which the items will be returned is non-deterministic.

``` lua
local x,y,w,h = world:getRect(item)
```
Given an item, obtain the coordinates of its bounding rect. Useful for debugging/testing things.

``` lua
local cell_count = world:countCells()
```

Returns the number of cells being used. Useful for testing/debugging.

``` lua
local cx,cy = world:toCell(x,y)
```

Given a point, return the coordinates of the cell that contains it using the world's `cellSize`. Useful mostly for debugging bump, or drawing
debug info.

``` lua
local x,y = world:toWorld(x,y)
```

The inverse of `world:toCell`. Given the coordinates of a cell, return the coordinates of its main corner (top-left in LÖVE and Corona SDK, bottom-left in Cocos2d-x) in the game world.

``` lua
local cols, len = world:project(item, x,y,w,h, goalX, goalY, filter)
```

Moves a the given imaginary rectangle towards goalX and goalY, providing a list of collisions as they happen *in that straight path*.

This method is useful mostly when creating new collision responses, although it could be also used as a query method.

You could use this method to implement your own collision response algorithm (this was the only way to
do it in previous versions of bump)

```lua
bump.responses.touch
bump.responses.cross
bump.responses.slide
bump.responses.bounce
```

These are the functions bump uses to resolve collisions by default. You can use these functions' source as a base to build your own response function, if you feel adventurous.

```lua
world:addResponse(name, response)
```

This is how you register a new type of response in the world. All worlds come with the 4 pre-defined responses already installed, but you can add your own: if you register the
response `'foo'`, if your filter returns `'foo'` in a collision your world will handle it with `response`. This, however, is advanced stuff, and you
will have to read the source code of the default responses in order to know how to do that.

```lua
bump.rect.getNearestCorner
bump.rect.getSegmentIntersectionIndices
bump.rect.getDiff
bump.rect.containsPoint
bump.rect.isIntersecting
bump.rect.getSquareDistance
bump.rect.detectCollision
```

bump.lua comes with some rectangle-related functions in the `bump.rect` namespace. These are **not** part of the official API and can change at any moment. However, feel free to
use them if you are implementing your own collision responses.

## Installation

Just copy the bump.lua file wherever you want it. Then require it where you need it:

``` lua
local bump = require 'bump'
```

If you copied bump.lua to a file not accessible from the root folder (for example a lib folder), change the code accordingly:

``` lua
local bump = require 'lib.bump'
```

Please make sure that you read the license, too (for your convenience it's now included at the beginning of the bump.lua file.

## License

bump.lua is licensed under the MIT license.

## Specs

Specs for this project can be run using [busted](http://olivinelabs.com/busted).


## Changelog

See CHANGELOG.md for details


