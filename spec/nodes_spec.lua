
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
      nodes.create(item)
      assert.equal("table", type(nodes.get(item)))
    end)

  end)

  describe(".create", function()
    it("throws an error when passed nil", function()
      assert.error(function() nodes.create(nil) end)
    end)

    it("inserts new nodes in the list of nodes, but they get automatically gc", function()
      assert.equal(0, nodes.count())
      local item={}
      nodes.create(item)
      assert.equal(1, nodes.count())
      item = nil
      collectgarbage('collect')
      assert.equal(0, nodes.count())
    end)

  end)

  describe(".count", function()
    it("returns the number of nodes available in the node store", function()
      assert.equal(0, nodes.count())
      nodes.create({})
      assert.equal(1, nodes.count())
    end)

  end)

  describe(".remove", function()
    it("destroys a node given its corresponding item", function()
      local item = {}
      nodes.create(item)
      assert.equal(1, nodes.count())
      nodes.destroy(item)
      assert.equal(nil, nodes.get(item))
      assert.equal(0, nodes.count())
    end)
  end)

end)
