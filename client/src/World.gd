extends Spatial

signal world_load_started
signal world_load_complete
signal world_load_failed

func _ready() -> void: 
	emit_signal("world_load_started")
	MatchController.connect("connection_established", self, "_on_ready_to_join")
	MatchController.connect("connection_failed", self, "_on_connection_failed")
	MatchController.connect("join_match_succeeded", self, "_on_join")
	MatchController.connect("join_match_failed", self, "_on_join_failed")

func _on_ready_to_join() -> void:
	MatchController.disconnect("connection_established", self, "_on_ready_to_join")
	var result: NakamaAPI.ApiRpc = yield(
		ServerConnection.call_rpc_async("get_world_id"), "completed"
	)

	if result.is_exception():
		emit_signal("world_load_failed")
		print("An error occured: %s" % result)
		return
		
	MatchController.join_match(result.payload)

func _on_join() -> void:
	emit_signal("world_load_complete")

func _on_join_failed() -> void:
	emit_signal("world_load_failed")

func _on_connection_failed() -> void:
	emit_signal("world_load_failed")

