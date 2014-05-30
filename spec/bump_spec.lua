local bump = require 'bump'

describe('bump', function()

  describe('newWorld', function()
    it('creates a world', function()
      assert.truthy(bump.newWorld())
    end)

    it('defaults the cellSize to 64', function()
      assert.equal(bump.newWorld().cellSize, 64)
    end)

    it('can set the cellSize', function()
      assert.equal(bump.newWorld(32).cellSize, 32)
    end)

    it('throws an error if cellsize is not a positive number', function()
      assert.error(function() bump.newWorld(-10) end)
      assert.error(function() bump.newWorld("") end)
    end)
  end)

end)
