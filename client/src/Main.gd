extends Node

export var WorldScene : PackedScene

func _ready() -> void:
	ServerConnection.connect("login_succeeded", self, "_on_login_succeeded")
	
func _on_login_succeeded() -> void:
	$Login.hide()
	MatchController.connect("connection_established", self, "_on_ready_to_join_world")
	MatchController.connect("connection_failed", self, "_on_connection_failed")

func _on_ready_to_join_world() -> void:
	MatchController.disconnect("connection_established", self, "_on_ready_to_join")
	var get_world_id_result: NakamaAPI.ApiRpc = yield(
		ServerConnection.call_rpc_async("get_world_id"), "completed"
	)

	if get_world_id_result.is_exception():
		print("An error occured: %s" % get_world_id_result)
		return
		
	var game_config: NakamaAPI.ApiRpc = yield(
		ServerConnection.get_game_config_async(), "completed"
	)
	
	if game_config == null:
		return
	
	MatchController.connect("join_match_succeeded", self, "_on_world_joined")
	MatchController.connect("join_match_failed", self, "_on_world_join_failed")
	MatchController.join_match(get_world_id_result.payload)

func _on_connection_failed() -> void:
	pass

func _on_world_joined() -> void:
	MatchController.disconnect("join_match_succeeded", self, "_on_world_joined")
	add_child(WorldScene.instance())

func _on_world_join_failed() -> void:
	MatchController.disconnect("join_match_failed", self, "_on_world_join_failed")
	pass
