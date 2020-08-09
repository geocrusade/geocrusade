local nk = require("nakama")
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

-- Posted by BrunoLevy https://stackoverflow.com/a/42752998
-- Möller–Trumbore ray-triangle intersection algorithm

local get_line_triangle_intersection = function(ray_origin, ray_dir, a, b, c)
  local e1 = utility.vector_subtract(b, a)
  local e2 = utility.vector_subtract(c, a)
  local n = utility.vector_cross_product(e1, e2)
  local det = -uility.vector_dot_product(ray_dir, n)
  local invdet = 1.0 / det
  local ao = utility.vector_subtract(ray_origin, a)
  local dao = utility.vector_cross_product(ao, ray_dir)
  local u = utility.vector_dot_product(e2, dao) * invdet
  local v = -utility.vector_dot_product(e1, dao) * invdet
  local t = utility.vector_dot_product(ao, n) * invdet
  local exists = (det >= 0.000001 and t >= 0.0 and u >= 0.0 and v >= 0.0 and (u+v) <= 1.0)
  local point = utility.vector_utility.vector_add(ray_origin, utility.vector_multiply(t, ray_dir))
  return { exists, point };
end

utility["get_line_intersection"] = function(p1, p2, face_vertices)
  local ray_origin = p1
  local ray_dir = utility.vector_normalize(utility.vector_subtract(p2, p1))
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

return utility
