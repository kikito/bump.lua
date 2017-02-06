## bump.lua changelog

## v3.1.7

* Fixes rare edge case which was triggered sometimes when two rects shared one corner and one of them moved (#33)

## v3.1.6

* Fixes queryRect accepting rectangles with negative dimensions without raising an error

## v3.1.5

* Fixed a typo inside the bounce code

## v3.1.4

* bump.lua was declaring '_' as a global variable by mistake. Added automated tests to prevent other global vars in the future

## v3.1.3

* Fix floating-point issue when using coordinates like 100.1298374892437, by adding a 10^-10 delta margin in some operations
* Add and remove less stuff when updating an item

## v3.1.2

* Add world:getItems and world:countItems

## v3.1.1

* Bugfix in rect_detectCollision where goalY was not correctly initialized

## v3.1.0

* The `filter` parameter of `world:move`, `world:check` and `world:project` now has the signature `filter(item, other)` instead of `filter(other)`.

## v3.0.0

* Renamed `world:move` to `world:update`
* `world:move()` now implements a basic collision-resolution algorithm - no need for the user to do the "complex loops" he needed to use in 2.0.x
* Collisions no longer have methods. Instead, `filter` now returns "the type of collision", and "move" handles that internally. The collisions are now
  "plain tables", which are returned by `world:move` after all the collisions have been dealt with.
* Added a new type of collision: `cross`, for when it's good to know that a collision happened but item's trajectory should remain unaltered
* `world:check()` does the same thing as `world:move`, except without calling `world:update`. Useful for planning/studying alternatives without moving things.
* `world:project()` now does more or less what `word:check()` did in 2.0.0. It's a key method for collision resolution.
* `world:getRect` now returns 4 integers instead of a table
* Collision detection is handled by the function `rect.detectCollision`.
* The `rect` module is now available to the user.
* It is possible to add new response types to the world


## v2.0.1

* Added `world:hasItem(item)`

## v2.0.0

* Massive interface change:
  * moved the state to worlds
  * Only 1 element can be "moved" at the same time
  * Introduced the concept of "Collision methods"


