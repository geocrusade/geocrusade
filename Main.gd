extends Node

signal connection_succeeded()
signal connection_failed()
signal game_error()
signal player_list_changed()

const DEFAULT_PORT = 10567

const MAX_PEERS = 30

const SERVER_ID = 1

var player_dict = {}

var is_player_hosting = false

remote func add_players(player_list):
	if _called_by_server():
		_add_players(player_list)
		
remote func remove_players(id_list):
	if _called_by_server():
		_remove_players(id_list)	
		
master func request_join_world(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	var new_players = [{id = id, name = new_player_name, position = Vector3(0, 0, 20) }]
	_add_players(new_players)
	rpc("add_players",  new_players)

func host_world_as_player():
	var new_player_name = get_node("LaunchUI/HostNameField").text
	is_player_hosting = true
	_host_world()
	_add_players([{id = SERVER_ID, name = new_player_name, position = Vector3(0, 0, 20) }])

func host_world_as_dedicated_server():
	is_player_hosting = false
	_host_world()

func join_world():
	var host_ip = get_node("LaunchUI/IPAddressField").text
	var client = NetworkedMultiplayerENet.new()
	client.create_client(host_ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)
	get_node("LaunchUI").hide()

func _host_world():
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	get_node("LaunchUI").hide()

func _add_players(player_list):
	var player_scene = load("res://Player.tscn");
	var players_node = get_node("Players")
	for p in player_list:
		player_dict[p.id] = p
		var instance = player_scene.instance()
		players_node.add_child(instance)
		instance.set_name(str(p.id))
		instance.set_player_name(p.name)
		instance.set_network_master(p.id)
		instance.global_transform.origin = p.position
	
	emit_signal("player_list_changed")

func _remove_players(id_list):
	var player_nodes = get_node("Players")
	for id in id_list:
		var node_name = str(id)
		if player_nodes.has_node(node_name):
			var player = player_nodes.get_node(node_name)
			#@TODO use call_deferred here?
			player_nodes.remove_child(player)
			player_dict.erase(id)
			player.free()
		
	emit_signal("player_list_changed")

# Server only callback
func _player_connected(id):
	rpc_id(id, "add_players", player_dict.values());
	
# Server only callback
func _player_disconnected(id):
	_remove_players([id])
	rpc("remove_players", [id])
	
# Client only callback
func _connected_to_server():
	var new_player_name = get_node("LaunchUI/NameField").text
	rpc("request_join_world", new_player_name)
	emit_signal("connection_succeeded")

# Client only callback
func _connection_failed():
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")
	
# Client only callback
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")

func _called_by_server():
	return get_tree().get_rpc_sender_id() == SERVER_ID

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	get_node("LaunchUI/HostButton").connect("button_up", self, "host_world_as_player")
	get_node("LaunchUI/JoinButton").connect("button_up", self, "join_world")
	
	
	

