package main

import (
  "context"
  "database/sql"
  "github.com/heroiclabs/nakama-common/runtime"
)

func rpcGetWorldId(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
  // var minPlayers *int
  // var maxPlayers *int
  // *minPlayers = WorldMinPlayers
  // *maxPlayers = WorldMaxPlayers
  // matches, err := nk.MatchList(ctx, 1, true, WorldMatchLabel, minPlayers, maxPlayers, "");
  // if err != nil {
  //   return "", err
  // } else if len(matches) > 0 {
  //   return matches[0].GetMatchId(), nil
  // }
  //
  // matchId, err := nk.MatchCreate(ctx, MatchModuleName, nil);
  // if err != nil {
  //   return "", err
  // }

  return "random_match_id_string", nil
}
