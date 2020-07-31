local util = require("utility")

local ability_codes = {
  ["FIRE"] = 0
}

local effect_codes = {
  ["BURN"] = 0
}

local ability_defaults = {
  cast_duration_seconds: 0.0,
  max_target_distance: 0,
  power_cost: 0,
  is_projectile: false,
  meters_per_second: 3.0,
  on_hit: {
    effects: []
  },
  on_hit_enemy: {
    effects: [],
    health_delta: 0
  }
  on_hit_friendly: {
    effects: [],
    health_delta: 0
  }
}

local effect_defaults = {
  duration_seconds: 0,
  health_per_second: 0,
  max_stacks: 1
}

local game_config = {

    ability_codes = ability_codes,
    ability_config = {

      [ability_codes.FIRE] = {
        primary : {
          cast_duration_seconds: 1.0,
          max_target_distance: 30,
          power_cost: 10,
          is_projectile: true,
          on_hit: {
            effects: [ effect_codes.BURN ]
          },
          on_hit_enemy: {
            health_delta: -10
          },
        },
        secondary : {
          cast_duration_seconds: 0.5,
          power_cost: 5,
          on_hit_enemy: {
            health_delta: -5
          }
        }
      }

    },

    effect_codes = effect_codes,
    effect_config = {
      [effect_codes.BURN] = {
        duration_seconds: 3,
        health_per_second: -1,
        max_stacks: 4
      }
    }
}

local function process_config()
  for ability_code, ability in pairs(game_config.ability_config) do
      -- fill in defaults where properties are not defined
      ability.primary = util.merge_table_into(ability_defaults, ability.primary)

      -- fill in undefined secondary properties with values from primary
      ability.secondary = util.merge_table_into(ability.primary, ability.secondary)

      game_config.ability_config[ability_code] = ability
  end

  for effect_code, effect in pairs(game_config.effect_config) do
    -- fill in defaults where properties are not defined
    game_config.effect_config[effect_code] = util.merge_table_into(effect_defaults, effect)
  end
end

process_config()

return game_config
