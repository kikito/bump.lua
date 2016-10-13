package = "bump"
version = "3.1.6-1"
source = {
   url = "git://github.com/kikito/bump.lua",
   tag = "v3.1.6",
   dir = "bump.lua"
}
description = {
   summary = "A collision detection library for Lua",
   detailed = [[
   Bump is a library for for resolving collisions between axis-aligned
   bounding boxes (AABBs). It is ideal for simple games that require
   non-realistic physics.
   ]],
   homepage = "http://github.com/kikito/bump.lua",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      bump = "bump.lua"
   }
}
