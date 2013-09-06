local bump = require 'bump'

describe('World', function()

  describe(':add', function()
    it('requires one table and 4 numbers', function()
      local world = bump.newWorld()
      assert.error(function() world:add({}) end)
      assert.error(function() world:add({}, 40) end)
      assert.error(function() world:add() end)
    end)

  end)
end)
