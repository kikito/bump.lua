local nodes = require 'bump.nodes'

describe("bump.nodes", function()

  it("is a table", function()
    assert.equals(type(nodes), "table")
  end)

  describe(".get", function()

    it("returns nil for unknown items", function()
      assert.equals(nil, nodes.get({}))
    end)

    it("returns a node when the item is known", function()
      local item = {}
      nodes.create(item)
      assert.equals("table", type(nodes.get(item)))
    end)

  end)

end)
