package main

type AbilityType int

const (
  FireType AbilityType = iota
  MeleeType
  LifeType
  AgilityType
)

type EffectType int

const (
  BurnType EffectType = iota
  BleedType
  MendType
  SprintType
)

type AbilityComponentType int

const (
  CastType AbilityComponentType = iota
  RangeType
  PowerDeltaType
  HealthDeltaType
  OnHitType
  OnHitAllyType
  OnHitHostileType
  ApplyEffectsType
  ProjectileType
)
type IAbilityComponent interface {
  GetType() AbilityComponentType
  GetName() string
}

type AbilityComponent struct {
  Type AbilityComponentType
  Name string
}

func (c AbilityComponent) GetType() AbilityComponentType {
  return c.Type
}

func (c AbilityComponent) GetName() string {
  return c.Name
}

type Cast struct {
  AbilityComponent
  DurationSeconds float32
  CancelOnMove bool
}

func NewCast(durationSeconds float32, cancelOnMove bool) Cast {
  return Cast{ AbilityComponent{ CastType, "Cast"} , durationSeconds, cancelOnMove }
}

type Range struct {
  AbilityComponent
  MinMeters float32
  MaxMeters float32
}

func NewRange(minMeters float32, maxMeters float32) Range {
  return Range{ AbilityComponent{ RangeType, "Range"}, minMeters, maxMeters }
}

type PowerDelta struct {
  AbilityComponent
  Value float32
}

func NewPowerDelta(value float32) PowerDelta {
  return PowerDelta{ AbilityComponent{ PowerDeltaType, "PowerDelta" }, value }
}

type HealthDelta struct {
  AbilityComponent
  Value float32
}

func NewHealthDelta(value float32) HealthDelta {
  return HealthDelta{ AbilityComponent{ HealthDeltaType, "HealthDelta" }, value }
}

type OnHit struct {
  AbilityComponent
  Components []IAbilityComponent
}

func NewOnHit(components []IAbilityComponent) OnHit {
  return OnHit{ AbilityComponent{ OnHitType, "OnHit" }, components }
}

type OnHitAlly struct {
  AbilityComponent
  Components []IAbilityComponent
}

func NewOnHitAlly (components []IAbilityComponent) OnHitAlly {
  return OnHitAlly{ AbilityComponent{ OnHitAllyType, "OnHitAlly" }, components }
}

type OnHitHostile struct {
  AbilityComponent
  Components []IAbilityComponent
}

func NewOnHitHostile (components []IAbilityComponent) OnHitHostile {
  return OnHitHostile{ AbilityComponent{ OnHitHostileType, "OnHitHostile" }, components }
}

type ApplyEffects struct {
  AbilityComponent
  Effects []EffectType
}

func NewApplyEffects (effects []EffectType) ApplyEffects{
  return ApplyEffects{ AbilityComponent{ ApplyEffectsType, "ApplyEffects" }, effects }
}

type Projectile struct {
  AbilityComponent
  MetersPerSecond float32
  Components []IAbilityComponent
}

func NewProjectile (metersPerSecond float32, components []IAbilityComponent) Projectile {
  return Projectile{ AbilityComponent{ ProjectileType, "Projectile" }, metersPerSecond, components }
}

type AbilityConfig struct {
  Type AbilityType
  Name string
  Components []IAbilityComponent
}

var FireConfig = AbilityConfig{FireType, "Fire", []IAbilityComponent {
  NewCast(1.0, true),
  NewRange(0, 30),
  NewPowerDelta(-20),
  NewProjectile(3.0, []IAbilityComponent{
    NewOnHit([]IAbilityComponent{ NewApplyEffects([]EffectType{ BurnType }) }),
    NewOnHitHostile([]IAbilityComponent{ NewHealthDelta(-20) }),
  }),
}}
