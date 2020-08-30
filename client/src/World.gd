extends Spatial

signal world_joined
signal world_join_failed

var _socket : NakamaSocket
var _world_id : String


func join(socket : NakamaSocket, world_id : String) -> void:
	_socket = socket
	_world_id = world_id
	var result: NakamaRTAPI.Match = yield(
		socket.join_match_async(world_id), "completed"
	)
	
	if result.is_exception():
		emit_signal("world_join_failed")
		print("Failed to join world: %s" % result)
		return
	
	print("world joined")
	emit_signal("world_joined")
