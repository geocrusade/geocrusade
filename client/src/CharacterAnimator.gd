extends Node

onready var _animation_tree : AnimationTree = $AnimationTree
onready var _mesh_root : Spatial = get_parent().get_node("Armature")

var _iwr_blend = Vector2.ZERO
var _target_iwr_blend = Vector2.ZERO
var blend_rate : float = 0.2

func animate_movement(direction : Vector3):
	_target_iwr_blend = Vector2(round(direction.x), round(-direction.z))
	_animation_tree.set("parameters/iwr/blend_position", _target_iwr_blend)
	var default_deg = 180
	
	match _target_iwr_blend:
		Vector2.DOWN:
			_mesh_root.rotation_degrees.y = default_deg
		Vector2.LEFT:
			_mesh_root.rotation_degrees.y = default_deg + 90
		(Vector2.DOWN + Vector2.LEFT):
			_mesh_root.rotation_degrees.y = default_deg + 45
		(Vector2.UP + Vector2.LEFT):
			_mesh_root.rotation_degrees.y = default_deg - 45
		Vector2.UP:
			_mesh_root.rotation_degrees.y = default_deg 
		(Vector2.UP + Vector2.RIGHT):
			_mesh_root.rotation_degrees.y = default_deg + 45
		Vector2.RIGHT:
			_mesh_root.rotation_degrees.y = default_deg - 90
		(Vector2.DOWN + Vector2.RIGHT):
			_mesh_root.rotation_degrees.y = default_deg - 45

func jump():
	_animation_tree.set("parameters/jump/active", true)
