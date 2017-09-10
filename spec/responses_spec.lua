local bump            = require('bump')
local detect          = bump.rect.detectCollision
local responses  = bump.responses

local world = bump.newWorld()

local touch = function(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  local col = detect(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  return {col.touch.x, col.touch.y, col.normal.x, col.normal.y}
end

local slide = function(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  local col = detect(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  responses.slide(world, col, x, y, w, h, goalX, goalY)
  return {col.touch.x, col.touch.y, col.normal.x, col.normal.y, col.slide.x, col.slide.y}
end

local bounce = function(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  local col = detect(x,y,w,h, ox,oy,ow,oh, goalX, goalY)
  responses.bounce(world, col, x, y, w, h, goalX, goalY)
  return {col.touch.x, col.touch.y, col.normal.x, col.normal.y, col.bounce.x, col.bounce.y }
end

describe('bump.responses', function()
  describe('touch', function()
    describe('when resolving collisions', function()
      describe('on overlaps', function()
        describe('when there is no movement', function()
          it('returns the left,top coordinates of the minimum displacement on static items', function()

            --                                          -2-1 0 1 2 3 4 5 6 7 8 9 10
            --      -2 -1 0 1 2 3 4 5 6 7 8 9           -2 · ┌–––┐ · ┌–––┐ · ┌–––┐ ·
            --      -1  ┌–––┐ · ┌–––┐ · ┌–––┐           -1 · │0-1│ · │0-1│ · │0-1│ ·
            --       0  │ ┌–––––––––––––––┐ │ 1  2  3    0 · └–┌–––––––––––––––┐–┘ ·
            --       1  └–│–┘ · └–––┘ · └–│–┘            1 · · │ · · · · · · · │ · ·
            --       2  · │ · · · · · · · │ ·            2 · · │ · · · · · · · │ · ·
            --       3  ┌–│–┐ · ┌–––┐ · ┌–│–┐            3 ┌–––│ · · · · · · · │–––┐
            --       4  │ │ │ · │ · │ · │ │ │ 4  5  6    4 -1 0│ · · · · · · · │1 0│
            --       5  └–│–┘ · └–––┘ · └–│–┘            5 └–––│ · · · · · · · │–––┘
            --       6  · │ · · · · · · · │ ·            6 · · │ · · · · · · · │ · ·
            --       7  ┌–│–┐ · ┌–––┐ · ┌–│–┐            7 · · │ · · · · · · · │ · ·
            --       8  │ └–––––––––––––––┘ │ 7  8  9    8 · ┌–└–––––––––––––––┘–┐ ·
            --       9  └–––┘ · └–––┘ · └–––┘            9 · │0 1│ · ╎0 1╎ · │0 1│ ·
            --      10                                  10 · └–––┘ · └╌╌╌┘ · └–––┘ ·

            assert.same(touch(-1,-1,2,2, 0,0,8,8), {-1,-2, 0, -1}) -- 1
            assert.same(touch( 3,-1,2,2, 0,0,8,8), { 3,-2, 0, -1}) -- 2
            assert.same(touch( 7,-1,2,2, 0,0,8,8), { 7,-2, 0, -1}) -- 3

            assert.same(touch(-1, 3,2,2, 0,0,8,8), {-2, 3, -1, 0}) -- 4
            assert.same(touch( 3, 3,2,2, 0,0,8,8), { 3, 8,  0, 1}) -- 5
            assert.same(touch( 7, 3,2,2, 0,0,8,8), { 8, 3,  1, 0}) -- 6

            assert.same(touch(-1, 7,2,2, 0,0,8,8), {-1, 8,  0, 1}) -- 7
            assert.same(touch( 3, 7,2,2, 0,0,8,8), { 3, 8,  0, 1}) -- 8
            assert.same(touch( 7, 7,2,2, 0,0,8,8), { 7, 8,  0, 1}) -- 9

          end)
        end)

        describe('when the item is moving', function()
          it('returns the left,top coordinates of the overlaps with the movement line, opposite direction', function()
            assert.same(touch(3,3,2,2, 0,0,8,8, 4, 3), { -2,  3, -1,  0})
            assert.same(touch(3,3,2,2, 0,0,8,8, 2, 3), {  8,  3,  1,  0})
            assert.same(touch(3,3,2,2, 0,0,8,8, 2, 3), {  8,  3,  1,  0})
            assert.same(touch(3,3,2,2, 0,0,8,8, 3, 4), {  3, -2,  0, -1})
            assert.same(touch(3,3,2,2, 0,0,8,8, 3, 2), {  3,  8,  0,  1})
          end)
        end)
      end)

      describe('on tunnels', function()
        it('returns the coordinates of the item when it starts touching the other, and the normal', function()
          assert.same(touch(-3, 3,2,2, 0,0,8,8, 3,3), { -2,  3, -1,  0})
          assert.same(touch( 9, 3,2,2, 0,0,8,8, 3,3), {  8,  3,  1,  0})
          assert.same(touch( 3,-3,2,2, 0,0,8,8, 3,3), {  3, -2,  0, -1})
          assert.same(touch( 3, 9,2,2, 0,0,8,8, 3,3), {  3,  8,  0,  1})
        end)
      end)
    end)
  end)

  describe('slide', function()
    it('slides on overlaps', function()
      assert.same(slide(3,3,2,2, 0,0,8,8, 4, 5), { 0.5, -2, 0,-1, 4, -2})
      assert.same(slide(3,3,2,2, 0,0,8,8, 5, 4), { -2, 0.5, -1,0, -2, 4})
      assert.same(slide(3,3,2,2, 0,0,8,8, 2, 1), { 5.5, 8, 0,1, 2, 8})
      assert.same(slide(3,3,2,2, 0,0,8,8, 1, 2), { 8, 5.5, 1,0, 8, 2})
    end)

    it('slides over tunnels', function()
      assert.same(slide(10,10,2,2, 0,0,8,8, 1, 4), { 7, 8, 0, 1, 1, 8})
      assert.same(slide(10,10,2,2, 0,0,8,8, 4, 1), { 8, 7, 1, 0, 8, 1})

      -- perfect corner case:
      assert.same(slide(10,10,2,2, 0,0,8,8, 1, 1), { 8, 8, 1, 0, 8, 1})
    end)
  end)

  describe('bounce', function()
    it('bounces on overlaps', function()
      assert.same(bounce( 3, 3,2,2, 0,0,8,8, 4, 5), { 0.5, -2, 0,-1, 4, -9})
      assert.same(bounce( 3, 3,2,2, 0,0,8,8, 5, 4), { -2, 0.5, -1,0, -9, 4})
      assert.same(bounce( 3, 3,2,2, 0,0,8,8, 2, 1), { 5.5, 8, 0,1, 2, 15})
      assert.same(bounce( 3, 3,2,2, 0,0,8,8, 1, 2), { 8, 5.5, 1,0, 15,2})
    end)

    it('bounces over tunnels', function()
      assert.same(bounce(10,10,2,2, 0,0,8,8, 1, 4), { 7, 8, 0, 1, 1, 12})
      assert.same(bounce(10,10,2,2, 0,0,8,8, 4, 1), { 8, 7, 1, 0, 12, 1})

      -- perfect corner case:
      assert.same(bounce(10,10,2,2, 0,0,8,8, 1, 1), { 8, 8, 1, 0, 15, 1})
    end)
  end)
end)
