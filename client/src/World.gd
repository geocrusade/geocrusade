extends Spatial

signal world_joined
signal world_join_failed

onready var _character_state = $CharacterState

var _socket : NakamaSocket
var _world_id : String

var _client_player_character_id : String

enum OpCodes {
	STATE_INIT,
	STATE_UPDATE
	ON_JOIN_CONFIG
}

func join(socket : NakamaSocket, world_id : String) -> void:
	_socket = socket
	_world_id = world_id
	_connect_to_socket_signals()
	var result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(_world_id), "completed"
	)
	
	if result.is_exception():
		emit_signal("world_join_failed")
		print("Failed to join world: %s" % result)
		return
	
	emit_signal("world_joined")

func _connect_to_socket_signals() -> void:
	_socket.connect("received_match_state", self, "_on_match_state_received")

func _on_match_state_received(payload: NakamaRTAPI.MatchData) -> void:
	var code := payload.op_code
	var state : Dictionary = JSON.parse(payload.data).result
	
	match code:
		OpCodes.STATE_INIT:
			_character_state.set_characters(state.Characters)
		OpCodes.STATE_UPDATE:
			_character_state.set_characters(state.Characters)
		OpCodes.ON_JOIN_CONFIG:
			_character_state.client_player_character_id = state.CharacterId
