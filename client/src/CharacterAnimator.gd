extends Node

onready var _animation_tree : AnimationTree = $AnimationTree
onready var _mesh_root : Spatial = get_parent().get_node("Armature")

var _iwr_blend = Vector2.ZERO
var _target_iwr_blend = Vector2.ZERO
var blend_speed : float = 10

func animate_movement(direction : Vector3):
	_target_iwr_blend = Vector2(direction.x, -direction.z)

func _process(delta):
	_iwr_blend = _iwr_blend.linear_interpolate(_target_iwr_blend, blend_speed * delta)
	_animation_tree.set("parameters/iwr/blend_position", _iwr_blend)
	var mesh_rot = rad2deg(Vector2.DOWN.angle_to(_iwr_blend)) - 180
	if round(mesh_rot) < -270 or round(mesh_rot) > -90:
		mesh_rot += 180
	# warning-ignore:return_value_discarded
	_mesh_root.rotation_degrees.y = mesh_rot

func jump():
	_animation_tree.set("parameters/jump/active", true)
