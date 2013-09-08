local bump = require 'bump'

describe('World', function()

  describe(':add', function()
    it('requires something + 4 numbers', function()
      local world = bump.newWorld()
      assert.error(function() world:add({}) end)
      assert.error(function() world:add({}, 40) end)
      assert.error(function() world:add() end)
    end)

    describe('when the world is empty', function()
      it('returns an empty list of collisions', function()
        local world = bump.newWorld()
        assert.same(world:add({}, 0,0,10,10), {})
      end)
    end)

    describe('when the world is not empty', function()
      it('returns an empty list of collisions', function()
        local world, a, b = bump.newWorld(), {}, {}

        world:add(a, 0,0,10,10)
        assert.same(world:add(b, 4,6,10,10), {
          { self = b, other = a, dx = 6, dy = 4 }
        })

      end)
    end)
  end)

  describe(':move', function()

    describe('when the object is not there', function()
      it('throws an error', function()
        local world = bump.newWorld()
        assert.is_error(function() world:move({}, 0,0,10,10) end)
      end)
    end)

    describe('when the world is empty', function()
      it('returns an empty list of collisions', function()
        local world = bump.newWorld()
        assert.same(world:add({}, 0,0,10,10), {})
      end)
    end)

    describe('when the world is not empty', function()
      it('returns a list of collisions', function()
        local world, a, b = bump.newWorld(), {}, {}

        world:add(a, 0,0,10,10)
        assert.same(world:add(b, 4,6,10,10), {
          { self = b, other = a, dx = 6, dy = 4 }
        })

      end)
    end)
  end)

  describe(':check', function()
    describe('when the item does not exist', function()
      it('returns an empty table', function()
        local world = bump.newWorld()
        assert.same(world:check({}, 1,2,3,4), {})
      end)
    end)
    describe('when the world is empty', function()
      it('returns an empty list of collisions', function()
        local world = bump.newWorld()
        assert.same(world:check({}, 0,0,10,10), {})
      end)
    end)

    describe('when the world is not empty', function()
      it('returns a list of collisions', function()
        local world, a, b = bump.newWorld(), {}, {}

        world:add(a, 0,0,10,10)
        assert.same(world:check(b, 4,6,10,10), {
          { self = b, other = a, dx = 6, dy = 4 }
        })

      end)
    end)
  end)
end)
