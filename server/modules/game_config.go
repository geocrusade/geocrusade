package main

type EffectType int

type ResourceCost struct {
  Power int
  Health int
}

type Range struct {
  MinMeters float32
  MaxMeters float32
}

type Cast struct {
  DurationSeconds float32
  CancelOnMove bool
}

type AttributeChange struct {
  Health int
  Power int
  Speed float32
  Effects []EffectConfig
}

type OnHit struct {
  Any AttributeChange
  Ally AttributeChange
  Hostile AttributeChange
}

type Projectile struct {
  MetersPerSecond float32
  OnHit
}

type BaseAbilityConfig struct {
  ResourceCost
  Range
  Cast
  OnHit
  Projectile
}

type SecondaryAbilityConfig struct {
  Default BaseAbilityConfig
  Overrides map[string]BaseAbilityConfig
}

type AbilityConfig struct {
  Primary BaseAbilityConfig
  Secondary SecondaryAbilityConfig
}

type EffectConfig struct {
  DurationSeconds float32
  MaxCount int
  OnHit
}

type GameConfigType struct {
  Abilities []AbilityConfig
  Effects []EffectConfig
}

var BurnConfig = EffectConfig{
  3,
  4,
  OnHit{
    Any: AttributeChange{
      Health: -2
    }
  }
}

var FireConfig = AbilityConfig{
  Primary: BaseAbilityConfig{
    ResourceCost{ Power: 20 },
    Range{0, 30},
    Cast{1, true},
    Projectile: Projectile{
      MetersPerSecond: 3,
      OnHit{
        Any: AttributeChange{ Effects: []EffectConfig{ BurnConfig }},
        Hostile: AttributeChange{ Health: -20 },
      },
    },
  },
  Secondary: SecondaryAbilityConfig{
    Default: BaseAbilityConfig{
      ResourceCost{ Power: 5 },
      Range{0, 5},
      Cast{0.25},
      Projectile: Projectile{
        MetersPerSecond: 
      }
    },
  }

}

var GameConfig = GameConfigType{
  []AbilityConfig{
    FireConfig,
    MeleeConfig,
    LifeConfig,
    MobilityConfig,
  },
  []EffectConfig{
    BurnConfig,
    BleedConfig,
    MendConfig,
    SprintConfig,
  },
}
