local bump = require 'bump.init'

describe("bump", function()

  it("is a table", function()
    assert.equals(type(bump), "table")
  end)

  describe("#initialize", function()
    it("is a function", function()
      assert.equals(type(bump.initialize), "function")
    end)
    it("sets the cell size", function()
      bump.initialize(32)
      assert.equals(32, bump:getCellSize())
    end)
    it("defaults the cell size to 64", function()
      bump.initialize()
      assert.equals(64, bump:getCellSize())
    end)
  end)

  describe("#getBBox", function()
    it("calculates the default of a box by returning l,t,w,h", function()
      local l,t,w,h = bump.getBBox({l=1,t=2,w=3,h=4})
      assert.same({l,t,w,h},{1,2,3,4})
    end)
  end)
end)
