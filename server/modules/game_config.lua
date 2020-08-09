local util = require("utility")

local ability_codes = {
  FIRE = 1,
  MELEE = 2,
  LIFE = 3,
  MOBILITY = 4
}

local effect_codes = {
  BURN = 1,
  BLEED = 2,
  MEND = 3,
  SPRINT = 4,
  DASH = 5,
}

local ability_defaults = {
  cast_duration_seconds = 0.0,
  cast_while_moving = false,
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
  name = "",
  color = { r = 0, g = 0, b = 0 },
  duration_seconds = 0,
  health_per_second = 0,
  max_stacks = 1,
  effects_removed = {},
  speed_inc_percent = 0,
  forward_move_per_second = { x = 0, y = 0, z = 0 }
}

local game_config = {

    max_health = 100,
    max_power = 100,

    passive_power_per_second = 1,
    passive_health_per_second = 1,

    default_speed = 200,

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
      },

      [ability_codes.MELEE] = {
        name = "Melee",
        primary = {
          cast_duration_seconds = 0.25,
          cast_while_moving = true,
          max_target_distance = 5,
          power_cost = 2,
          on_hit_enemy = {
            effects = { effect_codes.BLEED },
            health_delta = -2
          }
        },
        secondary = {
          cast_duration_seconds = 0.1,
          max_target_distance = 0,
          power_cost = 1,
          on_hit_enemy = {
            effects = { effect_codes.BLEED },
            health_delta = -1
          }
        }
      },

      [ability_codes.LIFE] = {
        name = "Life",
        primary = {
          cast_duration_seconds = 1,
          max_target_distance = 40,
          power_cost = 20,
          on_hit_friendly = {
            health_delta = 10
          }
        },
        secondary = {
          cast_duration_seconds = 0.5,
          max_target_distance = 0,
          power_cost = 10,
          on_hit_friendly = {
            effects = { effect_codes.MEND },
            health_delta = 0
          }
        }
      },

      [ability_codes.MOBILITY] = {
        name = "Mobility",
        primary = {
          cast_duration_seconds = 0.25,
          cast_while_moving = true,
          max_target_distance = 0,
          power_cost = 30,
          on_hit_friendly = {
            effects = { effect_codes.SPRINT, effect_codes.DASH },
            health_delta = 0
          }
        },
        secondary = {
          cast_duration_seconds = 0.1,
          max_target_distance = 0,
          power_cost = 10,
          on_hit_friendly = {
            effects = { effect_codes.SPRINT },
            health_delta = 0
          }
        }
      }
    },

    effect_codes = effect_codes,
    effect_defaults = effect_defaults,
    effect_config = {
      [effect_codes.BURN] = {
        name = "Burn",
        color = { r = 255, g = 69, b = 0 },
        duration_seconds = 3,
        health_per_second = -1,
        max_stacks = 4
      },
      [effect_codes.BLEED] = {
        name = "Bleed",
        color = { r = 255, g = 0, b = 0 },
        duration_seconds = 5,
        health_per_second = -1,
        max_stacks = 4
      },
      [effect_codes.MEND] = {
        name = "Mend",
        color = { r = 0, g = 255 , b = 0},
        duration_seconds = 5,
        health_per_second = 1,
        max_stacks = 4,
        effects_removed = { effect_codes.BLEED }
      },
      [effect_codes.SPRINT] = {
        name = "Sprint",
        color = { r = 0, g = 204, b = 204 },
        duration_seconds = 3,
        max_stacks = 4,
        speed_inc_percent = 0.2
      },
      [effect_codes.DASH] = {
        name = "Dash",
        color = { r = 102, g = 178, b = 255 },
        duration_seconds = 1,
        max_stacks = 1,
        forward_move_per_second = { x = 0, y = 0, z = -10 }
      },
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
