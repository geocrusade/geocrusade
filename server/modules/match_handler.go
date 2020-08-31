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
  OpCodeSetJoinConfig
  OpCodeInputUpdate
)

type InputState struct {
  Direction Vector3
  Jump bool
  ClientTick int64
}

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

      dispatcher.BroadcastMessage(OpCodeSetJoinConfig, bytes, []runtime.Presence{ p }, nil, true)
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
  mState, _ := state.(*MatchState)

  delta := float32(1.0 / MatchTickRate)

  for _, message := range messages {
    switch message.GetOpCode() {
    case OpCodeInputUpdate:
      input := InputState{}
      err := json.Unmarshal(message.GetData(), &input)
      if err != nil {
        logger.Error("Error reading input update %v", err)
      }
      userId := message.GetUserId()
      characterId := mState.Private.UserIdToCharacterIdMap[userId]
      character := mState.Public.Characters[characterId]
      input.Direction.Y = 0
      velocity := input.Direction.Scale(character.Speed * delta)
      nextPosition := character.Position.Add(velocity)
      character.Position = nextPosition
    }
  }
  return mState
}

func (m *Match) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
  return state
}
