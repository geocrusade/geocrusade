extends KinematicBody

onready var animator = $CharacterAnimator

var speed : float = 5
var jump_speed : float = 8
var gravity = -1

var _vel : Vector3 = Vector3.ZERO

func update_input(dir : Vector3, jump : bool, delta : float) -> void:
	if _is_grounded():
		_vel = dir * speed * delta
		_vel.y += int(jump) * jump_speed * delta

	_vel.y += gravity * delta
	_vel.y = max(_vel.y, gravity)
	.move_and_collide(_vel)
	
func _is_grounded() -> bool:
	var hit = get_world().direct_space_state.intersect_ray(global_transform.origin, global_transform.origin - Vector3(0,0.1,0), [self])
	return not hit.empty()
