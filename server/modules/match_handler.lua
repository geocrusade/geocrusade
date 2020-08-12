
local nk = require("nakama")
local game_config = require("game_config")
local util = require("utility")
local arena_vertices = require("arena_vertices")

local match_handler = {}

local WORLD_SPAWN_POSITION = { x = 150, y = 6, z = -45 }
local WORLD_SPAWN_ROTATION = { x = 0, y = 0, z = -1 }
local TEAM1_SPAWN_POSITION = { x = 150, y = 6, z = -45 }
local TEAM2_SPAWN_POSITION = { x = 150, y = 6, z = 45 }
local TEAM1_SPAWN_ROTATION = { x = 0, y = 0, z = 1 }
local TEAM2_SPAWN_ROTATION = { x = 0, y = 0, z = -1 }
local TICK_RATE = 20

local OpCodes = {
    initial_state = 1,
    update_state = 2,
    update_transform = 3,
    update_input = 4,
    update_jump = 5,
    update_target = 6,
    start_cast = 7,
    cancel_cast = 8,
    update_cast = 9
}

local commands = {}

commands[OpCodes.update_transform] = function(data, state)
    local id = data.id
    if state.positions[id] ~= nil then
        state.positions[id] = data.pos
    end
    if state.rotations[id] ~= nil then
        state.rotations[id] = data.rot
    end
end

commands[OpCodes.update_input] = function(data, state)
    local id = data.id
    local input = data.inp
    if state.inputs[id] ~= nil then
        state.inputs[id].dir = input
    end
end

commands[OpCodes.update_jump] = function(data, state)
    local id = data.id
    if state.inputs[id] ~= nil then
        state.inputs[id].jmp = 1
    end
end

commands[OpCodes.update_target] = function(data, state)
    if state.users[data.id] ~= nil and state.users[data.target_id] ~= nil then
      state.targets[data.id] = data.target_id
    end
end

local get_composite_ability = function(ability_codes)
  local ability_config = game_config.ability_config[ability_codes[1]]
  local primary_ability = ability_config.primary
  local composite_ability = util.table_copy(primary_ability)
  composite_ability.name = ability_config.name
  for i=2, table.getn(ability_codes) do
    ability_config = game_config.ability_config[ability_codes[i]]
    local secondary_ability = ability_config.secondary
    composite_ability.name = string.format("%s,%s", composite_ability.name, ability_config.name)
    composite_ability.cast_duration_seconds = composite_ability.cast_duration_seconds + secondary_ability.cast_duration_seconds
    composite_ability.max_target_distance = composite_ability.max_target_distance + secondary_ability.max_target_distance
    composite_ability.power_cost = composite_ability.power_cost + secondary_ability.power_cost
    composite_ability.meters_per_second = composite_ability.meters_per_second + secondary_ability.meters_per_second

    composite_ability.on_hit.health_delta = composite_ability.on_hit.health_delta + secondary_ability.on_hit.health_delta
    composite_ability.on_hit_enemy.health_delta = composite_ability.on_hit_enemy.health_delta + secondary_ability.on_hit_enemy.health_delta
    composite_ability.on_hit_friendly.health_delta = composite_ability.on_hit_friendly.health_delta + secondary_ability.on_hit_friendly.health_delta

    composite_ability.on_hit.directed_move = util.vector_add(composite_ability.on_hit.directed_move, secondary_ability.on_hit.directed_move)
    composite_ability.on_hit_enemy.directed_move = util.vector_add(composite_ability.on_hit_enemy.directed_move, secondary_ability.on_hit_enemy.directed_move)
    composite_ability.on_hit_friendly.directed_move = util.vector_add(composite_ability.on_hit_friendly.directed_move, secondary_ability.on_hit_friendly.directed_move)

    util.table_insert_all(composite_ability.on_hit.effects, secondary_ability.on_hit.effects)
    util.table_insert_all(composite_ability.on_hit_enemy.effects, secondary_ability.on_hit_enemy.effects)
    util.table_insert_all(composite_ability.on_hit_friendly.effects, secondary_ability.on_hit_friendly.effects)
  end

  return composite_ability
end

local in_line_of_sight = function(pos_a, pos_b)
  pos_a = util.vector_add(pos_a, game_config.character_line_of_sight_point)
  pos_b = util.vector_add(pos_b, game_config.character_line_of_sight_point)
  local intersection = util.get_line_intersection(pos_a, pos_b, arena_vertices)
  return not intersection.exists
end

