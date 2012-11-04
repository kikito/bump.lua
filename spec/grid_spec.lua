local grid = require 'bump.grid'

describe("bump.grid", function()
  before(grid.reset)

  it("is a table", function()
    assert.equal(type(grid), "table")
  end)

  describe(".reset", function()
    it("sets the cellSize", function()
      grid.reset(16)
      assert.equal(16, grid.getCellSize())
    end)

    it("defaults the cellSize to 64", function()
      assert.equal(64, grid.getCellSize())
    end)
  end)

  describe(".getCoords", function()
    it("returns the grid coordinates corresponding to a given real-world point", function()
      assert.same({1,1}, {grid.getCoords(1,1)})
      assert.same({1,1}, {grid.getCoords(16,16)})
      assert.same({2,1}, {grid.getCoords(65,1)})
    end)
  end)

  describe(".getBox", function()
    it("returns the l,t,w,h of the smallest grid box containing the given box in wc", function()
      assert.same({1,1,0,0}, {grid.getBox(1,1,10,10)})
      assert.same({1,1,0,0}, {grid.getBox(1,1,10,63)})
      assert.same({1,1,0,1}, {grid.getBox(1,1,10,64)})
      assert.same({1,1,0,0}, {grid.getBox(1,0,10,10)})
    end)
  end)

end)
