local nodes = require 'bump.nodes'

describe("bump.nodes", function()


  it("is a table", function()
    assert.equals(type(nodes), "table")
  end)

  describe(".get", function()
    before_each(nodes.reset)

    it("returns nil for unknown items", function()
      assert.equals(nil, nodes.get({}))
    end)

    it("returns a node when the item is known", function()
      local item = {}
      nodes.create(item)
      assert.equals("table", type(nodes.get(item)))
    end)

  end)

  describe(".create", function()
    before_each(nodes.reset)

    it("throws an error when passed nil", function()
      assert.error(function() nodes.create(nil) end)
    end)

    it("inserts new nodes in the list of nodes, but they get automatically gc", function()
      assert.equals(0, nodes.count())
      local item={}
      nodes.create(item)
      assert.equals(1, nodes.count())
      item = nil
      collectgarbage('collect')
      assert.equals(0, nodes.count())
    end)

  end)

  describe(".count", function()
    before_each(nodes.reset)

    it("returns the number of nodes available in the node store", function()
      assert.equals(0, nodes.count())
      nodes.create({})
      assert.equals(1, nodes.count())
    end)

  end)

  describe(".remove", function()
    before_each(nodes.reset)

    it("destroys a node given its corresponding item", function()
      local item = {}
      nodes.create(item)
      assert.equals(1, nodes.count())
      nodes.destroy(item)
      assert.equals(nil, nodes.get(item))
      assert.equals(0, nodes.count())
    end)

  end)

end)
