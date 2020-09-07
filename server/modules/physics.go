package main

var worldMesh []Triangle

func initPhysics() error {

  worldMeshVertices := []Vector3{}

  err := readJSONFromFile("./data/world_vertices.json", &worldMeshVertices)

  if err != nil {
    return err
  }

  for i := 0; i < len(worldMeshVertices); i+=3 {
    tri := Triangle{
      worldMeshVertices[i],
      worldMeshVertices[i+1],
      worldMeshVertices[i+2],
    }

    worldMesh = append(worldMesh, tri)
  }

  return nil
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

func getClosestLineIntersection(p1, p2 Vector3, mesh []Triangle) (bool, Vector3, Triangle) {
  found := false
  closestPoint := p2
  closestDist := closestPoint.Subtract(p1).Magnitude()
  closestTriangle := Triangle{}

  for _, tri := range(mesh) {
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

//Markus Jarderot
//https://stackoverflow.com/a/17503268
func doesBoxIntersectTriangle(box Box, tri Triangle) bool {

  boxNormals := []Vector3 {
    Vector3{1, 0, 0},
    Vector3{0, 1, 0},
    Vector3{0, 0, 1},
  }

  triVerts := tri.Vertices()
  boxEnd := box.End()
  boxStart := box.Start()

  for _, axis := range(boxNormals) {
    min, max := getMinMaxOfProjectedVertices(triVerts, axis)
    if max < boxStart.DotProduct(axis) || min > boxEnd.DotProduct(axis) {
      return false
    }
  }

  triNormal := tri.SurfaceNormal()
  triNormalOffset := triNormal.DotProduct(tri.V1)
  boxVerts := box.Vertices()
  boxMin, boxMax := getMinMaxOfProjectedVertices(boxVerts, triNormal)

  if boxMax < triNormalOffset || boxMin > triNormalOffset {
    return false
  }

  triEdges := tri.Edges()

  for _, edge := range(triEdges) {
    for _, n := range(boxNormals) {
      axis := edge.CrossProduct(n)
      boxMin, boxMax = getMinMaxOfProjectedVertices(boxVerts, axis)
      triMin, triMax := getMinMaxOfProjectedVertices(triVerts, axis)
      if boxMax < triMin || boxMin > triMax {
        return false
      }
    }
  }

  return true

}

func getBoxIntersections(hitBox Box, mesh []Triangle) ([]Triangle) {
    inters := []Triangle{}
    for _, tri := range(mesh) {
      does := doesBoxIntersectTriangle(hitBox, tri)
      if does {
        inters = append(inters, tri)
      }
    }

    return inters
}

func getGroundAdjustedVelocity(hitBox Box, velocity Vector3, intersectedTris []Triangle ) (bool, Vector3) {
  adjustedVel := velocity
  boxGroundPoint := hitBox.Center.Add(Vector3{0, -1, 0}.Mult(hitBox.Extends))
  groundTestPoint := boxGroundPoint.Add(Vector3{0, -0.1, 0})
  grounded, _, groundTriangle := getClosestLineIntersection(hitBox.Center, groundTestPoint, intersectedTris)

  if grounded {
    groundNormal := groundTriangle.SurfaceNormal().Normalize()

    adjustedVel = adjustedVel.Normalize().Rejection(groundNormal).Scale(adjustedVel.Magnitude())
  }

  return grounded, adjustedVel
}

func getCollisionAdjustedVelocity(hitBox Box, velocity Vector3, intersectedTris *[]Triangle ) (Vector3) {

  if velocity.Magnitude() < 0.00001 {
    return velocity
  }

  adjustedVel := velocity

  hitBoxCollisionPoint := hitBox.Center.Add(adjustedVel.Normalize().Mult(hitBox.Extends))
  furthestPoint := hitBoxCollisionPoint.Add(adjustedVel)

  tempBox := Box{ hitBox.Center.Add(adjustedVel), hitBox.Extends }
  *intersectedTris = getBoxIntersections(tempBox, worldMesh)

  for _, tri := range(*intersectedTris) {
    _, point := getLineTriangleIntersection(hitBoxCollisionPoint, furthestPoint, tri)
    diff := point.Subtract(hitBoxCollisionPoint)
    adjustedVel = adjustedVel.Clamp(diff, diff)
    // TODO: it is possible that the box intersects the triangle but from a different
    // point than hitBoxCollisionPoint such as clipping an edge while falling
  }

  return adjustedVel
}
