local collision = require('bump').collision

local function rect(l,t,w,h)
  return {l=l,t=t,w=w,h=h}
end

local touch = function(itemRect, otherRect, future_l, future_t)
  local col = collision.touch(itemRect, otherRect, future_l, future_t)
  return {col.touch.l, col.touch.t, col.normal.x, col.normal.y}
end

local slide = function(itemRect, otherRect, future_l, future_t)
  local col = collision.slide(itemRect, otherRect, future_l, future_t)
  return {col.touch.l, col.touch.t, col.normal.x, col.normal.y, col.slide.l, col.slide.t}
end

local bounce = function(itemRect, otherRect, future_l, future_t)
  local col = collision.bounce(itemRect, otherRect, future_l, future_t)
  return {col.touch.l, col.touch.t, col.normal.x, col.normal.y, col.bounce.l, col.bounce.t }
end



describe('collision.base', function()
  describe('when item is static', function()
    describe('when itemRect does not intersect otherRect', function()
      it('returns nil', function()
        local c = collision.base(rect(0,0,1,1), rect(5,5,1,1), 0,0)
        assert.is_nil(c)
      end)
    end)
    describe('when itemRect overlaps otherRect', function()
      it('returns overlaps, normal, move, ti, diff, itemRect, otherRect', function()
        local c = collision.base(rect(0,0,7,6), rect(5,5,1,1), 0, 0)

        assert.is_true(c.overlaps)
        assert.equals(c.ti, -2)
        assert.same(c.move, {x = 0, y = 0})
        assert.same(c.itemRect, {l=0,t=0,w=7,h=6})
        assert.same(c.otherRect, {l=5,t=5,w=1,h=1})
        assert.same(c.diffRect, {l=-2,t=-1,w=8,h=7})
        assert.same(c.normal, {x=0, y=0})

      end)
    end)
  end)

  describe('when item is moving', function()
    describe('when itemRect does not intersect otherRect', function()
      it('returns nil', function()
        local c = collision.base(rect(0,0,1,1), rect(5,5,1,1), 0,1)
        assert.is_nil(c)
      end)
    end)
    describe('when itemRect intersects otherRect', function()
      it('detects collisions from the left', function()
        local c = collision.base(rect(1,1,1,1), rect(5,0,1,1), 6,0)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=-1, y=0})
      end)
      it('detects collisions from the right', function()
        local c = collision.base(rect(6,0,1,1), rect(1,0,1,1), 1,1)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.8)
        assert.same(c.normal, {x=1, y=0})
      end)
      it('detects collisions from the top', function()
        local c = collision.base(rect(0,0,1,1), rect(0,4,1,1), 0,5)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=0, y=-1})
      end)
      it('detects collisions from the bottom', function()
        local c = collision.base(rect(0,4,1,1), rect(0,0,1,1), 0,-1)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=0, y=1})
      end)
    end)
  end)
end)

describe('collision.touch', function()
  local other = rect(0,0,8,8)

  describe('on overlaps', function()
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

        assert.same(touch(rect(-1,-1,2,2), other), {-1,-2, 0, -1}) -- 1
        assert.same(touch(rect( 3,-1,2,2), other), { 3,-2, 0, -1}) -- 2
        assert.same(touch(rect( 7,-1,2,2), other), { 7,-2, 0, -1}) -- 3

        assert.same(touch(rect(-1, 3,2,2), other), {-2, 3, -1, 0}) -- 4
        assert.same(touch(rect( 3, 3,2,2), other), { 3, 8,  0, 1}) -- 5
        assert.same(touch(rect( 7, 3,2,2), other), { 8, 3,  1, 0}) -- 6

        assert.same(touch(rect(-1, 7,2,2), other), {-1, 8,  0, 1}) -- 1
        assert.same(touch(rect( 3, 7,2,2), other), { 3, 8,  0, 1}) -- 2
        assert.same(touch(rect( 7, 7,2,2), other), { 7, 8,  0, 1}) -- 3

      end)
    end)

    describe('when the item is moving', function()
      it('returns the left,top coordinates of the overlaps with the movement line, opposite direction', function()
        assert.same(touch(rect( 3, 3,2,2), other, 4, 3), { -2,  3, -1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 2, 3), {  8,  3,  1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 2, 3), {  8,  3,  1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 3, 4), {  3, -2,  0, -1})
        assert.same(touch(rect( 3, 3,2,2), other, 3, 2), {  3,  8,  0,  1})
      end)
    end)
  end)

  describe('on tunnels', function()
    it('returns the coordinates of the item when it starts touching the other, and the normal', function()
      assert.same(touch(rect( -3,  3,2,2), other, 3,3), { -2,  3, -1,  0})
      assert.same(touch(rect(  9,  3,2,2), other, 3,3), {  8,  3,  1,  0})
      assert.same(touch(rect(  3, -3,2,2), other, 3,3), {  3, -2,  0, -1})
      assert.same(touch(rect(  3,  9,2,2), other, 3,3), {  3,  8,  0,  1})
    end)
  end)
