package main

import (
  "encoding/json"
  "io/ioutil"
  "os"
  "math"
)

type Vector3 struct {
  X float64
  Y float64
  Z float64
}

func (v Vector3) Add(other Vector3) Vector3 {
  return Vector3{ X: v.X + other.X, Y: v.Y + other.Y, Z: v.Z + other.Z }
}

func (v Vector3) Scale(value float64) Vector3 {
  return Vector3 { X: v.X * value, Y: v.Y * value, Z: v.Z * value }
}

func (v Vector3) Subtract(other Vector3) Vector3 {
  return Vector3{ X: v.X - other.X, Y: v.Y - other.Y, Z: v.Z - other.Z }
}

func (a Vector3) Mult(b Vector3) Vector3 {
  return Vector3 { X: a.X * b.X, Y: a.Y * b.Y, Z: a.Z * b.Z }
}

func (a Vector3) CrossProduct(b Vector3) Vector3 {
  return Vector3{
    X: a.Y * b.Z - a.Z * b.Y,
    Y: a.Z * b.X - a.X * b.Z,
    Z: a.X * b.Y - a.Y * b.X,
  }
}

func (a Vector3) DotProduct(b Vector3) float64 {
  return a.X*b.X + a.Y*b.Y + a.Z*b.Z
}

func (a Vector3) Magnitude() float64 {
  return math.Sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z)
}

func (v Vector3) Normalize() Vector3 {
  mag := v.Magnitude()
  if mag == 0 {
    return v.Scale(0)
  }
  return v.Scale(1 / mag)
}

//https://stackoverflow.com/questions/26958198/vector-projection-rejection-in-c
func (a Vector3) Projection(b Vector3) Vector3 {
  return b.Scale(a.DotProduct(b) / b.DotProduct(b))
}

func (a Vector3) Rejection(b Vector3) Vector3 {
  return a.Subtract(a.Projection(b))
}

func (a Vector3) Clamp(min Vector3, max Vector3) Vector3 {
  return Vector3{
    Clamp(a.X, min.X, max.X),
    Clamp(a.Y, min.Y, max.Y),
    Clamp(a.Z, min.Z, max.Z),
  }
}

func Clamp(value float64, min float64, max float64) float64 {
    return math.Max(math.Min(value, max), min)
}

type Triangle struct {
  V1 Vector3
  V2 Vector3
  V3 Vector3
}

// https://www.khronos.org/opengl/wiki/Calculating_a_Surface_Normal
func (t Triangle) SurfaceNormal() Vector3 {
  edge1 := t.V2.Subtract(t.V1)
  edge2 := t.V3.Subtract(t.V2)
  return edge1.CrossProduct(edge2)
}

func (t Triangle) Vertices() []Vector3 {
  return []Vector3 { t.V1, t.V2, t.V3 }
}

func (t Triangle) Edges() []Vector3 {
  return []Vector3 {
    t.V1.Subtract(t.V2),
    t.V2.Subtract(t.V3),
    t.V3.Subtract(t.V1),
  }
}

type Box struct {
  Center Vector3
  Extends Vector3
}

func (b Box) Start() Vector3 {
  return b.Center.Subtract(b.Extends);
}

func (b Box) End() Vector3 {
  return b.Center.Add(b.Extends);
}

func (b Box) Vertices() []Vector3 {
  return []Vector3 {
    b.Center.Subtract(b.Extends),
    b.Center.Add(Vector3{b.Extends.X, b.Extends.Y, b.Extends.Z}),
    b.Center.Add(Vector3{b.Extends.X, b.Extends.Y, -b.Extends.Z}),
    b.Center.Add(Vector3{b.Extends.X, -b.Extends.Y, b.Extends.Z}),
    b.Center.Add(Vector3{-b.Extends.X, b.Extends.Y, b.Extends.Z}),
    b.Center.Add(Vector3{b.Extends.X, -b.Extends.Y, -b.Extends.Z}),
    b.Center.Add(Vector3{-b.Extends.X, -b.Extends.Y, b.Extends.Z}),
    b.Center.Add(Vector3{-b.Extends.X, b.Extends.Y, -b.Extends.Z}),
  }
}

// for box - triangle intersection
func getMinMaxOfProjectedVertices(verts []Vector3, axis Vector3) (float64, float64) {
  min := math.MaxFloat64
  max := -math.MaxFloat64

  for _, v := range(verts) {
    p := axis.DotProduct(v)
    min = math.Min(p, min)
    max = math.Max(p, max)
  }

  return min, max
}

func getIntPointer(val int) *int {
    return &val
}

func readJSONFromFile(filename string, readTo interface{}) error {
  jsonFile, err := os.Open(filename)

  if err != nil {
      return err
  }

  defer jsonFile.Close()

  byteValue, err := ioutil.ReadAll(jsonFile)

  if err != nil {
      return err
  }

  err = json.Unmarshal(byteValue, readTo)

  return err
}
