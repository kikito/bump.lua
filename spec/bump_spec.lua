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
      bump.add({l=1, t=1, w=1, h=1})
      bump.initialize()
      assert.equal(bump.countItems(), 0)
    end)
  end)

  describe(".getBBox", function()
    it("obtains the bounding box by getting the l,t,w,h properties by default", function()
      assert.same({1,2,3,4}, { bump.getBBox({ l=1, t=2, w=3, h=4 }) })
    end)
  end)

  describe(".add", function()
    it("raises an error if nil is passed", function()
      assert.error(function() bump.add() end)
    end)

    it("increases the item count by 1", function()
      bump.add({l=1, t=2, w=3, h=4})
      assert.equal(bump.countItems(), 1)
    end)

    it("inserts the item in as many cells as needed", function()
      bump.add({l=1, t=1, w=70, h=70})
      assert.equal(bump.countCells(), 4)
    end)

    it("caches the bounding box info into the node", function()
      local item = {l=1, t=1, w=70, h=70}
      bump.add(item)
      local n = bump.nodes.get(item)
      assert.same({1,1,70,70,1,1,1,1}, {n.l,n.t,n.w,n.h, n.gl,n.gt,n.gw,n.gh})
    end)
  end)

  describe(".remove", function()
    it("raises an error if nil is passed", function()
      assert.error(function() bump.remove() end)
    end)

    it("decreases the item count by 1", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      bump.remove(item)
      assert.equal(bump.countItems(), 0)
    end)

    it("removes the item from as many cells as needed", function()
      local item = {l=1, t=2, w=70, h=70}
      bump.add(item)
      bump.remove(item)
      collectgarbage('collect')
      assert.equal(bump.countCells(), 0)
    end)
  end)

  describe(".update", function()

    it("raises an error if nil is passed", function()
      assert.error(function() bump.update() end)
    end)

    it("does nothing if the bbox has not changed", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      spy.on(bump.nodes, 'update')
      spy.on(bump.cells, 'remove')
      bump.update(item)
      assert.spy(bump.nodes.update).was_not_called()
      assert.spy(bump.cells.remove).was_not_called()
    end)

    it("updates the node if the bbox has changed", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      local node = bump.nodes.get(item)
      item.w, item.h = 70,70
      bump.update(item)
      local node = bump.nodes.get(item)
      assert.same({node.w, node.h, node.gw, node.gh}, {70,70,1,1})
    end)

    it("updates the cells if the grid bbox has changed", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      item.l, item.t, item.w, item.h = 100, 100, 60, 60
      bump.update(item)
      assert.falsy(bump.cells.getOrCreate(1,1).items[item])

      assert.truthy(bump.cells.getOrCreate(2,2).items[item])
      assert.truthy(bump.cells.getOrCreate(2,3).items[item])
      assert.truthy(bump.cells.getOrCreate(3,2).items[item])
      assert.truthy(bump.cells.getOrCreate(3,3).items[item])
    end)
  end)

  describe(".each", function()
    local i11, i12, i21, i22

    local function mark(item) item.mark = true end

    before_each(function()
      i11 = {l=1, t=1,  w=1, h=1}
      i12 = {l=80,t=1,  w=1, h=1}
      i21 = {l=1, t=80, w=1, h=1}
      i22 = {l=80,t=80, w=1, h=1}
      bump.add(i11)
      bump.add(i12)
      bump.add(i21)
      bump.add(i22)
    end)

    it("affects all items if given one callback function", function()
      bump.each(mark)
      assert.same({true, true, true, true}, {i11.mark, i12.mark, i21.mark, i22.mark})
    end)

    describe("when given a bounding box", function()
      it("affects only the items inside that box", function()
        bump.each(mark, 0,0,20,20)
        assert.same({true, false, false, false}, {i11.mark, i12.mark, i21.mark, i22.mark})
      end)
    end)

  end)
end)