local can_cast = function(composite_ability, user_id, target_id, state)
  if state.users[user_id] == nil or state.targets[user_id] == nil then
    return false
  end

  if state.powers[user_id] < composite_ability.power_cost then
    return false
  end

  local pos = state.positions[user_id]
  local target_pos = state.positions[target_id]
  local distance_to_target = util.get_vector_distance(pos, target_pos)
  return distance_to_target <= composite_ability.max_target_distance and (user_id == target_id or in_line_of_sight(pos, target_pos))
end

commands[OpCodes.start_cast] = function(data, state)
  if #data.ability_codes <= game_config.max_composite_ability_size then
    local composite_ability = get_composite_ability(data.ability_codes)
    local target_id = state.targets[data.id]
    if can_cast(composite_ability, data.id, target_id, state) then
      state.casts[data.id] = {
        ability_codes = data.ability_codes,
        composite_ability = composite_ability,
        target_id = target_id,
        elapsed_time_seconds = 0.0,
      }
    end
  end
end

commands[OpCodes.cancel_cast] = function(data, state)
  if state.users[data.id] ~= nil and state.casts[data.id] ~= nil then
    state.casts[data.id] = nil
  end
end

commands[OpCodes.update_cast] = function(data, state)
  if state.casts[data.id] ~= nil then
    local current_ability_codes = state.casts[data.id].ability_codes
    if #data.ability_codes + #current_ability_codes  <= game_config.max_composite_ability_size then
      local ability_codes = util.table_copy(current_ability_codes)
      util.table_insert_all(ability_codes, data.ability_codes)
      local current_cast = util.table_copy(state.casts[data.id])
      current_cast.composite_ability = get_composite_ability(ability_codes)
      current_cast.ability_codes = ability_codes
      local target_id = state.targets[data.id]
      if can_cast(current_cast.composite_ability, data.id, target_id, state) then
        state.casts[data.id] = current_cast
      end
    end
  end
end

function match_handler.match_init(_, params)
    local gamestate = {
      is_arena = params.is_arena,
      is_world = params.is_world,
      users = {},
      inputs = {},
      positions = {},
      rotations = {},
      jumps = {},
      names = {},
      targets = {},
      healths = {},
      powers = {},
      effects = {},
      casts = {},
      speeds = {},
      projectiles = {},
      projectile_count = 0
    }
    local label = "world"
    if params.is_arena then
      label = "arena"
      gamestate.joined_count_team1 = 0
      gamestate.joined_count_team2 = 0
      gamestate.team_size = #params.matched_users / 2
    end
    return gamestate, TICK_RATE, label
end

function match_handler.match_join_attempt(_, _, _, state, user, _)
    if state.users[user.user_id] ~= nil then
        return state, false, "User already in match."
    end
    return state, true
end

function match_handler.match_join(_, dispatcher, _, state, joining_users)
    for _, user in ipairs(joining_users) do

        if state.is_arena then
          if state.joined_count_team1 < state.team_size then
            user.team = 1
            state.joined_count_team1 = state.joined_count_team1 + 1
          else
            user.team = 2
            state.joined_count_team2 = state.joined_count_team2 + 1
          end
        end

        state.users[user.user_id] = user

        if state.is_world then
          state.positions[user.user_id] = WORLD_SPAWN_POSITION
          state.rotations[user.user_id] = WORLD_SPAWN_ROTATION
        elseif state.is_arena and user.team == 1 then
          state.positions[user.user_id] = TEAM1_SPAWN_POSITION
          state.rotations[user.user_id] = TEAM1_SPAWN_ROTATION
        elseif state.is_arena then
          state.positions[user.user_id] = TEAM2_SPAWN_POSITION
          state.rotations[user.user_id] = TEAM2_SPAWN_ROTATION
        end

        state.inputs[user.user_id] = {
            dir= {
              x = 0,
              y = 0,
              z = 0
            },
            jmp = 0
        }

        state.names[user.user_id] = user.username

        state.healths[user.user_id] = game_config.max_health
        state.powers[user.user_id] = game_config.max_power
        state.effects[user.user_id] = {}

        state.casts[user.user_id] = nil

        state.speeds[user.user_id] = game_config.default_speed
    end


    local data = {
        pos = state.positions,
        rot = state.rotations,
        inp = state.inputs,
        nms = state.names,
        trg = state.targets,
        hlt = state.healths,
        pwr = state.powers,
        eff = state.effects,
        cst = state.casts,
        spd = state.speeds,
        prj = state.projectiles,
    }

    local encoded = nk.json_encode(data)
    dispatcher.broadcast_message(OpCodes.initial_state, encoded, joining_users)

    return state
