package main

import (
  "context"
  "database/sql"
  "github.com/heroiclabs/nakama-common/runtime"
)

func rpcGetWorldId(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
  matches, err := nk.MatchList(ctx, 1, true, WorldMatchLabel, getIntPointer(WorldMinPlayers), getIntPointer(WorldMaxPlayers), "");
  if err != nil {
    logger.Error("Match List Error %v", err)
    return "", err
  } else if len(matches) > 0 {
    return matches[0].GetMatchId(), nil
  }

  matchId, err := nk.MatchCreate(ctx, MatchModuleName, nil);
  if err != nil {
    logger.Error("Match Create Error %v", err)
    return "", err
  }

  return matchId, nil
}
