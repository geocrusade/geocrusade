local nk = require("nakama")
local utility = {}

utility["get_zero_vector"] = function()
  return { x = 0, y = 0, z = 0 }
end

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

utility["table_log"] = function(t)
  for k,v in pairs(t) do
    if type(v) == "table" then
      nk.logger_info(("--- %q ---"):format(k))
      utility.table_log(v);
    else
      nk.logger_info(("%q = %q"):format(k, v))
    end
  end
end

utility["table_insert_all"] = function(t1, t2)
  for _, v in ipairs(t2) do
      table.insert(t1, v)
  end
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

utility["vector_rotate"] = function(v, deg)
  -- y axis rotation
  return { x = (v.x * math.cos(deg)) + (v.z * math.sin(deg)),
           y = v.y,
           z = (-v.x * math.sin(deg)) + (v.z * math.cos(deg))
         }
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

utility["vector_multiply"] = function(a, b)
  return {
    x = a.x * b.x,
    y = a.y * b.y,
    z = a.z * b.z
  }
end

-- Suggested by BrunoLevy https://stackoverflow.com/a/42752998
-- Source: Möller–Trumbore ray-triangle intersection algorithm on Wikipedia

local get_line_triangle_intersection = function(ray_origin, ray_vector, v1, v2, v3)
  local ray_end = utility.vector_add(ray_origin, ray_vector)
  local EPSILON = 0.0000001;
  local edge1 = utility.vector_subtract(v2, v1)
  local edge2 = utility.vector_subtract(v3, v1)
  local h = utility.vector_cross_product(ray_vector, edge2)
  local a = utility.vector_dot_product(edge1, h)
  if a > -EPSILON and a < EPSILON then
    return { exists = false, point = ray_end }  -- ray is parallel to triangle
  end

  local f = 1.0 / a
  local s = utility.vector_subtract(ray_origin, v1)
  local u = f * utility.vector_dot_product(s, h)
  if u < 0.0 or u > 1.0 then
    return { exists = false, point = ray_end }
  end

  local q = utility.vector_cross_product(s, edge1)
  local v = utility.vector_dot_product(ray_vector, q) * f
  if v < 0.0 or (v + u) > 1.0 then
    return { exists = false, point = ray_end }
  end

  local t = f * utility.vector_dot_product(edge2, q)
  if t < 0 or t > 1 then
    return { exists = false, point = ray_end }
  end

  return { exists = true, point = utility.vector_add(ray_origin, utility.vector_scale(ray_vector, t)) }
end

utility["get_line_intersection"] = function(p1, p2, face_vertices)
  local ray_origin = p1
  local ray_dir = utility.vector_subtract(p2, p1)
  for i = 1, table.getn(face_vertices)-3, 3 do
    local v1 = face_vertices[i]
    local v2 = face_vertices[i+1]
    local v3 = face_vertices[i+2]
    local intersection = get_line_triangle_intersection(ray_origin, ray_dir, v1, v2, v3)
    if intersection.exists then
      return intersection
    end
  end

  return { exists = false, point = p2 }
end

utility["get_closest_line_intersection"] = function(p1, p2, face_vertices)
  local ray_origin = p1
  local ray_dir = utility.vector_subtract(p2, p1)
  local closest_intersection = { exists = false, point = p2 }
  local closest_intersection_dist = utility.get_vector_distance(p1, p2)
  for i = 1, table.getn(face_vertices)-3, 3 do
    local v1 = face_vertices[i]
    local v2 = face_vertices[i+1]
    local v3 = face_vertices[i+2]
    local intersection = get_line_triangle_intersection(ray_origin, ray_dir, v1, v2, v3)
    local intersection_dist = utility.get_vector_distance(intersection.point, p1)
    if intersection.exists and intersection_dist < closest_intersection_dist then
      closest_intersection_dist = intersection_dist
      closest_intersection = intersection
    end
  end

  return closest_intersection
end

return utility
