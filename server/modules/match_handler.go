package main

import (
  "context"
  "database/sql"
  "encoding/json"
  "github.com/gofrs/uuid"
  "github.com/heroiclabs/nakama-common/runtime"
)

const (
  OpCodeStateInit int64 = iota
  OpCodeStateUpdate
  OpCodeOnJoinConfig
)

type CastState struct {
  AbilityTypes []int
  ElapsedSeconds float32
}

type EffectState struct {
  Type int
  ElapsedSeconds float32
  Count int
}

type CharacterState struct {
  Name string
  Health int
  Power int
  Speed float32
  Position Vector3
  Rotation Vector3
  Cast CastState
  Target string
  AbilityCodes []int
  Effects []EffectState
}

type PrivateOnJoinConfig struct {
  CharacterId string
}

type PublicMatchState struct {
  Characters map[string]CharacterState
}

type PrivateMatchState struct {
  Presences map[string]runtime.Presence
  UserIdToCharacterIdMap map[string]string
}

type MatchState struct {
  Private PrivateMatchState
  Public PublicMatchState
}

type Match struct{}

func (m *Match) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
    state := &MatchState{
      Private: PrivateMatchState{
        Presences: make(map[string]runtime.Presence),
        UserIdToCharacterIdMap: make(map[string]string),
      },
      Public: PublicMatchState{
        Characters: make(map[string]CharacterState),
      },
    }
    return state, MatchTickRate, WorldMatchLabel
}

func (m *Match) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
    mState, _ := state.(*MatchState)
    _, exists := mState.Private.Presences[presence.GetUserId()]
    message := ""
    if exists {
      message = "User already joined."
    }
    return mState, !exists, message
}

func (m *Match) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
    mState, _ := state.(*MatchState)

    for _, p := range presences {
      characterUUID, _ := uuid.NewV4()
      characterId := characterUUID.String()
      mState.Private.Presences[p.GetUserId()] = p
      mState.Private.UserIdToCharacterIdMap[p.GetUserId()] = characterId
      mState.Public.Characters[characterId] = CharacterState{
        Name: p.GetUsername(),
        Health: GameConfig.DefaultHealth,
        Power: GameConfig.DefaultPower,
        Speed: GameConfig.DefaultSpeed,
        Position: GameConfig.WorldStartPosition,
        Rotation: GameConfig.WorldStartRotation,
      }
      bytes, _ := json.Marshal(PrivateOnJoinConfig{ characterId })

      dispatcher.BroadcastMessage(OpCodeOnJoinConfig, bytes, []runtime.Presence{ p }, nil, true)
    }

    bytes, _ := json.Marshal(mState.Public)

    dispatcher.BroadcastMessage(OpCodeStateInit, bytes, presences, nil, true)

    return mState
}

func (m *Match) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
  mState, _ := state.(*MatchState)

  for _, p := range presences {
    userId := p.GetUserId()
    characterId := mState.Private.UserIdToCharacterIdMap[userId]
    delete(mState.Private.Presences, userId)
    delete(mState.Private.UserIdToCharacterIdMap, userId)
    delete(mState.Public.Characters, characterId)
  }

  return mState
}

func (m *Match) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
    return state
}

func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
  return state
}