end

function match_handler.match_leave(_, _, _, state, leaving_users)
    for _, user in ipairs(leaving_users) do
        local id = user.user_id
        state.users[id] = nil
        state.positions[id] = nil
        state.rotations[id] = nil
        state.inputs[id] = nil
        state.jumps[id] = nil
        state.names[id] = nil
        state.targets[id] = nil
        state.healths[id] = nil
        state.powers[id] = nil
        state.effects[id] = nil
        state.casts[id] = nil
        state.speeds[id] = nil

        -- remove this user as a target of others
        for k, v in pairs(state.targets) do
          if v == id then
            state.targets[k] = nil
          end
        end
    end
    return state
end

local apply_effect_removals = function(current_effects, new_effect_code)
  local config = game_config.effect_config[new_effect_code]
  for _, code_to_remove in ipairs(config.effects_removed) do
    for current_code, current_effect in pairs(current_effects) do
      if current_code == code_to_remove then
        current_effect.stack_count = current_effect.stack_count - 1
        if current_effect.stack_count >= 1 then
          current_effects[current_code] = current_effect
        else
          current_effects[current_code] = nil
        end
      end
    end
  end

  return current_effects
end

local add_new_effects = function(current, new_codes)
  local result_effects = util.table_copy(current)
  for code, result_effect in pairs(result_effects) do
    for _, new_code in ipairs(new_codes) do
      local config = game_config.effect_config[new_code]
      if code == new_code and result_effect.stack_count < config.max_stacks then
        result_effect.stack_count = result_effect.stack_count + 1
        result_effect.remaining_seconds = config.duration_seconds
        result_effects = apply_effect_removals(result_effects, new_code)
      end
    end
    result_effects[code] = result_effect
  end

  for _, new_code in ipairs(new_codes) do
    if current[new_code] == nil then
      local result_effect = result_effects[new_code]
      local config = game_config.effect_config[new_code]
      if result_effect == nil then
        result_effect = {}
        result_effect.stack_count = 1
        result_effect.remaining_seconds = config.duration_seconds
      else
        result_effect.stack_count = result_effect.stack_count + 1
      end
      result_effects[new_code] = result_effect
      result_effects = apply_effect_removals(result_effects, new_code)
    end
  end

  return result_effects
end

