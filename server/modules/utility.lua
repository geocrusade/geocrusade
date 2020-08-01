local utility = {}


utility["merge_table_into"] = function(a, b)
  for key, a_val in pairs(a) do
    local b_val = b[key]
    if b_val == nil then
      b[key] = a_val
    elseif type(b_val) == "table" then
      b[key] = utility.merge_table_into(a_val, b_val)
    end
  end

  return b
end

utility["get_vector_distance"] = function(v1, v2)
  local x = v1.x - v2.x
  local y = v1.y - v2.y
  local z = v1.z - v2.z

  return math.sqrt(x^2 + y^2 + z^2)
end

utility["is_zero_vector"] = function(v)
  return v.x == 0 and v.y == 0 and v.z == 0
end

return utility
