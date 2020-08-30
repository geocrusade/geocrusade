package main

import (
  "context"
  "database/sql"
  "github.com/heroiclabs/nakama-common/runtime"
)

type Vector3 struct {
  X float32
  Y float32
  Z float32
}

func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {

  if err := initializer.RegisterMatch(MatchModuleName, func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
    return &Match{}, nil
  }); err != nil {
    logger.Error("Unable to register match: %v", err)
    return err
  }

  if err := initializer.RegisterRpc("get_world_id", rpcGetWorldId); err != nil {
    logger.Error("Unable to register rpc: %v", err)
    return err
  }
  return nil
}
