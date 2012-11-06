
local nodes = require 'bump.nodes'

describe("bump.nodes", function()

  before_each(nodes.reset)

  it("is a table", function()
    assert.equal(type(nodes), "table")
  end)

  describe(".get", function()
    it("returns nil for unknown items", function()
      assert.equal(nil, nodes.get({}))
    end)

    it("returns a node when the item is known", function()
      local item = {}
      nodes.add(item)
      assert.equal("table", type(nodes.get(item)))
    end)

  end)

  describe(".add", function()
    it("throws an error when passed nil", function()
      assert.error(function() nodes.add(nil) end)
    end)

    it("inserts new nodes in the list of nodes, but they get automatically gc", function()
      assert.equal(0, nodes.count())
      local item={}
      nodes.add(item)
      assert.equal(1, nodes.count())
      item = nil
      collectgarbage('collect')
      assert.equal(0, nodes.count())
    end)

    it("adds bounding box info into the new node", function()
      local item = {}
      nodes.add(item, 1,2,3,4,5,6,7,8)
      local n = nodes.get(item)
      assert.same({1,2,3,4,5,6,7,8}, {n.l, n.t, n.w, n.h, n.gl, n.gt, n.gw, n.gh})
    end)

  end)

  describe(".count", function()
    it("returns the number of nodes available in the node store", function()
      assert.equal(0, nodes.count())
      nodes.add({})
      assert.equal(1, nodes.count())
    end)
  end)

  describe(".remove", function()
    it("destroys a node given its corresponding item", function()
      local item = {}
      nodes.add(item)
      assert.equal(1, nodes.count())
      nodes.remove(item)
      assert.equal(nil, nodes.get(item))
      assert.equal(0, nodes.count())
    end)
  end)

  describe(".update", function()
    it("updates the bbox of an item", function()
      local item = {}
      nodes.add(item, 1,2,3,4,5,6,7,8)
      nodes.update(item, 2,2,2,2,2,2,2,2)
      local n = nodes.get(item)
      assert.same({2,2,2,2,2,2,2,2}, {n.l, n.t, n.w, n.h, n.gl, n.gt, n.gw, n.gh})
    end)
  end)

end)
