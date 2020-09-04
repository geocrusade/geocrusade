extends Node

const SERVER_KEY := "geocrusade_server_key"
const SERVER_IP := "127.0.0.1"
const SERVER_PORT := 7350

enum OpCodes {
	STATE_INIT,
	STATE_UPDATE
	SET_JOIN_CONFIG
	INPUT_UPDATE
}

onready var _auth_screen = $AuthScreen
onready var _world = $World

onready var _client : NakamaClient = Nakama.create_client(SERVER_KEY, SERVER_IP, SERVER_PORT, "http")
onready var _socket : NakamaSocket = Nakama.create_socket_from(_client)
var _session : NakamaSession

func _ready():
	set_physics_process(false)
	_auth_screen.connect("auth_requested", self, "_authenticate")

func _authenticate(username : String) -> void:
	var device_id = OS.get_unique_id() + username
	_session = yield(_client.authenticate_device_async(device_id, username), "completed")
	if not _session.is_exception():
		_connect_socket()
	else:
		_auth_screen.reset()
		printerr("Session error %s" % _session)
		
func _connect_socket() -> void:
	# warning-ignore:return_value_discarded
	_socket.connect("connected", self, "_on_socket_connected")
	# warning-ignore:return_value_discarded
	_socket.connect("closed", self, "_on_socket_closed")
	# warning-ignore:return_value_discarded
	_socket.connect("received_error", self, "_on_socket_error")
	yield(_socket.connect_async(_session), "completed")

func _on_socket_connected():
	_auth_screen.reset()
	_auth_screen.hide()
	# warning-ignore:return_value_discarded
	_socket.connect("received_match_state", self, "_on_match_state_received")
	_join_world()
	
func _on_socket_closed():
	_auth_screen.show()

func _on_socket_error(err):
	_auth_screen.show()
	_auth_screen.reset()
	printerr("Socket error %s" % err)

func _join_world() -> void:
	if _world.id.length() == 0:
		var result: NakamaAPI.ApiRpc = yield(
			_client.rpc_async(_session, "get_world_id", ""), "completed"
		)
		if result.is_exception():
			print("Get world id failed: %s" % result)
			return
		_world.id = result.payload

		
	var result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(_world.id), "completed"
	)
	
	if result.is_exception():
		print("Failed to join world: %s" % result)
		return

func _on_match_state_received(payload) -> void:
	var code : int = payload.op_code
	var state : Dictionary = JSON.parse(payload.data).result
	match code:
		OpCodes.STATE_INIT:
			_world.characters_controller.set_characters(state.Characters)
			call_deferred("set_physics_process", true)
		OpCodes.STATE_UPDATE:
			_world.characters_controller.set_characters(state.Characters)
		OpCodes.SET_JOIN_CONFIG:
			_world.characters_controller.client_player_character_id = state.CharacterId

func _physics_process(_delta):
	var payload := { 
		Direction = {
			X = Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Y = 0, 
			Z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward") 
		}, 
		Jump = Input.is_action_just_pressed("jump"), 
		ClientTick = 0 
	}
	_socket.send_match_state_async(_world.id, OpCodes.INPUT_UPDATE, JSON.print(payload))