end)

describe('collision.slide', function()
  local other = rect(0,0,8,8)

  describe('when there is no movement', function()
    it('behaves like touch, plus safe info', function()
      local ct = collision.touch(rect(3,3,2,2), other)
      local cs = collision.slide(rect(3,3,2,2), other)
      local slide = cs.slide
      cs.slide = nil
      assert.same(ct, cs)
      assert.same(slide, {l = 3, t = 8})
    end)
  end)

  describe('when there is movement, it slides', function()
    it('slides on overlaps', function()
      assert.same(slide(rect(3,3,2,2), other, 4, 5), { 0.5, -2, 0,-1, 4, -2})
      assert.same(slide(rect(3,3,2,2), other, 5, 4), { -2, 0.5, -1,0, -2, 4})
      assert.same(slide(rect(3,3,2,2), other, 2, 1), { 5.5, 8, 0,1, 2, 8})
      assert.same(slide(rect(3,3,2,2), other, 1, 2), { 8, 5.5, 1,0, 8, 2})
    end)

    it('slides over tunnels', function()
      assert.same(slide(rect(10,10,2,2), other, 1, 4), { 7, 8, 0, 1, 1, 8})
      assert.same(slide(rect(10,10,2,2), other, 4, 1), { 8, 7, 1, 0, 8, 1})

      -- perfect corner case:
      assert.same(slide(rect(10,10,2,2), other, 1, 1), { 8, 8, 1, 0, 8, 1})
    end)
  end)
end)

describe('collision.bounce', function()
  local other = rect(0,0,8,8)

  describe('when there is no movement', function()
    it('behaves like :getTouch(), plus safe info', function()
      local ct = collision.touch(rect(3,3,2,2), other)
      local cb = collision.bounce(rect(3,3,2,2), other)
      local bounce, bounceNormal = cb.bounce, cb.bounceNormal
      cb.bounce, cb.bounceNormal = nil, nil
      assert.same(ct, cb)
      assert.same(bounce, {l=3, t=8})
      assert.same(bounceNormal, {x=0,y=0})
    end)
  end)
  describe('when there is movement, it bounces', function()
    it('bounces on overlaps', function()
      assert.same(bounce(rect( 3, 3,2,2), other, 4, 5), { 0.5, -2, 0,-1, 4, -9})
      assert.same(bounce(rect( 3, 3,2,2), other, 5, 4), { -2, 0.5, -1,0, -9, 4})
      assert.same(bounce(rect( 3, 3,2,2), other, 2, 1), { 5.5, 8, 0,1, 2, 15})
      assert.same(bounce(rect( 3, 3,2,2), other, 1, 2), { 8, 5.5, 1,0, 15,2})
    end)

    it('bounces over tunnels', function()
      assert.same(bounce(rect(10,10,2,2), other, 1, 4), { 7, 8, 0, 1, 1, 12})
      assert.same(bounce(rect(10,10,2,2), other, 4, 1), { 8, 7, 1, 0, 12, 1})

      -- perfect corner case:
      assert.same(bounce(rect(10,10,2,2), other, 1, 1), { 8, 8, 1, 0, 15, 1})
    end)
  end)
end)

