extends Node

signal connection_failed
signal connection_established
signal connection_initiated
signal connection_closed

signal join_match_started
signal join_match_failed
signal join_match_succeeded

signal arena_match_search_started
signal arena_match_search_failed
signal arena_match_search_canceled
signal arena_match_found(seconds_until_expire)
signal arena_match_joined
signal arena_match_join_failed


signal users_changed
signal state_updated(positions, turn_angles, inputs, targets, healths, powers, casts)
signal initial_state_received(positions, turn_angles, inputs, names, targets, healths, powers, casts)
signal character_spawned(id)


enum OpCodes {
	INITIAL_STATE = 1,
	UPDATE_STATE,
	UPDATE_TRANSFORM,
	UPDATE_INPUT,
	UPDATE_JUMP,
	UPDATE_TARGET,
	START_CAST,
	CANCEL_CAST
}

var users = {}

var _socket : NakamaSocket

var _match_id : String
var _matchmaker_ticket : NakamaRTAPI.MatchmakerTicket 
var _matchmaker_matched : NakamaRTAPI.MatchmakerMatched

func join_match(match_id: String) -> void:
	emit_signal("join_match_started")
	if not match_id:
		emit_signal("join_match_failed")
		print("Invalid match id")
		return
	
	var prev_match_id = _match_id
	_match_id = match_id
	var match_join_result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(match_id), "completed"
	)
	
	if match_join_result.is_exception():
		_match_id = prev_match_id
		emit_signal("join_match_failed")
		print("An error occured: %s" % match_join_result)
		return

	
	for user in match_join_result.presences:
			users[user.user_id] = user
	
	emit_signal("users_changed")
	emit_signal("join_match_succeeded")


func search_for_arena_match(team_size : int) -> void:
	var query = "*"
	var min_count = team_size * 2
	var max_count = team_size * 2
	var string_properties = {}
	var numeric_properties = {}
	_matchmaker_ticket = yield(
		_socket.add_matchmaker_async(query, min_count, max_count, string_properties, numeric_properties),
		"completed"
	)
	if _matchmaker_ticket.is_exception():
		emit_signal("arena_match_search_failed")
		print("An error occured: %s" % _matchmaker_ticket)
		return
	emit_signal("arena_match_search_started")

func cancel_search_for_arena_match() -> void:
	var result : NakamaAsyncResult = yield(_socket.remove_matchmaker_async(_matchmaker_ticket.ticket), "completed")
	if result.is_exception():
		print("An error occured: %s" % result)
		return
	emit_signal("arena_match_search_canceled")

func join_arena_match() -> void:
	var leave_result : NakamaAsyncResult = yield(_socket.leave_match_async(_match_id), "completed")
	if leave_result.is_exception():
		emit_signal("arena_match_join_failed")
		print("An error occured: %s" % leave_result)
		return

	var prev_match_id = _match_id
	_match_id = _matchmaker_matched.match_id

	var joined_match : NakamaRTAPI.Match = yield(_socket.join_matched_async(_matchmaker_matched), "completed")
	if joined_match.is_exception():
		_match_id = prev_match_id
		emit_signal("arena_match_join_failed")
		print("An error occured: %s" % joined_match)
		return
	
	for user in joined_match.presences:
		users[user.user_id] = user
		
	emit_signal("users_changed")
	emit_signal("arena_match_joined")

func send_transform_update(position: Vector3, turn_angle: float) -> void:
	var payload := {id = ServerConnection.get_user_id(), pos = {x = position.x, y = position.y, z = position.z }, trn = turn_angle}
	_socket.send_match_state_async(_match_id, OpCodes.UPDATE_TRANSFORM, JSON.print(payload))
		
func send_input_update(input: Vector3) -> void:
	var payload := {id = ServerConnection.get_user_id(), inp = {x = input.x, y = input.y, z = input.z }}
	_socket.send_match_state_async(_match_id, OpCodes.UPDATE_INPUT, JSON.print(payload))

func send_jump() -> void:
	var payload := {id = ServerConnection.get_user_id() }
	_socket.send_match_state_async(_match_id, OpCodes.UPDATE_JUMP, JSON.print(payload))

func send_target(target_id: String) -> void:
	var payload := {id = ServerConnection.get_user_id(), target_id = target_id }
	_socket.send_match_state_async(_match_id, OpCodes.UPDATE_TARGET, JSON.print(payload))

func send_start_cast(ability_codes : Array) -> void:
	var payload := { id = ServerConnection.get_user_id(), ability_codes = ability_codes }
	_socket.send_match_state_async(_match_id, OpCodes.START_CAST, JSON.print(payload))

func send_cancel_Cast() -> void:
	var payload := { id = ServerConnection.get_user_id() }
	_socket.send_match_state_async(_match_id, OpCodes.CANCEL_CAST, JSON.print(payload))

func _ready() -> void:
	ServerConnection.connect("login_succeeded", self, "_connect_socket")

func _connect_socket() -> void:
	emit_signal("connection_initiated")
	_socket = ServerConnection.create_socket()
	
	var result: NakamaAsyncResult = yield(
		_socket.connect_async(ServerConnection.get_session()), "completed"
	)
	
	if result.is_exception():
		emit_signal("connection_failed")
		print("An error occured: %s" % result)
		return
		
	emit_signal("connection_established")
	#warning-ignore: return_value_discarded
	_socket.connect("closed", self, "_on_socket_closed")
	#warning-ignore: return_value_discarded
	_socket.connect("received_error", self, "_on_socket_received_error")
	#warning-ignore: return_value_discarded
	_socket.connect("received_match_presence", self, "_on_socket_received_match_presence")
	#warning-ignore: return_value_discarded
	_socket.connect("received_match_state", self, "_on_socket_received_match_state")
	#warning-ignore: return_value_discarded
	_socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")


func _on_socket_closed() -> void:
	_socket = null
	emit_signal("connection_closed")
	
func _on_socket_received_error(error: String) -> void:
	print(error)
	_socket = null
	emit_signal("connection_closed")
	
func _on_socket_received_match_presence(event: NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in event.leaves:
		#warning-ignore: return_value_discarded
		users.erase(leave.user_id)

	for join in event.joins:
		if not join.user_id == ServerConnection.get_user_id():
			users[join.user_id] = join

	emit_signal("users_changed")

func _on_socket_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var raw := match_state.data
	
	match code:
		OpCodes.UPDATE_STATE:
			var decoded: Dictionary = JSON.parse(raw).result

			var positions: Dictionary = decoded.pos
			var turn_angles: Dictionary = decoded.trn
			var inputs: Dictionary = decoded.inp
			var targets: Dictionary = decoded.trg
			var healths: Dictionary = decoded.hlt
			var powers: Dictionary = decoded.pwr
			var casts: Dictionary = decoded.cst

			emit_signal("state_updated", positions, turn_angles, inputs, targets, healths, powers, casts)
			
		OpCodes.INITIAL_STATE:
			var decoded: Dictionary = JSON.parse(raw).result

			var positions: Dictionary = decoded.pos
			var turn_angles: Dictionary = decoded.trn
			var inputs: Dictionary = decoded.inp
			var names: Dictionary = decoded.nms
			var targets: Dictionary = decoded.trg
			var healths: Dictionary = decoded.hlt
			var powers: Dictionary = decoded.pwr
			var casts: Dictionary = decoded.cst
			
			emit_signal("initial_state_received", positions, turn_angles, inputs, names, targets, healths, powers, casts)

func _on_matchmaker_matched(matched : NakamaRTAPI.MatchmakerMatched):
	_matchmaker_matched = matched
	emit_signal("arena_match_found", 60)
