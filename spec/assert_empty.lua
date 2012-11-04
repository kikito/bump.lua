local assert = require 'luassert'
local say    = require 'say'

local function empty(state, arguments)
  for _,_ in pairs(arguments[1]) do return false end
  return true
end

assert:register("assertion", "empty", empty, "assertion.empty.positive", "assertion.empty.negative")

say:set_namespace('en')

say:set("assertion.empty.positive", "Expected object to be empty. Passed: \n%s")
say:set("assertion.empty.negative", "Expected object not to be empty. Passed: \n%s")

