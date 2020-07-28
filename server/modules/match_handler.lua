
local nk = require("nakama")

local match_handler = {}

local WORLD_SPAWN_POSITION = { ["x"] = 0, ["y"] = 0, ["z"] = 0 }
local TEAM1_SPAWN_POSITION = { ["x"] = 150, ["y"] = 6, ["z"] = -45 }
local TEAM2_SPAWN_POSITION = { ["x"] = 150, ["y"] = 6, ["z"] = 45 }

local OpCodes = {
    initial_state = 1,
    update_state = 2,
    update_transform = 3,
    update_input = 4,
    update_jump = 5,
    update_target = 6
}

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
    }
    local tickrate = 20
    local label = "world"
    if params.is_arena then
      label = "arena"
      gamestate.joined_count_team1 = 0
      gamestate.joined_count_team2 = 0
      gamestate.team_size = #params.matched_users / 2
    end
    return gamestate, tickrate, label
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
            ["dir"] = {
              ["x"] = 0,
              ["y"] = 0,
              ["z"] = 0
            },
            ["jmp"] = 0
        }

        state.names[user.user_id] = user.username

        state.healths[user.user_id] = 100
        state.powers[user.user_id] = 100
    end


    local data = {
        ["pos"] = state.positions,
        ["trn"] = state.turn_angles,
        ["inp"] = state.inputs,
        ["nms"] = state.names,
        ["trg"] = state.targets,
        ["hlt"] = state.healths,
        ["pwr"] = state.powers
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

    local data = {
        ["pos"] = state.positions,
        ["trn"] = state.turn_angles,
        ["inp"] = state.inputs,
        ["trg"] = state.targets,
        ["hlt"] = state.healths,
        ["pwr"] = state.powers
    }
    local encoded = nk.json_encode(data)

    dispatcher.broadcast_message(OpCodes.update_state, encoded)

    for _, input in pairs(state.inputs) do
        input.jmp = 0
    end

    return state
end

function match_handler.match_terminate(_, _, _, state, _)
    return state
end

return match_handler
