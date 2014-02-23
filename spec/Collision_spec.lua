local bump = require 'bump'

local function box(l,t,w,h)
  return {l=l,t=t,w=w,h=h}
end

local collide = bump.newCollision
local resolve = function(itemBox, otherBox, prev_l, prev_t)
  prev_l = prev_l or itemBox.l
  prev_t = prev_t or itemBox.t
  return collide({}, {}, itemBox, otherBox, prev_l, prev_t):resolve()
end

describe('World', function()
  describe('constructor', function()
    it('accepts two items, two boxes, and next l and t', function()
      local i1,i2,b1,b2 = {},{}, box(0,2,1,1), box(0,0,10,10)
      local c = collide(i1,i2,b1,b2,5,0)
      assert.equal(c.item,  i1)
      assert.equal(c.other, i2)
      assert.equal(c.itemBox,  b1)
      assert.equal(c.otherBox, b2)
      assert.equal(c.vx, 5)
      assert.equal(c.vy, -2)
    end)
  end)

  describe(':resolve', function()
    describe('when item is static', function()
      describe('when itemBox does not intersect otherBox', function()
        it('returns nil', function()
          local c = collide({},{},box(0,0,1,1), box(5,5,1,1), 0,0)
          assert.is_nil((c:resolve()))
        end)
      end)
      describe('when itemBox intersects otherBox', function()
        it('returns intersection, sets the collision kind to "intersection", and ti to a negative value', function()
          local c = collide({},{},box(0,0,7,6), box(5,5,1,1), 0, 0)
          assert.equal(c, c:resolve())
          assert.equal(c.kind, 'intersection')
          assert.equal(c.ti, -2)
          assert.equal(c.normal_x, 0)
          assert.equal(c.normal_y, 0)
        end)
      end)
    end)

    describe('when item is moving', function()
      describe('when itemBox does not intersect otherBox', function()
        it('returns nil', function()
          local c = collide({},{},box(0,0,1,1), box(5,5,1,1), 0,1)
          assert.is_nil((c:resolve()))
        end)
      end)
      describe('when itemBox intersects otherBox', function()
        it('detects collisions from the left', function()
          local c = collide({},{},box(1,1,1,1), box(5,0,1,1), 6,0)
          assert.equal(c, c:resolve())
          assert.equal(c.kind, 'tunnel')
          assert.equal(c.ti, 0.6)
          assert.equal(c.normal_x, -1)
          assert.equal(c.normal_y, 0)
        end)
        it('detects collisions from the right', function()
          local c = collide({},{},box(6,0,1,1), box(1,0,1,1), 1,1)
          assert.equal(c, c:resolve())
          assert.equal(c.kind, 'tunnel')
          assert.equal(c.ti, 0.8)
          assert.equal(c.normal_x, 1)
          assert.equal(c.normal_y, 0)
        end)
        it('detects collisions from the top', function()
          local c = collide({},{},box(0,0,1,1), box(0,4,1,1), 0,5)
          assert.equal(c, c:resolve())
          assert.equal(c.kind, 'tunnel')
          assert.equal(c.ti, 0.6)
          assert.equal(c.normal_x, 0)
          assert.equal(c.normal_y, -1)
        end)
        it('detects collisions from the bottom', function()
          local c = collide({},{},box(0,4,1,1), box(0,0,1,1), 0,-1)
          assert.equal(c, c:resolve())
          assert.equal(c.kind, 'tunnel')
          assert.equal(c.ti, 0.6)
          assert.equal(c.normal_x, 0)
          assert.equal(c.normal_y, 1)
        end)
      end)
    end)
  end)

  describe(':getTouch', function()
    describe('on intersections', function()
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

        local other = box(0,0,8,8)

        assert.same({resolve(box(-1,-1,2,2), other):getTouch()}, {-1,-2}) -- 1
        assert.same({resolve(box( 3,-1,2,2), other):getTouch()}, { 3,-2}) -- 2
        assert.same({resolve(box( 7,-1,2,2), other):getTouch()}, { 7,-2}) -- 3

        assert.same({resolve(box(-1, 3,2,2), other):getTouch()}, {-2, 3}) -- 4
        assert.same({resolve(box( 3, 3,2,2), other):getTouch()}, { 3, 8}) -- 5
        assert.same({resolve(box( 7, 3,2,2), other):getTouch()}, { 8, 3}) -- 6

        assert.same({resolve(box(-1, 7,2,2), other):getTouch()}, {-1, 8}) -- 1
        assert.same({resolve(box( 3, 7,2,2), other):getTouch()}, { 3, 8}) -- 2
        assert.same({resolve(box( 7, 7,2,2), other):getTouch()}, { 7, 8}) -- 3

      end)
      describe('when the item is moving', function()
        it('returns the left,top coordinates of the intersection with the movement line, opposite direction', function()

        end)
      end)

    end)

  end)
end)
