extends Node

signal login_failed
signal login_succeeded
signal login_started

const SERVER_KEY := "geocrusade_server_key"
const SERVER_IP := "127.0.0.1"
const SERVER_PORT := 7350

var _client : NakamaClient
var _session : NakamaSession

func login(name: String) -> void:
	var device_id = OS.get_unique_id() + name
	emit_signal("login_started")
	_session = yield(_client.authenticate_device_async(device_id, name, true), "completed")
	if _session.is_exception():
		emit_signal("login_failed")
		print("An error occured: %s" % _session)
		return
	emit_signal("login_succeeded")

func call_rpc_async(name : String, payload : String = "") -> NakamaAPI.ApiRpc:
	return _client.rpc_async(_session, name, payload)

func create_socket() -> NakamaSocket:
	return Nakama.create_socket_from(_client)

func get_session() -> NakamaSession:
	return _session

func get_username() -> String:
	return _session.username
	
func get_user_id() -> String:
	return _session.user_id

func _ready() -> void:
	_client = Nakama.create_client(SERVER_KEY, SERVER_IP, SERVER_PORT, "http")
