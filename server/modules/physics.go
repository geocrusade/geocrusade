package main

// import (
//   "sync"
// )

var worldMesh []Vector3

func initPhysics() error {
  return readJSONFromFile("./data/world_vertices.json", &worldMesh)
}

// Suggested by BrunoLevy https://stackoverflow.com/a/42752998
// Source: Möller–Trumbore ray-triangle intersection algorithm on Wikipedia

func getLineTriangleIntersection(p1, p2, v1, v2, v3 Vector3) (bool, Vector3) {
  var epsilon float32 =  0.0000001
  lineDiff := p2.Subtract(p1)
  edge1 := v2.Subtract(v1)
  edge2 := v3.Subtract(v1)
  h := lineDiff.CrossProduct(edge2)
  a := edge1.DotProduct(h)
  if a > -epsilon && a < epsilon {
    return false, p2 // line is parallel to triangle
  }

  f := 1.0 / a
  s := p1.Subtract(v1)
  u := f * s.DotProduct(h)

  if u < 0.0 || u > 1.0 {
    return false, p2
  }

  q := s.CrossProduct(edge1)
  v := lineDiff.DotProduct(q) * f

  if v < 0.0 || (v + u) > 1.0 {
    return false, p2
  }

  t := f * edge2.DotProduct(q)

  if t < 0 || t > 1 {
    return false, p2
  }

  return true, p1.Add(lineDiff.Scale(t))
}

func getLineIntersection(p1, p2 Vector3, vertices []Vector3) (bool, Vector3) {
  for i := 0; i < len(vertices); i+=3 {
    v1 := vertices[i]
    v2 := vertices[i+1]
    v3 := vertices[i+2]
    exists, point := getLineTriangleIntersection(p1, p2, v1, v2, v3)
    if exists {
      return exists, point
    }
  }

  return false, p2
}

func isOnGround(position Vector3) bool {
  intersects, _ := getLineIntersection(position, position.Add(Vector3{0,-0.1,0}), worldMesh)

  return intersects
}
