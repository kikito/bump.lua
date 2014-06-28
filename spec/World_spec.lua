local bump = require 'bump'

describe('World', function()

  local collect = function(t, field_name)
    local res = {}
    for i,v in ipairs(t) do res[i] = v[field_name] end
    return res
  end

  describe(':add', function()
    it('requires something + 4 numbers', function()
      local world = bump.newWorld()
      assert.error(function() world:add({}) end)
      assert.error(function() world:add({}, 40) end)
      assert.error(function() world:add() end)
    end)

    it('throws an error if the object was already added', function()
      local world = bump.newWorld()
      local obj = {}
      world:add(obj, 0,0,10,10)
      assert.error(function() world:add(obj, 0,0,10,10) end)
    end)

    describe('when the world is empty', function()
      it('creates as many cells as needed to hold the item', function()
        local world = bump.newWorld()

        world:add({}, 0,0,10,10) -- adss one cell
        assert.equal(world:countCells(), 1)

        world:add({}, 100,100,10,10) -- adds a separate single cell
        assert.equal(world:countCells(), 2)

        world:add({}, 0,0,100,10) -- occupies 2 cells, but just adds one (the other is already added)
        assert.equal(world:countCells(), 3)

        world:add({}, 0,0,100,10) -- occupies 2 cells, but just adds one (the other is already added)
        assert.equal(world:countCells(), 3)

        world:add({}, 300,300,64,64) -- adds 8 new cells
        assert.equal(world:countCells(), 7)
      end)
    end)
  end)

  describe(':move', function()

    describe('when the object is not there', function()
      it('throws an error', function()
        local world = bump.newWorld()
        assert.is_error(function() world:move({}, 0,0) end)
      end)
    end)

    it('moves the object', function()
      local world, a = bump.newWorld(), {}
      world:add(a, 0,0,10,10)
      world:move(a, 40,40, 20,20)
      assert.same(world:getRect(a), {l=40,t=40,w=20,h=20})
    end)

    describe('when no width or height is given', function()
      it('takes width and height from its previous value', function()
        local world, a = bump.newWorld(), {'a'}
        world:add(a, 0,0, 10,10)
        world:move(a, 5,5)
        assert.same({l=5,t=5,w=10,h=10}, world:getRect(a))
      end)
    end)

    describe('when the object stays in the same group of cells', function()
      it('does not invoke remove and add', function()
        local world, a = bump.newWorld(), {}

        world:add(a, 0,0,10,10)

        spy.on(world, 'remove')
        spy.on(world, 'add')

        world:move(a, 1,1, 11,11)

        assert.spy(world.remove).was.called(0)
        assert.spy(world.add).was.called(0)
      end)
    end)
  end)

  describe(':check', function()
    describe('when the item does not exist', function()
      it('throws an error', function()
        local world = bump.newWorld()
        assert.error(function() world:check({}) end)
      end)
    end)
    describe('when the world is empty', function()
      it('returns an empty list of collisions', function()
        local world = bump.newWorld()
        local obj = {}
        world:add(obj, 1,2,3,4)
        assert.same(world:check(obj), {})
      end)
    end)

    describe('when the world is not empty', function()
      it('returns a list of collisions', function()
        local world, a, b, c = bump.newWorld(), {'a'}, {'b'}, {'c'}

        world:add(a, 0,0,10,10)
        world:add(b, 4,6,10,10)
        world:add(c, 14,16,10,10)
        assert.same(#world:check(b), 1)

      end)

      describe('when next l,t are passed', function()
        it('still handles intersections as before', function()
          local world, a, b = bump.newWorld(), {'a'}, {'b'}

          world:add(a, 0,0, 2,2)
          world:add(b, 1,1, 2,2)
          assert.same(#world:check(b, 1, 1), 1)
        end)
        it('detects and tags tunneling correctly', function()
          local world, a, b = bump.newWorld(), {'a'}, {'b'}

          world:add(a,  1,0, 2,1)
          world:add(b, -5,0, 4,1)
          assert.same(#world:check(b, 5, 0), 1)
        end)
        it('detects the case where an object was touching another without intersecting, and then penetrates', function()
          local world, a, b = bump.newWorld(), {'a'}, {'b'}

          world:add(a, 32,50,20,20)
          world:add(b, 0,0,32,100)

          assert.same(#world:check(a, 30, 50), 1)
        end)

        it('returns a list of collisions sorted by ti', function()
          local world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}

          world:add(a, 110,0, 10,10)
          world:add(b, 70,0, 10,10)
          world:add(c, 50,0, 10,10)
          world:add(d, 90,0, 10,10)
          local col = world:check(a, 10, 0)

          assert.same(collect(col, 'ti'), {0.1, 0.3, 0.5})
        end)
      end) -- when next l,t are passed

      describe('options', function()
        local world, a, b, c, d

        before_each(function()
          world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}
          world:add(a, 110,0, 10,10)
          world:add(b, 70,0, 10,10)
          world:add(c, 50,0, 10,10)
          world:add(d, 90,0, 10,10)
        end)

        describe('the filter param', function()
          it('deactivates collisions when filter returns false', function()
            local cols = world:check(a, 10, 0, function(obj)
              return obj ~= d
            end)
            assert.same(#cols, 2)
          end)
        end)
      end)
    end) -- when the world is not empty
  end) -- :check

  describe(':remove', function()
    it('throws an error if the item does not exist', function()
      local world = bump.newWorld()
      assert.error(function() world:remove({}) end)
    end)
    it('makes the item disappear from the world', function()
      local world, a, b = bump.newWorld(), {}, {}

      world:add(a, 0,0, 10,10)
      world:add(b, 5,0, 1,1)
      assert.same(#world:check(b), 1)
      world:remove(a)
      assert.same(world:check(b), {})
    end)
    it('marks empty cells & rows for deallocation', function()
      local world, a, b = bump.newWorld(), {}, {}
      world:add(a, 0,0, 10, 10)
      world:add(b, 200,200, 10,10)
      assert.same(world:countCells(), 2)
      world:remove(b)
      assert.same(world:countCells(), 2)
      collectgarbage('collect')
      assert.same(world:countCells(), 1)
    end)
  end)

  describe(':toCell', function()
    it('returns the coordinates of the cell containing a point', function()
      local w = bump.newWorld()
      assert.same({w:toCell(0,0)}, {1,1})
      assert.same({w:toCell(63.9,63.9)}, {1,1})
      assert.same({w:toCell(64,64)}, {2,2})
      assert.same({w:toCell(-1,-1)}, {0,0})
    end)
  end)

  describe(':toWorld', function()
    it('returns the world left,top corner of the given cell', function()
      local w = bump.newWorld()
      assert.same({w:toWorld(1,1)}, {0,0})
      assert.same({w:toWorld(2,2)}, {64,64})
      assert.same({w:toWorld(-1,1)}, {-128,0})
    end)
  end)

  describe(':queryRect', function()
    it('returns nothing when the world is empty', function()
      assert.same(bump.newWorld():queryRect(0,0,1,1), {})
    end)
    describe('when the world has items', function()
      local world, a, b, c, d
      before_each(function()
        world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}
        world:add(a, 10,0, 10,10)
        world:add(b, 70,0, 10,10)
        world:add(c, 50,0, 10,10)
        world:add(d, 90,0, 10,10)
      end)
      local sorted = function(tbl)
        table.sort(tbl, function(a,b) return a[1] < b[1] end)
        return tbl
      end

      it('returns the items inside/partially inside the given rect', function()
        assert.same(sorted(world:queryRect(55, 5, 20, 20)), {b,c})
        assert.same(sorted(world:queryRect(0, 5, 100, 20)), {a,b,c,d})
      end)

      it('only returns the items for which filter returns true', function()
        local filter = function(other) return other == a or other == b or other == d end
        assert.same(sorted(world:queryRect(55, 5, 20, 20, filter)), {b})
        assert.same(sorted(world:queryRect(0, 5, 100, 20, filter)), {a,b,d})
      end)
    end)

  end)

  describe(':queryPoint', function()
    it('returns nothing when the world is empty', function()
      assert.same(bump.newWorld():queryPoint(0,0), {})
    end)
    describe('when the world has items', function()
      local world, a, b, c, d
      before_each(function()
        world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}
        world:add(a, 10,0, 10,10)
        world:add(b, 15,0, 10,10)
        world:add(c, 20,0, 10,10)
      end)
      local sorted = function(tbl)
        table.sort(tbl, function(a,b) return a[1] < b[1] end)
        return tbl
      end

      it('returns the items inside/partially inside the given rect', function()
        assert.same(sorted(world:queryPoint( 4,5)), {})
        assert.same(sorted(world:queryPoint(14,5)), {a})
        assert.same(sorted(world:queryPoint(16,5)), {a,b})
        assert.same(sorted(world:queryPoint(21,5)), {b,c})
        assert.same(sorted(world:queryPoint(26,5)), {c})
        assert.same(sorted(world:queryPoint(31,5)), {})
      end)

      it('the items are ignored when filter is present and returns false for them', function()
        local filter = function(other) return other ~= b end
        assert.same(sorted(world:queryPoint( 4,5, filter)), {})
        assert.same(sorted(world:queryPoint(14,5, filter)), {a})
        assert.same(sorted(world:queryPoint(16,5, filter)), {a})
        assert.same(sorted(world:queryPoint(21,5, filter)), {c})
        assert.same(sorted(world:queryPoint(26,5, filter)), {c})
        assert.same(sorted(world:queryPoint(31,5, filter)), {})
      end)
    end)

  end)

  describe(':querySegment', function()
    it('returns nothing when the world is empty', function()
      assert.same(bump.newWorld():querySegment(0,0,1,1), {})
    end)

    it('does not touch borders', function()
      local world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}
      world:add(a, 10,0, 5,5)
      world:add(c, 20,0, 5,5)

      assert.same(world:querySegment(0,5,  10,0),  {})
      assert.same(world:querySegment(15,5, 20,0),  {})
      assert.same(world:querySegment(26,5, 25,0),  {})
    end)

    describe("when the world has items", function()
      local world, a, b, c, d
      before_each(function()
        world, a, b, c, d = bump.newWorld(), {'a'}, {'b'}, {'c'}, {'d'}
        world:add(a,  5,0, 5,10)
        world:add(b, 15,0, 5,10)
        world:add(c, 25,0, 5,10)
      end)

      it('returns the items touched by the segment, sorted by touch order', function()
        assert.same(world:querySegment(0,5, 11,5),  {a})
        assert.same(world:querySegment(0,5, 17,5),  {a,b})
        assert.same(world:querySegment(0,5, 30,5),  {a,b,c})
        assert.same(world:querySegment(17,5, 26,5), {b,c})
        assert.same(world:querySegment(22,5, 26,5), {c})

        assert.same(world:querySegment(11,5, 0,5),  {a})
        assert.same(world:querySegment(17,5, 0,5),  {b,a})
        assert.same(world:querySegment(30,5, 0,5),  {c,b,a})
        assert.same(world:querySegment(26,5, 17,5), {c,b})
        assert.same(world:querySegment(26,5, 22,5), {c})
      end)

      it('filters out items when filter does not return true for them', function()
        local filter = function(other) return other ~= a and other ~= c end

        assert.same(world:querySegment(0,5, 11,5, filter),  {})
        assert.same(world:querySegment(0,5, 17,5, filter),  {b})
        assert.same(world:querySegment(0,5, 30,5, filter),  {b})
        assert.same(world:querySegment(17,5, 26,5, filter), {b})
        assert.same(world:querySegment(22,5, 26,5, filter), {})

        assert.same(world:querySegment(11,5, 0,5, filter),  {})
        assert.same(world:querySegment(17,5, 0,5, filter),  {b})
        assert.same(world:querySegment(30,5, 0,5, filter),  {b})
        assert.same(world:querySegment(26,5, 17,5, filter), {b})
        assert.same(world:querySegment(26,5, 22,5, filter), {})
      end)

    end)
  end)

  describe(":hasItem", function()
    it('returns wether the world has an item', function()
      local item = {}
      local world = bump.newWorld()
      assert.is_false(world:hasItem(item))
      world:add(item, 0,0,1,1)
      assert.is_true(world:hasItem(item))
    end)
    it('does not throw errors with non-tables or nil', function()
      local world = bump.newWorld()
      assert.is_false(world:hasItem(false))
      assert.is_false(world:hasItem(1))
      assert.is_false(world:hasItem("hello"))
      assert.is_false(world:hasItem())
    end)
  end)
end)
