extends KinematicBody

export var speed : float = 200
export var jump_speed : float = 10
export var key_turn_speed : float = 5
export var mouse_turn_speed : float = 10
export var gravity : float = 40

var _velocity = Vector3.ZERO

var _mouse_delta_x = 0

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_RIGHT):
		_mouse_delta_x = event.relative.x

func _physics_process(delta):
	_move(delta)
	_turn(delta)

func _move(delta : float):
	var both_mouse_button_down = Input.is_mouse_button_pressed(BUTTON_LEFT) and Input.is_mouse_button_pressed(BUTTON_RIGHT)
	
	var input = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward") - int(both_mouse_button_down)
		).normalized()

	var direction = input.rotated(Vector3.UP, deg2rad(rotation_degrees.y))
		
	var vel_diff = direction * speed * delta
	
	_velocity.x = vel_diff.x
	_velocity.z = vel_diff.z
	
	var on_floor = .is_on_floor()

	if on_floor:
		_velocity.y = 0
		if Input.is_action_pressed("jump"):
			_velocity.y += jump_speed
	elif not on_floor:
		_velocity.y -= gravity * delta
		_velocity.y = max(_velocity.y, -gravity)
		
	# warning-ignore:return_value_discarded
	.move_and_slide(_velocity, Vector3.UP)

func _turn(delta : float):
	if not Input.is_mouse_button_pressed(BUTTON_RIGHT):
		var dir = 0
		if Input.is_action_pressed("turn_left"):
			dir = 1
		elif Input.is_action_pressed("turn_right"):
			dir = -1
		.rotate(Vector3.UP, dir * key_turn_speed * delta)
	else:
		.rotate(Vector3.UP, -clamp(_mouse_delta_x, -mouse_turn_speed, mouse_turn_speed) * delta)
		_mouse_delta_x = 0
