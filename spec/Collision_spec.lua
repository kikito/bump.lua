local bump = require 'bump'

describe('Collision', function()
  local world
  before_each(function()
    world = bump.newWorld()
  end)
  describe(':getMinimumDisplacement', function()
    it('returns the minimum displacement when not tunneling', function()
      local a,b = {'a'}, {'b'}
      world:add(a, 0,0, 5,5)
      local col = world:add(b, 2,3, 5,5)[1]
      assert.same(col, {ti = 0, tunneling = false, item = {'a'}, dx = 3, dy = 2})
      assert.same({col:getMinimumDisplacement()}, {0,2})
    end)
    it('returns the touching point when tunneling', function()
      local a,b = {'a'}, {'b'}
      world:add(a, 0,0,  5,5)
      world:add(b, 10,3, 5,5)
      local col = world:move(b, -10,0, 5,5)[1]

      assert.same(col, {ti = 0.25, tunneling = true, item = {'a'}, dx = 15, dy = 2.25})
      assert.same({col:getMinimumDisplacement()}, {15, 2.25})
    end)
  end)
end)
