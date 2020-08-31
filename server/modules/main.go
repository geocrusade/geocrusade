package main

import (
  "context"
  "database/sql"
  "github.com/heroiclabs/nakama-common/runtime"
)

func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {

  if err := initializer.RegisterMatch(MatchModuleName, registerMatchCallback); err != nil {
    logger.Error("Unable to register match: %v", err)
    return err
  }

  if err := initializer.RegisterRpc("get_world_id", rpcGetWorldId); err != nil {
    logger.Error("Unable to register rpc: %v", err)
    return err
  }

  if err := initPhysics(); err != nil {
    logger.Error("Unable to init physics: %v", err)
    return err
  }

  return nil
}

func registerMatchCallback(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
  return &Match{}, nil
}
