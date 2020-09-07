extends Node

onready var _animation_tree : AnimationTree = $AnimationTree
onready var _mesh_root : Spatial = get_parent().get_node("Armature")

var _iwr_blend = Vector2.ZERO
var _target_iwr_blend = Vector2.ZERO
var _target_rot_y = 180
var blend_rate : float = 0.2

func _process(delta):
	_iwr_blend = _iwr_blend.linear_interpolate(_target_iwr_blend, blend_rate)
	_animation_tree.set("parameters/iwr/blend_position", _iwr_blend)

func _physics_process(delta):
	_mesh_root.rotation_degrees.y = lerp(_mesh_root.rotation_degrees.y, _target_rot_y, blend_rate)

func animate_movement(direction : Vector3):
	_target_iwr_blend = Vector2(round(direction.x), round(-direction.z))
	var default_deg = 180
	match _target_iwr_blend:
		Vector2.DOWN:
			_target_rot_y = default_deg
		Vector2.LEFT:
			_target_rot_y = default_deg + 90
		(Vector2.DOWN + Vector2.LEFT):
			_target_rot_y = default_deg + 45
		(Vector2.UP + Vector2.LEFT):
			_target_rot_y = default_deg - 45
		Vector2.UP:
			_target_rot_y = default_deg 
		(Vector2.UP + Vector2.RIGHT):
			_target_rot_y = default_deg + 45
		Vector2.RIGHT:
			_target_rot_y = default_deg - 90
		(Vector2.DOWN + Vector2.RIGHT):
			_target_rot_y = default_deg - 45
		Vector2.ZERO:
			_target_rot_y = default_deg

func jump():
	_animation_tree.set("parameters/jump/active", true)
