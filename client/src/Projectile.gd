extends Spatial

var _velocity = Vector3.ZERO
var _last_update = Vector3.ZERO
var _delta_since_update = 0

func _physics_process(delta):
	global_transform.origin += _velocity
	_delta_since_update += delta

func update_position(pos : Vector3) -> void:
	_velocity = (pos - _last_update) * _delta_since_update
	global_transform.origin = pos
	_last_update = pos
	_delta_since_update = 0
