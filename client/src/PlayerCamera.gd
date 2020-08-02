extends Spatial

const VERTICAL_DEGREE_BOUND = 90

var h_rot = 0
var v_rot = 0

var v_min = -55
var v_max = 75
var v_sens = 0.8
var h_sens = 0.8
var v_accel = 20
var h_accel = 20

onready var _h : Spatial = $H
onready var _v : Spatial = $H/V
onready var _cam : Camera = $H/V/ClippedCamera
onready var _parent : Spatial = get_parent()
onready var _prev_parent_y : float = _parent.rotation_degrees.y

var _left_pressed = false
var _right_pressed = false

func dont_collide_with(node: Object) -> void:
	_cam.add_exception(node)
	
func get_direction() -> Vector3:
	return _cam.global_transform.origin.direction_to(self.global_transform.origin)

func get_rotation_degrees() -> Vector3:
	return Vector3(_v.rotation_degrees.x, _h.rotation_degrees.y, _h.rotation_degrees.z)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			_right_pressed = event.pressed
		if event.button_index == BUTTON_LEFT:
			_left_pressed = event.pressed
	elif event is InputEventMouseMotion and _left_pressed:
		h_rot -= event.relative.x * h_sens
		v_rot -= event.relative.y * v_sens

func _physics_process(delta):
	
	var current_parent_y = _parent.rotation_degrees.y
	
	if _right_pressed:
		rotation_degrees.y -= current_parent_y - _prev_parent_y
	
	
	v_rot = clamp(v_rot, v_min, v_max)
	
	_h.rotation_degrees.y = lerp(_h.rotation_degrees.y, h_rot, delta * h_accel)
	_v.rotation_degrees.x = lerp(_v.rotation_degrees.x, v_rot, delta * v_accel)
	
	_prev_parent_y = current_parent_y
		
