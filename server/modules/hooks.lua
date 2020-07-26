local nk = require("nakama")

local function on_matchmaker_matched(context, matched_users)
  return nk.match_create("match_handler", { matched_users = matched_users, is_arena = true })
end

nk.register_matchmaker_matched(on_matchmaker_matched)
