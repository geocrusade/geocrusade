local util = require("utility")

local ability_codes = {
  ["FIRE"] = 1
}

local effect_codes = {
  ["BURN"] = 1
}

local ability_defaults = {
  cast_duration_seconds = 0.0,
  max_target_distance = 0,
  power_cost = 0,
  is_projectile = false,
  meters_per_second = 0,
  on_hit = {
    effects = {},
    health_delta = 0
  },
  on_hit_enemy = {
    effects = {},
    health_delta = 0
  },
  on_hit_friendly = {
    effects = {},
    health_delta = 0
  }
}

local effect_defaults = {
  duration_seconds = 0,
  health_per_second = 0,
  max_stacks = 1
}

local game_config = {

    character_line_of_sight_point = { x = 0, y = 2, z = 0 },

    max_composite_ability_size = 4,

    ability_codes = ability_codes,
    ability_config = {

      [ability_codes.FIRE] = {
        name = "Fire",
        primary = {
          cast_duration_seconds = 1.0,
          max_target_distance = 40,
          power_cost = 10,
          is_projectile = true,
          meters_per_second = 20,
          on_hit = {
            effects = { effect_codes.BURN }
          },
          on_hit_enemy = {
            health_delta = -10
          }
        },
        secondary = {
          cast_duration_seconds = 0.5,
          max_target_distance = 5,
          meters_per_second = 0,
          power_cost = 5,
          on_hit_enemy = {
            health_delta = -5
          }
        }
      }

    },

    effect_codes = effect_codes,
    effect_defaults = effect_defaults,
    effect_config = {
      [effect_codes.BURN] = {
        name = "Burn",
        color = { r = 255, g = 0, b = 0 },
        duration_seconds = 3,
        health_per_second = -1,
        max_stacks = 4
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

  -- to support json encoding convert ability & effect configs to use array indexing instead of integer keys
  local ability_config_array = {}
  for _, code in pairs(ability_codes) do
    ability_config_array[code] = game_config.ability_config[code]
  end
  game_config.ability_config = ability_config_array

  local effect_config_array = {}
  for _, code in pairs(effect_codes) do
    effect_config_array[code] = game_config.effect_config[code]
  end
  game_config.effect_config = effect_config_array

end

process_config()

return game_config
