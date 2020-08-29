package main

import (
  "context"
  "database/sql"

  "github.com/heroiclabs/nakama-common/runtime"
)

type CastState struct {
  AbilityCodes []int
  ElapsedSeconds float32
}

type Vector3 struct {
  X float32
  Y float32
  Z float32
}

type EffectState struct {
  Code int
  ElapsedSeconds float32
  Count int
}

type CharacterState struct {
  Health int
  Power int
  Cast CastState
  Position Vector3
  Rotation Vector3
  Speed float32
  Target string
  AbilityCodes []int
  Effects []EffectState
}

type MatchState struct {
  Character map[string]CharacterState
}

type Match struct{}

func (m *Match) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
    state := &MatchState{}
    return state, MatchTickRate, WorldMatchLabel
}

func (m *Match) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
    return state, true, ""
}

func (m *Match) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
    return state
}

func (m *Match) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
    return state
}

func (m *Match) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
    return state
}

func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
    return state
}
