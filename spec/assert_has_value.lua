local assert = require 'luassert'
local say    = require 'say'

local function has_value(state, arguments)
  local t, value = arguments[1], arguments[2]
  for k,v in pairs(t) do
    if v == value then return true end
  end
  return false
end

assert:register("assertion", "has_value", has_value, "assertion.has_value.positive", "assertion.has_value.negative")

say:set_namespace('en')

say:set("assertion.has_value.positive", "Expected object to have value. Passed: \n%s\nrequired value:\n%s")
say:set("assertion.has_value.negative", "Expected object not to have value. Passed: \n%s\nrequired value:\n%s")

