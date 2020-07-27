class_name Player
extends Character

var last_direction := Vector3.ZERO

var _right_button_pressed = false
var _left_button_pressed = false

onready var timer: Timer = $Timer
onready var camera: Spatial = $PlayerCamera

func _ready() -> void:
	#warning-ignore: return_value_discarded
	timer.connect("timeout", self, "_on_timer_timeout")
	camera.dont_collide_with(self)
	hide()

	
func _process(delta):
	if Input.is_action_pressed("jump") and state == States.ON_GROUND:
		jump()
		
	_right_button_pressed = Input.is_mouse_button_pressed(BUTTON_RIGHT)
	_left_button_pressed = Input.is_mouse_button_pressed(BUTTON_LEFT)

	
func _physics_process(_delta: float) -> void:
	direction = _get_direction()
	if _right_button_pressed:
		.turn_to(camera.get_rotation_degrees().y)

func setup(username: String, position: Vector3, turn_angle: float) -> void:
	self.username = username
	set_global_position(position)
	turn_to(turn_angle)
	spawn()
	show()

func spawn() -> void:
	.spawn()
	yield(self, "spawned")


func jump() -> void:
	.jump()
	MatchController.send_jump()

func _get_direction() -> Vector3:
	var new_direction := Vector3.ZERO
	if _left_button_pressed and _right_button_pressed:
		var cam_dir = camera.get_direction()
		new_direction = Vector3(cam_dir.x, 0, cam_dir.z)
	else:
		new_direction = Vector3(
			Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
			0,
			Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
		)
		new_direction = new_direction.rotated(Vector3.UP, deg2rad(.get_turn_angle()))

	if new_direction != last_direction:
		MatchController.send_input_update(new_direction)
		last_direction = new_direction
	return new_direction

func _on_timer_timeout() -> void:
	MatchController.send_transform_update(global_transform.origin, .get_turn_angle())