
local nk = require("nakama")
local game_config = require("game_config")
local util = require("utility")
local arena_vertices = require("arena_vertices")

local match_handler = {}

local WORLD_SPAWN_POSITION = { x = 0, y = 0, z = 0 }
local TEAM1_SPAWN_POSITION = { x = 150, y = 6, z = -45 }
local TEAM2_SPAWN_POSITION = { x = 150, y = 6, z = 45 }
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
}

local in_line_of_sight = function(pos_a, pos_b)
  pos_a = util.vector_add(pos_a, game_config.character_line_of_sight_point)
  pos_b = util.vector_add(pos_b, game_config.character_line_of_sight_point)
  return not util.line_intersects_faces(pos_a, pos_b, arena_vertices)
end

local commands = {}

commands[OpCodes.update_transform] = function(data, state)
    local id = data.id
    local position = data.pos
    if state.positions[id] ~= nil then
        state.positions[id] = position
    end
    if state.turn_angles[id] ~= nil then
        state.turn_angles[id] = data.trn
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

commands[OpCodes.start_cast] = function(data, state)
    if state.users[data.id] ~= nil and state.targets[data.id] ~= nil then
      local ability_config = game_config.ability_config[data.ability_codes[1]]
      local primary_ability = ability_config.primary
      local composite_ability = util.table_copy(primary_ability)
      composite_ability.name = ability_config.name
      for i=2, table.getn(data.ability_codes) do
        ability_config = game_config.ability_config[data.ability_codes[i]]
        local secondary_ability = ability_config.secondary
        composite_ability.name = string.format("%s,%s", composite_ability.name, ability_config.name)
        composite_ability.cast_duration_seconds = composite_ability.cast_duration_seconds + secondary_ability.cast_duration_seconds
        composite_ability.max_target_distance = composite_ability.max_target_distance + secondary_ability.max_target_distance
        composite_ability.power_cost = composite_ability.power_cost + secondary_ability.power_cost
        composite_ability.meters_per_second = composite_ability.power_cost + secondary_ability.meters_per_second

        composite_ability.on_hit.health_delta = composite_ability.on_hit.health_delta + secondary_ability.on_hit.health_delta
        composite_ability.on_hit_enemy.health_delta = composite_ability.on_hit_enemy.health_delta + secondary_ability.on_hit_enemy.health_delta
        composite_ability.on_hit_friendly.health_delta = composite_ability.on_hit_friendly.health_delta + secondary_ability.on_hit_friendly.health_delta

        util.table_insert_all(composite_ability.on_hit.effects, secondary_ability.on_hit.effects)
        util.table_insert_all(composite_ability.on_hit_enemy.effects, secondary_ability.on_hit_enemy.effects)
        util.table_insert_all(composite_ability.on_hit_friendly.effects, secondary_ability.on_hit_friendly.effects)

      end
      if state.powers[data.id] >= composite_ability.power_cost then
        local target_id = state.targets[data.id]
        local pos = state.positions[data.id]
        local target_pos = state.positions[target_id]
        local distance_to_target = util.get_vector_distance(pos, target_pos)
        if distance_to_target <= composite_ability.max_target_distance and in_line_of_sight(pos, target_pos) then
          state.casts[data.id] = {
            composite_ability = composite_ability,
            target_id = target_id,
            elapsed_time_seconds = 0.0,
          }
        end
      end
    end
end

commands[OpCodes.cancel_cast] = function(data, state)
  if state.users[data.id] ~= nil and state.casts[data.id] ~= nil then
    state.casts[data.id] = nil
  end
end

function match_handler.match_init(_, params)
    local gamestate = {
      is_arena = params.is_arena,
      is_world = params.is_world,
      users = {},
      inputs = {},
      positions = {},
      turn_angles = {},
      jumps = {},
      names = {},
      targets = {},
      healths = {},
      powers = {},
      casts = {},
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
          state.turn_angles[user.user_id] = 0
        elseif state.is_arena and user.team == 1 then
          state.positions[user.user_id] = TEAM1_SPAWN_POSITION
          state.turn_angles[user.user_id] = 0
        elseif state.is_arena then
          state.positions[user.user_id] = TEAM2_SPAWN_POSITION
          state.turn_angles[user.user_id] = 180
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

        state.healths[user.user_id] = 100
        state.powers[user.user_id] = 100

        state.casts[user.user_id] = nil
    end


    local data = {
        pos = state.positions,
        trn = state.turn_angles,
        inp = state.inputs,
        nms = state.names,
        trg = state.targets,
        hlt = state.healths,
        pwr = state.powers,
        cst = state.casts,
        prj = state.projectiles
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
        state.turn_angles[id] = nil
        state.inputs[id] = nil
        state.jumps[id] = nil
        state.names[id] = nil
        state.targets[id] = nil
        state.healths[id] = nil
        state.powers[id] = nil
        state.casts[id] = nil

        -- remove this user as a target of others
        for k, v in pairs(state.targets) do
          if v == id then
            state.targets[k] = nil
          end
        end
    end
    return state
end

function match_handler.match_loop(_, dispatcher, _, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code

        local decoded = nk.json_decode(message.data)

        local command = commands[op_code]
        if command ~= nil then
            commands[op_code](decoded, state)
        end
    end

    local update = {
        pos = state.positions,
        trn = state.turn_angles,
        inp = state.inputs,
        trg = state.targets,
        hlt = state.healths,
        pwr = state.powers,
        cst = state.casts,
        prj = state.projectiles
    }

    local encoded_update = nk.json_encode(update)

    dispatcher.broadcast_message(OpCodes.update_state, encoded_update)


    local delta_seconds = 1.0 / TICK_RATE

    for id, cast in pairs(state.casts) do
      local input = state.inputs[id]
      if input ~= nil and (input.jmp == 1 or not util.is_zero_vector(input.dir)) then
        state.casts[id] = nil
      elseif cast.elapsed_time_seconds >= cast.composite_ability.cast_duration_seconds then
        if in_line_of_sight(state.positions[id], state.positions[cast.target_id]) then
          state.powers[id] = state.powers[id] - cast.composite_ability.power_cost
          if cast.composite_ability.is_projectile then
            state.projectiles[tostring(state.projectile_count)] = {
              from_id = id,
              to_id = cast.target_id,
              position = util.vector_add(state.positions[id], game_config.character_line_of_sight_point),
              composite_ability = cast.composite_ability
            }
            state.projectile_count = state.projectile_count + 1
          end
        end
        state.casts[id] = nil
      else
        cast.elapsed_time_seconds = cast.elapsed_time_seconds + delta_seconds
        state.casts[id] = cast
      end
    end

    for id, proj in pairs(state.projectiles) do
      local to_pos = util.vector_add(state.positions[proj.to_id], game_config.character_line_of_sight_point)
      if to_pos ~= nil then
        if util.get_vector_distance(to_pos, proj.position) <= 1 then
          state.healths[proj.to_id] = state.healths[proj.to_id] + proj.composite_ability.on_hit.health_delta
          local to_team = state.users[proj.to_id].team
          local from_team = state.users[proj.from_id].team
          local special_hit_key = "on_hit_friendly"
          if to_team ~= from_team or to_team == nil then
            special_hit_key = "on_hit_enemy"
          end
          state.healths[proj.to_id] = state.healths[proj.to_id] + proj.composite_ability[special_hit_key].health_delta
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


    for _, input in pairs(state.inputs) do
        input.jmp = 0
    end

    return state
end

function match_handler.match_terminate(_, _, _, state, _)
    return state
end

return match_handler
