package main

var worldMesh []Vector3

func initPhysics() error {
  return readJSONFromFile("./data/world_vertices.json", &worldMesh)
}

// Suggested by BrunoLevy https://stackoverflow.com/a/42752998
// Source: Möller–Trumbore ray-triangle intersection algorithm on Wikipedia

func getLineTriangleIntersection(p1, p2 Vector3, tri Triangle) (bool, Vector3) {
  var epsilon float64 =  0.0000001
  lineDiff := p2.Subtract(p1)
  edge1 := tri.V2.Subtract(tri.V1)
  edge2 := tri.V3.Subtract(tri.V1)
  h := lineDiff.CrossProduct(edge2)
  a := edge1.DotProduct(h)
  if a > -epsilon && a < epsilon {
    return false, p2 // line is parallel to triangle
  }

  f := 1.0 / a
  s := p1.Subtract(tri.V1)
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

func getClosestLineIntersection(p1, p2 Vector3, vertices []Vector3) (bool, Vector3, Triangle) {
  found := false
  closestPoint := p2
  closestDist := closestPoint.Subtract(p1).Magnitude()
  closestTriangle := Triangle{}

  for i := 0; i < len(vertices); i+=3 {
    tri := Triangle{
      vertices[i],
      vertices[i+1],
      vertices[i+2],
    }
    exists, point := getLineTriangleIntersection(p1, p2, tri)
    if exists {
      dist := point.Subtract(p1).Magnitude()
      if dist < closestDist {
        closestDist = dist
        closestPoint = point
        closestTriangle = tri
      }
      found = true
    }
  }

  return found, closestPoint, closestTriangle
}

func getGroundInteraction(position, inputDir Vector3) (bool, Vector3) {
  grounded, _, groundTriangle := getClosestLineIntersection(position.Add(Vector3{0,0.1,0}), position.Add(Vector3{0,-0.1,0}), worldMesh)

  if grounded {
    surfaceNormal := groundTriangle.SurfaceNormal()
    normal := surfaceNormal.Normalize()

    inputDir = inputDir.Normalize()

    return true, inputDir.Rejection(normal)
  }

  return false, inputDir
}

func clipVelocityWithCollisions(position Vector3, velocity Vector3) Vector3 {
  hit, point, _ := getClosestLineIntersection(position, adjustedPosition.Add(velocity), worldMesh)

  if hit {
    return point.Subtract(position)
  }

  return velocity
}
