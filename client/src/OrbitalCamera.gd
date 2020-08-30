extends Spatial

export var x_sens : float = 0.8
export var y_sens : float = 0.8

export var x_min = -55
export var x_max = 75
export var x_accel = 20
export var y_accel = 20
export var min_zoom = 1
export var max_zoom = 15
export var zoom_step = 1

onready var _cam = $PivotY/PivotX/ClippedCamera
onready var _pivot_y : Spatial = $PivotY
onready var _pivot_x : Spatial = $PivotY/PivotX

func _ready():
	_cam.current = true

var _mouse_dir = Vector2.ZERO

var _x = 0
var _y = 0

func _input(event):
	var left_pressed = Input.is_mouse_button_pressed(BUTTON_LEFT)
	var right_pressed = Input.is_mouse_button_pressed(BUTTON_RIGHT)
	if event is InputEventMouseMotion:
		if left_pressed:
			_x -= event.relative.y * x_sens
			if not right_pressed:
				_y -= event.relative.x * y_sens
	elif left_pressed and right_pressed:
		_y = 0
	
	if event is InputEventMouseButton:
		var zoom_delta = 0
		if Input.is_action_pressed("zoom_in"):
			zoom_delta = zoom_step
		elif Input.is_action_pressed("zoom_out"):
			zoom_delta = -zoom_step
		if zoom_delta != 0:
			_cam.transform.origin.z += zoom_delta
			_cam.transform.origin.z = clamp(_cam.transform.origin.z, min_zoom, max_zoom)

			
func _physics_process(delta):
	_x = clamp(_x, x_min, x_max)
	_pivot_y.rotation_degrees.y = lerp(_pivot_y.rotation_degrees.y, _y, delta * y_accel)
	_pivot_x.rotation_degrees.x = lerp(_pivot_x.rotation_degrees.x, _x, delta * x_accel)

