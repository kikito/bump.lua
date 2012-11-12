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

  describe(".add", function()
    describe("when the item bbox only takes one cell", function()
      local item

      before_each(function()
        item = {}
        cells.add(item, 1,1,0,0)
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
        assert.equal(3, cells.count())
        collectgarbage('collect')
        assert.equal(1, cells.count())
      end)
    end)

    describe("when the item bbox only takes more than one cell", function()
      it("inserts the item in all the affected cells", function()
        local item = {}
        cells.add(item, 1,1,1,1)
        assert.truthy(cells.getOrCreate(1,1).items[item])
        assert.truthy(cells.getOrCreate(1,2).items[item])
        assert.truthy(cells.getOrCreate(2,1).items[item])
        assert.truthy(cells.getOrCreate(2,2).items[item])

        assert.equal(cells.count(), 4)
      end)
    end)
  end)

  describe(".remove", function()
    it("removes the item from all the cells that contain it", function()
      local item = {}
      cells.add(item, 1,1,1,1)
      cells.remove(item, 1,1,1,1)
      assert.falsy(cells.getOrCreate(1,1).items[item])
      assert.falsy(cells.getOrCreate(1,2).items[item])
      assert.falsy(cells.getOrCreate(2,1).items[item])
      assert.falsy(cells.getOrCreate(2,2).items[item])

      collectgarbage('collect')
      assert.equal(cells.count(), 0)
    end)
  end)

  describe(".count", function()
    it("returns the amount of cells currently available", function()
      assert.equal(0, cells.count())
      cells.create(1,1)
      assert.equal(1, cells.count())
    end)
  end)

  describe(".each", function()
    local c11,c12,c21,c22
    local function mark(cell) cell.mark = true end
    before_each(function()
      c11 = cells.getOrCreate(1,1)
      c12 = cells.getOrCreate(1,2)
      c21 = cells.getOrCreate(2,1)
      c22 = cells.getOrCreate(2,2)
    end)
    describe("when given no params", function()
      it("parses all cells", function()
        cells.each(mark)
        assert.same({true, true, true, true}, {c11.mark, c12.mark, c21.mark, c22.mark})
      end)
    end)
    describe("when given a box", function()
      it("parses only once cell if the box has 0 length", function()
        cells.each(mark, 1,1,0,0)
        assert.same({true, nil, nil, nil}, {c11.mark, c12.mark, c21.mark, c22.mark})
      end)
      it("parses 2 cells if the box has width but no height", function()
        cells.each(mark, 1,1,1,0)
        assert.same({true, nil, true, nil}, {c11.mark, c12.mark, c21.mark, c22.mark})
      end)
      it("parses 2 cells if the box has height but no width", function()
        cells.each(mark, 1,1,0,1)
        assert.same({true, true}, {c11.mark, c12.mark, c21.mark, c22.mark})
      end)
      it("parses 4 cells if the box has 1 length", function()
        cells.each(mark, 1,1,1,1)
        assert.same({true, true, true, true}, {c11.mark, c12.mark, c21.mark, c22.mark})
      end)
    end)
  end)

  describe(".eachItem", function()
    local i11, i22, shared
    local mark = function(item) item.mark = true end
    before_each(function()
      i11, i22, shared = {}, {}, {}
      cells.add(i11, 1,1,0,0)
      cells.add(i22, 2,2,0,0)
      cells.add(shared, 1,1,1,1)
    end)

    it("does nothing if the box is outside the boundaries", function()
      cells.eachItem(mark, 20,20,0,0)
      assert.same({}, {i11.mark, i22.mark, shared.mark})
    end)
    it("touches the items inside one box, but not the others", function()
      cells.eachItem(mark, 1,1,0,0)
      assert.same({true, nil, true}, {i11.mark, i22.mark, shared.mark})
    end)
    it("does not touch items on the visited param", function()
      cells.eachItem(mark, 1,1,0,0, {[i11]=true})
      assert.same({nil, nil, true}, {i11.mark, i22.mark, shared.mark})
    end)
    it("does not alter the visited table", function()
      local visited = {}
      cells.eachItem(function() end, 1,1,0,0, visited)
      assert.empty(visited)
    end)
    it("does not touch the same item more than once", function()
      local counter = 0
      cells.eachItem(function() counter = counter + 1 end, 1,1,1,1)
      assert.equals(counter, 3)
    end)
  end)
end)

