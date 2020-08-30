extends Node

const SERVER_KEY := "geocrusade_server_key"
const SERVER_IP := "127.0.0.1"
const SERVER_PORT := 7350

onready var _auth_screen = $AuthScreen
onready var _world = $World

onready var _client : NakamaClient = Nakama.create_client(SERVER_KEY, SERVER_IP, SERVER_PORT, "http")
onready var _socket : NakamaSocket = Nakama.create_socket_from(_client)
var _session : NakamaSession

func _ready():
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
	_join_world()
	
func _on_socket_closed():
	_auth_screen.show()

func _on_socket_error(err):
	_auth_screen.show()
	_auth_screen.reset()
	printerr("Socket error %s" % err)

func _join_world() -> void:
	var result: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_session, "get_world_id", ""), "completed"
	)
	if result.is_exception():
		print("Get world id failed: %s" % result)
		return
	
	_world.join(_socket, result.payload)
