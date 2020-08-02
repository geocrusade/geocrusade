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

utility["table_copy"] = function(t)
  local t2 = {};
  for k,v in pairs(t) do
    if type(v) == "table" then
        t2[k] = utility.table_copy(v);
    else
        t2[k] = v;
    end
  end
  return t2;
end

utility["vector_magnitude"] = function(a)
  return math.sqrt(a.x^2 + a.y^2 + a.z^2)
end

utility["vector_normalize"] = function(a)
  local mag = utility.vector_magnitude(a)
  return {
    x = a.x / mag,
    y = a.y / mag,
    z = a.z / mag
  }
end

utility["get_vector_distance"] = function(v1, v2)
  local x = v1.x - v2.x
  local y = v1.y - v2.y
  local z = v1.z - v2.z

  return utility.vector_magnitude({ x = x, y = y, z = z})
end

utility["is_zero_vector"] = function(v)
  return v.x == 0 and v.y == 0 and v.z == 0
end

utility["vector_dot_product"] = function(a, b)
  return a.x*b.x + a.y*b.y + a.z*b.z
end

utility["vector_scale"] = function(v, scale)
  return { x = v.x * scale, y = v.y * scale, z = v.z * scale }
end

utility["vector_cross_product"] = function(a, b)
  return {
    x = a.y * b.z - a.z * b.y,
    y = a.z * b.x - a.x * b.z,
    z = a.x * b.y - a.y * b.x
  }
end

utility["vector_subtract"] = function(a, b)
  return {
    x = a.x - b.x,
    y = a.y - b.y,
    z = a.z - b.z
  }
end

utility["vector_add"] = function(a, b)
  return {
    x = a.x + b.x,
    y = a.y + b.y,
    z = a.z + b.z
  }
end

local num_have_same_sign = function(a, b)
  return a*b >= 0
end

local get_tetra_volume = function(a, b, c, d)
  local ba = utility.vector_subtract(b, a)
	local ca = utility.vector_subtract(c, a)
	local da = utility.vector_subtract(d, a)
	return (1.0 / 6.0) * utility.vector_dot_product(utility.vector_cross_product(ba, ca), da)
end

local line_intersects_triangle = function(p1, p2, v1, v2, v3)
  local s1 = get_tetra_volume(p1, v1, v2, v3)
  local s2 = get_tetra_volume(p2, v1, v2, v3)

  if num_have_same_sign(s1, s2) then
    return false
  end

  local s3 = get_tetra_volume(p1, p2, v1, v2)
  local s4 = get_tetra_volume(p1, p2, v2, v3)

  if not num_have_same_sign(s3, s4) then
    return false
  end

  local s5 = get_tetra_volume(p1, p2, v3, v1)

  if not num_have_same_sign(s4, s5) then
    return false
  end

  return true
end

utility["line_intersects_faces"] = function(p1, p2, face_vertices)
  for i = 1, table.getn(face_vertices)-3, 3 do
    local v1 = face_vertices[i]
    local v2 = face_vertices[i+1]
    local v3 = face_vertices[i+2]
    if line_intersects_triangle(p1, p2, v1, v2, v3) then
      return true
    end
  end

  return false
end

utility["table_insert_all"] = function(t1, t2)
  for _, v in ipairs(t2) do
      table.insert(t1, v)
  end
end

return utility
