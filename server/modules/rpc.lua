local nk = require("nakama")

local function get_world_id(_, _)
  local matches = nk.match_list()
  local current_match = matches[1]

  if current_match == nil then
      return nk.match_create("match_handler", { is_world = true })
  else
      return current_match.match_id
  end
end

local ability_codes = {
  ["FIRE"] = 0
}

local effect_codes = {
  ["BURN"] = 0
}

local game_config = {

    ability_codes = ability_codes,
    ability_config = {

      [ability_codes.FIRE] = {
        base : {
          cast_duration_seconds: 1.0,
          max_target_distance: 30,
          power_cost: 10,
          projectile: {
            meters_per_second: 3,
            on_hit: {
              effects: [ effect_codes.BURN ]
            },
            on_hit_enemy: {
              health_delta: -10,
            },
            on_hit_friendly: {
              health_delta: 0,
            }
          }
        },
        addition : {
          cast_duration_seconds: 0.5,
          power_cost: 5,
          projectile: {
            on_hit_enemy: {
              health_delta: -5
            }
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

local function get_game_config(_, _)
  return nk.json_encode(game_config)
end

nk.register_rpc(get_world_id, "get_world_id")
