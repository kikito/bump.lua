local bump = require 'bump'

local function rect(l,t,w,h)
  return {l=l,t=t,w=w,h=h}
end

local collide = bump.newCollision
local resolve = function(itemRect, otherRect, prev_l, prev_t)
  prev_l = prev_l or itemRect.l
  prev_t = prev_t or itemRect.t
  return collide({}, {}, itemRect, otherRect, prev_l, prev_t):resolve()
end

describe('World', function()
  describe('constructor', function()
    it('accepts two items, two rectes, and next l and t', function()
      local i1,i2,b1,b2 = {},{}, rect(0,2,1,1), rect(0,0,10,10)
      local c = collide(i1,i2,b1,b2,5,0)
      assert.equal(c.item,  i1)
      assert.equal(c.other, i2)
      assert.equal(c.itemRect,  b1)
      assert.equal(c.otherRect, b2)
      assert.equal(c.vx, 5)
      assert.equal(c.vy, -2)
    end)
  end)

  describe(':resolve', function()
    describe('when item is static', function()
      describe('when itemRect does not intersect otherRect', function()
        it('returns nil', function()
          local c = collide({},{},rect(0,0,1,1), rect(5,5,1,1), 0,0)
          assert.is_nil((c:resolve()))
        end)
      end)
      describe('when itemRect intersects otherRect', function()
        it('returns intersection, sets the collision kind to "intersection", and ti to a negative value', function()
          local c = collide({},{},rect(0,0,7,6), rect(5,5,1,1), 0, 0)
          assert.equal(c, c:resolve())
          assert.is_true(c.is_intersection)
          assert.equal(c.ti, -2)
          assert.equal(c.nx, 0)
          assert.equal(c.ny, 0)
        end)
      end)
    end)

    describe('when item is moving', function()
      describe('when itemRect does not intersect otherRect', function()
        it('returns nil', function()
          local c = collide({},{},rect(0,0,1,1), rect(5,5,1,1), 0,1)
          assert.is_nil((c:resolve()))
        end)
      end)
      describe('when itemRect intersects otherRect', function()
        it('detects collisions from the left', function()
          local c = collide({},{},rect(1,1,1,1), rect(5,0,1,1), 6,0)
          assert.equal(c, c:resolve())
          assert.is_false(c.is_intersection)
          assert.equal(c.ti, 0.6)
          assert.equal(c.nx, -1)
          assert.equal(c.ny, 0)
        end)
        it('detects collisions from the right', function()
          local c = collide({},{},rect(6,0,1,1), rect(1,0,1,1), 1,1)
          assert.equal(c, c:resolve())
          assert.is_false(c.is_intersection)
          assert.equal(c.ti, 0.8)
          assert.equal(c.nx, 1)
          assert.equal(c.ny, 0)
        end)
        it('detects collisions from the top', function()
          local c = collide({},{},rect(0,0,1,1), rect(0,4,1,1), 0,5)
          assert.equal(c, c:resolve())
          assert.is_false(c.is_intersection)
          assert.equal(c.ti, 0.6)
          assert.equal(c.nx, 0)
          assert.equal(c.ny, -1)
        end)
        it('detects collisions from the bottom', function()
          local c = collide({},{},rect(0,4,1,1), rect(0,0,1,1), 0,-1)
          assert.equal(c, c:resolve())
          assert.is_false(c.is_intersection)
          assert.equal(c.ti, 0.6)
          assert.equal(c.nx, 0)
          assert.equal(c.ny, 1)
        end)
      end)
    end)
  end)

  describe(':getTouch', function()
    local other = rect(0,0,8,8)

    describe('on intersections', function()
      describe('when there is no movement', function()
        it('returns the left,top coordinates of the minimum displacement on static items', function()

          --       -1     3     7
          --     -1 +---+ +---+ +---+
          --        | +-+-+---+-+-+ |    1     2     3
          --        +-+-+ +---+ +-+-+
          --          |           |
          --      3 +-+-+ +---+ +-+-+
          --        | | | |   | | | |    4     5     6
          --        +-+-+ +---+ +-+-+
          --          |           |
          --      7 +-+-+ +---+ +-+-+
          --        | +-+-+---+-+-+ |    7     8     9
          --        +-+-+ +---+ +-+-+

          assert.same({resolve(rect(-1,-1,2,2), other):getTouch()}, {-1,-2, 0, -1}) -- 1
          assert.same({resolve(rect( 3,-1,2,2), other):getTouch()}, { 3,-2, 0, -1}) -- 2
          assert.same({resolve(rect( 7,-1,2,2), other):getTouch()}, { 7,-2, 0, -1}) -- 3

          assert.same({resolve(rect(-1, 3,2,2), other):getTouch()}, {-2, 3, -1, 0}) -- 4
          assert.same({resolve(rect( 3, 3,2,2), other):getTouch()}, { 3, 8,  0, 1}) -- 5
          assert.same({resolve(rect( 7, 3,2,2), other):getTouch()}, { 8, 3,  1, 0}) -- 6

          assert.same({resolve(rect(-1, 7,2,2), other):getTouch()}, {-1, 8,  0, 1}) -- 1
          assert.same({resolve(rect( 3, 7,2,2), other):getTouch()}, { 3, 8,  0, 1}) -- 2
          assert.same({resolve(rect( 7, 7,2,2), other):getTouch()}, { 7, 8,  0, 1}) -- 3

        end)
      end)

      describe('when the item is moving', function()
        it('returns the left,top coordinates of the intersection with the movement line, opposite direction', function()
          assert.same({resolve(rect( 3, 3,2,2), other, 4, 3):getTouch()}, { -2,  3, -1,  0})
          assert.same({resolve(rect( 3, 3,2,2), other, 2, 3):getTouch()}, {  8,  3,  1,  0})
          assert.same({resolve(rect( 3, 3,2,2), other, 2, 3):getTouch()}, {  8,  3,  1,  0})
          assert.same({resolve(rect( 3, 3,2,2), other, 3, 4):getTouch()}, {  3, -2,  0, -1})
          assert.same({resolve(rect( 3, 3,2,2), other, 3, 2):getTouch()}, {  3,  8,  0,  1})
        end)
      end)
    end)

    describe('on tunnels', function()
      it('returns the coordinates of the item when it starts touching the other, and the normal', function()
        assert.same({resolve(rect( -3,  3,2,2), other, 3,3):getTouch()}, { -2,  3, -1,  0})
        assert.same({resolve(rect(  9,  3,2,2), other, 3,3):getTouch()}, {  8,  3,  1,  0})
        assert.same({resolve(rect(  3, -3,2,2), other, 3,3):getTouch()}, {  3, -2,  0, -1})
        assert.same({resolve(rect(  3,  9,2,2), other, 3,3):getTouch()}, {  3,  8,  0,  1})
      end)
    end)
  end)

  describe(':getSlide', function()
    local other = rect(0,0,8,8)

    describe('when there is no movement', function()
      it('behaves like :getTouch(), plus safe info', function()
        local c = resolve(rect(3,3,2,2), other)
        assert.same({c:getSlide()}, {3,8, 0,1, 3,8})
      end)
    end)
    describe('when there is movement, it slides', function()
      it('slides on intersections', function()
        assert.same({resolve(rect( 3, 3,2,2), other, 4, 5):getSlide()}, { 0.5, -2, 0,-1, 4, -2})
        assert.same({resolve(rect( 3, 3,2,2), other, 5, 4):getSlide()}, { -2, 0.5, -1,0, -2, 4})
        assert.same({resolve(rect( 3, 3,2,2), other, 2, 1):getSlide()}, { 5.5, 8, 0,1, 2, 8})
        assert.same({resolve(rect( 3, 3,2,2), other, 1, 2):getSlide()}, { 8, 5.5, 1,0, 8, 2})
      end)

      it('slides over tunnels', function()
        assert.same({resolve(rect(10,10,2,2), other, 1, 4):getSlide()}, { 7, 8, 0, 1, 1, 8})
        assert.same({resolve(rect(10,10,2,2), other, 4, 1):getSlide()}, { 8, 7, 1, 0, 8, 1})

        -- perfect corner case:
        assert.same({resolve(rect(10,10,2,2), other, 1, 1):getSlide()}, { 8, 8, 1, 0, 8, 1})
      end)
    end)
  end)

  describe(':getBounce', function()
    local other = rect(0,0,8,8)

    describe('when there is no movement', function()
      it('behaves like :getTouch(), plus safe info', function()
        local c = resolve(rect(3,3,2,2), other)
        assert.same({c:getBounce()}, {3,8, 0,1, 3,8})
      end)
    end)
    describe('when there is movement, it bounces', function()
      it('bounces on intersections', function()
        assert.same({resolve(rect( 3, 3,2,2), other, 4, 5):getBounce()}, { 0.5, -2, 0,-1, 4, -9})
        assert.same({resolve(rect( 3, 3,2,2), other, 5, 4):getBounce()}, { -2, 0.5, -1,0, -9, 4})
        assert.same({resolve(rect( 3, 3,2,2), other, 2, 1):getBounce()}, { 5.5, 8, 0,1, 2, 15})
        assert.same({resolve(rect( 3, 3,2,2), other, 1, 2):getBounce()}, { 8, 5.5, 1,0, 15,2})
      end)

      it('bounces over tunnels', function()
        assert.same({resolve(rect(10,10,2,2), other, 1, 4):getBounce()}, { 7, 8, 0, 1, 1, 12})
        assert.same({resolve(rect(10,10,2,2), other, 4, 1):getBounce()}, { 8, 7, 1, 0, 12, 1})

        -- perfect corner case:
        assert.same({resolve(rect(10,10,2,2), other, 1, 1):getBounce()}, { 8, 8, 1, 0, 15, 1})
      end)
    end)
  end)

end)
