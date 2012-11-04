require 'spec.assert_empty'

local cells = require 'bump.cells'

describe("bump.cells", function()

  before_each(cells.reset)

  it("is a table", function()
    assert.equal(type(cells), "table")
  end)

  describe(".create", function()
    it("adds 1 cell if given a x,y coordinate", function()
      cells.create(1,1)
      assert.equal(1, cells.count())
    end)
  end)

  describe(".getOrCreate", function()
    it("creates a new cell if it does not exist", function()
      cells.getOrCreate(1,1)
      assert.equal(1, cells.count())
    end)
    it("returns the existing cell if it exists", function()
      local cell = cells.getOrCreate(1,1)
      assert.equal(cell, cells.getOrCreate(1,1))
    end)
  end)

  describe(".addItem", function()
    describe("when the item bbox only takes one cell", function()
      local item

      before_each(function()
        item = {}
        cells.addItem(item, 1,1,0,0)
      end)

      it("includes the item in the cell", function()
        assert.truthy(cells.getOrCreate(1,1).items[item])
      end)

      it("forgets the item when it's garbage collected", function()
        item = nil
        collectgarbage('collect')
        assert.empty(cells.getOrCreate(1,1).items)
      end)

      it("forgets the empty cells when they are garbage collected", function()
        cells.create(1,2)
        cells.create(2,1)
        collectgarbage('collect')
        assert.truthy(cells.store.rows[1])
        assert.truthy(cells.store.rows[1][1])
        assert.falsy(cells.store.rows[1][2])
        assert.truthy(cells.store.rows[2])
        assert.falsy(cells.store.rows[2][1])
      end)
    end)

    describe("when the item bbox only takes more than one cell", function()
      it("inserts the item in all the affected cells", function()
        local item = {}
        cells.addItem(item, 1,1,1,1)
        assert.truthy(cells.getOrCreate(1,1).items[item])
        assert.truthy(cells.getOrCreate(1,2).items[item])
        assert.truthy(cells.getOrCreate(2,1).items[item])
        assert.truthy(cells.getOrCreate(2,2).items[item])

        assert.equal(cells.count(), 4)
      end)
    end)
  end)

  describe(".count", function()
    it("returns the amount of cells currently available", function()
      assert.equal(0, cells.count())
      cells.create(1,1)
      assert.equal(1, cells.count())
    end)
  end)

end)
