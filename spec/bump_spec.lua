local bump = require 'bump.init'

describe("bump", function()

  before_each(function()
    bump.initialize()
  end)

  it("is a table", function()
    assert.equal(type(bump), "table")
  end)

  describe(".initialize", function()
    it("is a function", function()
      assert.equal(type(bump.initialize), "function")
    end)
    it("sets the cell size", function()
      bump.initialize(32)
      assert.equal(32, bump:getCellSize())
    end)
    it("defaults the cell size to 64", function()
      bump.initialize()
      assert.equal(64, bump:getCellSize())
    end)
    it("sets the item count back to 0", function()
      bump.add({})
      bump.initialize()
      assert.equal(bump.countItems(), 0)
    end)
  end)

  describe(".getBBox", function()
    it("calculates the default of a box by returning l,t,w,h", function()
      assert.same({1,2,3,4}, { bump.getBBox({ l=1, t=2, w=3, h=4 }) })
    end)
  end)

  describe(".add", function()
    it("raises an error if nil is passed", function()
      assert.error(function() bump.add() end)
    end)

    it("increases the item count by 1", function()
      bump.add({})
      assert.equal(bump.countItems(), 1)
    end)
  end)




end)
