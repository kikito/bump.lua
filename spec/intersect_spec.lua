local intersect = require 'bump.intersect'

describe('bump.intersect', function()
  describe('.quick', function()
    it('returns true when two boxes intersect', function()
      assert.truthy(intersect.quick(0,0,10,10, 5,5,10,10))
    end)
    it('returns false when two boxes do not intersect', function()
      assert.falsy(intersect.quick(0,0,10,10, 20,20,10,10))
    end)
  end)
end)
