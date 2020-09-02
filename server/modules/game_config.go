package main

// hits, attribute changes, projectiles, effects, canceled effects, casts, range, resource cost
// ability add rules
// ranged projectile, ranged instant, ranged instant aoe, ranged projectile aoe, melee aoe, melee, multi target, shield
// dot, hots, sets

type EffectType struct {
  DurationSeconds float64
  MaxStackSize int
  HealthPerTick int
  PowerPerTick int
  SpeedDelta float64
  DamageMult float64
  BoxSize Vector3
}

type AbilityType struct {
  PowerDelta int
  MinRange float64
  MaxRange float64
  CastSeconds float64
  CastWhileMoving bool
  PassiveEffects []int
  HitEffects []int
  HitHealthDelta int
  HitEnemyHealthDelta int
  HitEnemyEffects []int
  HitAllyEffects []int
  HitAllyRemoveEffects []int
  HitAllyMoveDelta Vector3
  HitAllyHealthDelta int
  ProjectileMetersPerSecond float64
}

type AbilitiesConfigType struct {
  Base map[int]AbilityType
  Addition map[int]AbilityType
}

type GameConfigType struct {
  Abilities AbilitiesConfigType
  Effects map[int]EffectType
  DefaultHealth int
  DefaultPower int
  DefaultSpeed float64
  DefaultJumpSpeed float64
  WorldStartPosition Vector3
  WorldStartRotation Vector3
  Gravity float64
}

const (
  BurnType int = iota
  BleedType
  MendType
  SprintType
  FortifyType
  ShieldType
)

const (
  FireType int = iota
  MeleeType
  LifeType
  MobilityType
  ProtectionType
)

func NewGameConfig() GameConfigType {
  effects := make(map[int]EffectType)


  effects[BurnType] = EffectType{
    DurationSeconds: 3,
    MaxStackSize: 4,
    HealthPerTick: -5,
  }

  effects[BleedType] = EffectType{
    DurationSeconds: 3,
    MaxStackSize: 4,
    HealthPerTick: -1,
  }

  effects[MendType] = EffectType{
    DurationSeconds: 3,
    MaxStackSize: 4,
    HealthPerTick: 1,
  }

  effects[SprintType] = EffectType{
    DurationSeconds: 3,
    MaxStackSize: 4,
    SpeedDelta: 25,
  }

  effects[FortifyType] = EffectType{
    DurationSeconds: -1, //forever
    MaxStackSize: 1,
    DamageMult: 0.8,
  }

  effects[ShieldType] = EffectType{
    DurationSeconds: 5,
    MaxStackSize: 4,
    BoxSize: Vector3{2, 2, 0.5},
  }

  base := make(map[int]AbilityType)
  addition := make(map[int]AbilityType)

  base[FireType] = AbilityType{
    PowerDelta: -20,
    MaxRange: 30,
    CastSeconds: 1,
    HitEnemyHealthDelta: -20,
    HitEffects: []int { BurnType },
    ProjectileMetersPerSecond: 5,
  }

  addition[FireType] = AbilityType{
    PowerDelta: -5,
    MaxRange: 5,
    CastSeconds: 0.25,
    HitEnemyHealthDelta: -5,
    HitEffects: []int { BurnType },
  }

  base[MeleeType] = AbilityType{
    PowerDelta: -5,
    MaxRange: 5,
    CastSeconds: 0.25,
    CastWhileMoving: true,
    HitEnemyHealthDelta: -5,
    HitEffects: []int { BleedType },
  }

  addition[MeleeType] = AbilityType{
    PowerDelta: -5,
    CastSeconds: 0.25,
    CastWhileMoving: true,
    HitEnemyHealthDelta: -5,
    HitEffects: []int { BleedType },
  }

  base[LifeType] = AbilityType{
    PowerDelta: -20,
    MaxRange: 30,
    CastSeconds: 1,
    HitAllyHealthDelta: 10,
    HitAllyEffects: []int { MendType },
    HitAllyRemoveEffects: []int { BleedType },
  }

  addition[LifeType] = AbilityType{
    PowerDelta: -10,
    MaxRange: 5,
    CastSeconds: 0.25,
    HitAllyHealthDelta: 5,
    HitAllyEffects: []int { MendType },
    HitAllyRemoveEffects: []int { BleedType },
  }

  base[MobilityType] = AbilityType{
    PowerDelta: -20,
    MaxRange: 5,
    CastSeconds: 0.25,
    CastWhileMoving: true,
    HitAllyMoveDelta: Vector3{ 0, 0, -10 },
    HitAllyEffects: []int { SprintType },
  }

  addition[MobilityType] = AbilityType{
    PowerDelta: -5,
    CastSeconds: 0.25,
    CastWhileMoving: true,
    HitAllyMoveDelta: Vector3{ 0, 0, -2 },
    HitAllyEffects: []int { SprintType },
  }

  base[ProtectionType] = AbilityType{
    PowerDelta: -20,
    MaxRange: 5,
    CastSeconds: 0.5,
    CastWhileMoving: true,
    PassiveEffects: []int { FortifyType },
    HitAllyEffects: []int { ShieldType },
  }

  addition[ProtectionType] = AbilityType{
    PowerDelta: -10,
    CastSeconds: 0.25,
    CastWhileMoving: true,
    HitAllyEffects: []int { ShieldType },
  }

  return GameConfigType{
    Abilities: AbilitiesConfigType{ base, addition },
    Effects: effects,
    DefaultHealth: 100,
    DefaultPower: 100,
    DefaultSpeed: 5,
    DefaultJumpSpeed: 8,
    WorldStartPosition: Vector3{ 0, 15, 0 },
    WorldStartRotation: Vector3{ 0, 0, -1 },
    Gravity: -1,
  }
}

var GameConfig GameConfigType = NewGameConfig()
