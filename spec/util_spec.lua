local util = require 'bump.util'

describe('bump.util', function()
  describe('.copy', function()
    it('creates a copy of a given table', function()
      local t1, t2 = {1,2,3,4}, {a=1,b=2,c=3}

      assert.same(util.copy(t1), t1)
      assert.Not.equal(util.copy(t1), t1)

      assert.same(util.copy(t2), t2)
      assert.Not.equal(util.copy(t2), t2)
    end)
  end)

  describe('.newWeakTable', function()
    local function assertWeakKeys(wt)
      local id = {}
      wt[id] = true
      id = nil
      collectgarbage('collect')
      assert.falsy(next(wt))
    end

    local function assertWeakValues(wt)
      local v = {}
      wt[1] = v
      v = nil
      collectgarbage('collect')
      assert.falsy(next(wt))
    end

    it('creates a table weak on keys by default', function()
      assertWeakKeys(util.newWeakTable())
    end)

    it('creates a table weak on keys when passed "k" in mode', function()
      assertWeakKeys(util.newWeakTable('k'))
    end)

    it('creates a table weak on values when passed "v" in mode', function()
      assertWeakValues(util.newWeakTable('v'))
    end)

    it('creates a table weak on values and keys when passed "kv" in mode', function()
      local wt = util.newWeakTable('kv')
      assertWeakKeys(wt)
      assertWeakValues(wt)
    end)
  end)

  describe('.abs', function()
    it('returns the absolute value of a number', function()
      assert.equal(1, util.abs(1))
      assert.equal(1, util.abs(-1))
      assert.equal(0, util.abs(0))
    end)
  end)
end)
