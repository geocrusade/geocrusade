package main

import (
  "encoding/json"
  "io/ioutil"
  "os"
)

type Vector3 struct {
  X float32
  Y float32
  Z float32
}

func (v Vector3) Add(other Vector3) Vector3 {
  return Vector3{ X: v.X + other.X, Y: v.Y + other.Y, Z: v.Z + other.Z }
}

func (v Vector3) Scale(value float32) Vector3 {
  return Vector3 { X: v.X * value, Y: v.Y * value, Z: v.Z * value }
}

func (v Vector3) Subtract(other Vector3) Vector3 {
  return Vector3{ X: v.X - other.X, Y: v.Y - other.Y, Z: v.Z - other.Z }
}

func (a Vector3) CrossProduct(b Vector3) Vector3 {
  return Vector3{
    X: a.Y * b.Z - a.Z * b.Y,
    Y: a.Z * b.X - a.X * b.Z,
    Z: a.X * b.Y - a.Y * b.X,
  }
}

func (a Vector3) DotProduct(b Vector3) float32 {
  return a.X*b.X + a.Y*b.Y + a.Z*b.Z
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
