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

local game_config = require("game_config")

local function get_game_config(_, _)
  return nk.json_encode(game_config)
end

nk.register_rpc(get_world_id, "get_world_id")