function match_handler.match_loop(_, dispatcher, tick, state, messages)

    -- RESET JUMPS BEFORE NEXT STATE
    for _, input in pairs(state.inputs) do
        input.jmp = 0
    end

    for _, message in ipairs(messages) do
        local op_code = message.op_code

        local decoded = nk.json_decode(message.data)

        local command = commands[op_code]
        if command ~= nil then
            commands[op_code](decoded, state)
        end
    end

    local delta_seconds = 1.0 / TICK_RATE

    local hits_to_process = {}

    -- CAST PROCESSING

    for id, cast in pairs(state.casts) do
      local input = state.inputs[id]
      if input ~= nil and ((input.jmp == 1 or not util.is_zero_vector(input.dir)) and not cast.composite_ability.cast_while_moving) then
        state.casts[id] = nil
      elseif cast.elapsed_time_seconds >= cast.composite_ability.cast_duration_seconds then
        if can_cast(cast.composite_ability, id, cast.target_id, state) then
          state.powers[id] = state.powers[id] - cast.composite_ability.power_cost
          if cast.composite_ability.is_projectile then
            state.projectiles[tostring(state.projectile_count)] = {
              from_id = id,
              to_id = cast.target_id,
              position = util.vector_add(state.positions[id], game_config.character_line_of_sight_point),
              composite_ability = cast.composite_ability
            }
            state.projectile_count = state.projectile_count + 1
          else
            table.insert(hits_to_process, { from_id = id, target_id = cast.target_id, composite_ability = cast.composite_ability })
          end
        end
        state.casts[id] = nil
      else
        cast.elapsed_time_seconds = cast.elapsed_time_seconds + delta_seconds
        state.casts[id] = cast
      end
    end

    -- EFFECTS PROCESSING

    for id, user_effects in pairs(state.effects) do
      local next_speed = state.speeds[id]
      for code, effect in pairs(user_effects) do
        local config = game_config.effect_config[code]
        local speed_delta = (game_config.default_speed * (config.speed_inc_percent * effect.stack_count))
        if effect.start_tick ~= nil then
          if math.fmod(tick - effect.start_tick, TICK_RATE) == 0 then
            -- tasks done in discrete 1 sec intervals
            state.healths[id] = state.healths[id] + (config.health_per_second * effect.stack_count)
            if effect.remaining_seconds - 1 > 0 then
              effect.remaining_seconds = effect.remaining_seconds - 1
            else
              user_effects[code] = nil
              next_speed = next_speed - speed_delta
            end
          end
        elseif effect.start_tick == nil then
          effect.start_tick = tick
          next_speed = next_speed + speed_delta
        end
      end
      state.speeds[id] = next_speed
      state.effects[id] = user_effects
    end

    -- PROJECTILE PROCESSING

    for id, proj in pairs(state.projectiles) do
      local to_pos = state.positions[proj.to_id]
      if to_pos ~= nil then
        to_pos = util.vector_add(to_pos, game_config.character_line_of_sight_point)
        if util.get_vector_distance(to_pos, proj.position) < 1 then
          table.insert(hits_to_process, { from_id = proj.from_id, target_id = proj.to_id, composite_ability = proj.composite_ability })
          state.projectiles[id] = nil
        else
          local diff = util.vector_subtract(to_pos, proj.position)
          proj.position = util.vector_add(proj.position, util.vector_scale(util.vector_normalize(diff), delta_seconds * proj.composite_ability.meters_per_second))
          state.projectiles[id] = proj
        end
      else
        state.projectiles[id] = nil
      end
    end

    -- HITS PROCESSING

    for _, hit in ipairs(hits_to_process) do
      local total_directed_move = { x = 0, y = 0, z = 0 }
      state.healths[hit.target_id] = state.healths[hit.target_id] + hit.composite_ability.on_hit.health_delta
      state.effects[hit.target_id] = add_new_effects(state.effects[hit.target_id], hit.composite_ability.on_hit.effects)
      total_directed_move = util.vector_add(total_directed_move, hit.composite_ability.on_hit.directed_move)
      local special_hit_key = "on_hit_friendly"
      if hit.target_id ~= hit.from_id then
        local to_team = state.users[hit.target_id].team
        local from_team = state.users[hit.from_id].team
        if to_team ~= from_team or to_team == nil then
          special_hit_key = "on_hit_enemy"
        end
      end
      state.healths[hit.target_id] = state.healths[hit.target_id] + hit.composite_ability[special_hit_key].health_delta
      state.effects[hit.target_id] = add_new_effects(state.effects[hit.target_id], hit.composite_ability[special_hit_key].effects)
      total_directed_move = util.vector_add(total_directed_move, hit.composite_ability[special_hit_key].directed_move)

      if not util.is_zero_vector(total_directed_move) then
        local pos_delta = util.vector_scale(state.rotations[hit.target_id], total_directed_move.z)
        local start_pos = util.vector_add(state.positions[hit.target_id], game_config.character_line_of_sight_point)
        local furthest_end_pos = util.vector_add(start_pos, pos_delta)
        local intersection = util.get_closest_line_intersection(start_pos, furthest_end_pos, arena_vertices)
        local end_offset = util.vector_add(util.vector_scale(state.rotations[hit.target_id], (game_config.character_dimensions.z / 2)), game_config.character_line_of_sight_point)
        local end_pos = util.vector_subtract(intersection.point, end_offset)
        end_pos.override = true
        state.positions[hit.target_id] = end_pos
        util.table_log({ pos_delta = pos_delta, start_pos = start_pos, furthest_end_pos = furthest_end_pos, intersection = intersection, end_offset = end_offset, end_pos = end_pos })
      end

    end

    -- PASSIVES

    if math.fmod(tick, TICK_RATE) == 0 then
      for id, _ in pairs(state.users) do
        state.healths[id] = math.min(game_config.max_health, state.healths[id] + game_config.passive_health_per_second)
        state.powers[id] = math.min(game_config.max_power, state.powers[id] + game_config.passive_power_per_second)
      end
    end

    local update = {
        pos = state.positions,
        rot = state.rotations,
        inp = state.inputs,
        trg = state.targets,
        hlt = state.healths,
        pwr = state.powers,
        eff = state.effects,
        cst = state.casts,
        spd = state.speeds,
        prj = state.projectiles,
    }

    local encoded_update = nk.json_encode(update)

    dispatcher.broadcast_message(OpCodes.update_state, encoded_update)

    return state
end

function match_handler.match_terminate(_, _, _, state, _)
    return state
end

return match_handler
