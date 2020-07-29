class_name Player
extends Character

var last_direction := Vector3.ZERO

var _right_button_pressed = false
var _left_button_pressed = false

onready var timer: Timer = $Timer
onready var camera: Spatial = $PlayerCamera

onready var alert : Label = $Alert
onready var alert_timer : Timer = $AlertTimer

func _ready() -> void:
	#warning-ignore: return_value_discarded
	timer.connect("timeout", self, "_on_timer_timeout")
	alert_timer.connect("timeout", self, "_hide_alert")
	camera.dont_collide_with(self)
	hide()

	
func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("jump") and state == States.ON_GROUND:
		jump()
	
	if event.is_action_pressed("ability_1"):
		if target == null:
			_show_alert("No target!")
		elif not _is_facing_target():
			_show_alert("Not facing target!")
		elif not _is_target_in_line_of_sight():
			_show_alert("Target not in line of sight!")
		else:
			#cast
			pass
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			_right_button_pressed =  event.pressed
		if event.button_index == BUTTON_LEFT:
			_left_button_pressed =event.pressed

	
func _physics_process(_delta: float) -> void:
	direction = _get_direction()
	if _right_button_pressed:
		.turn_to(camera.get_rotation_degrees().y)

func setup(username: String, position: Vector3, turn_angle: float, health : int, power : int) -> void:
	self.username = username
	self.health = health
	self.power = power
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

func _set_target(value : Character) -> void:
	if value != null:
		value.hud.set_as_target(true)
	if target != null and target != value:
		target.hud.set_as_target(false)
	._set_target(value)
	
func _is_target_in_line_of_sight() -> bool:
	if target == null:
		return false
	var from : Vector3 = get_node("LineOfSitePoint").global_transform.origin
	var to : Vector3 = target.get_node("LineOfSitePoint").global_transform.origin
	var hit = get_world().direct_space_state.intersect_ray(from, to)
	return hit and hit.collider == target

func _is_facing_target() -> bool:
	if target == null:
		return false
	else:	
		var angle_1 = atan2(global_transform.origin.z, global_transform.origin.x)
		var angle_2 = atan2(target.global_transform.origin.z, target.global_transform.origin.x)
		var diff_rad = angle_2 - angle_1 - deg2rad(.get_turn_angle())
		var diff_deg = fmod(rad2deg(diff_rad), 360.0)
		return (diff_deg > 0 and diff_deg < 180) or (diff_deg < -180)

func _show_alert(text : String) -> void:
	alert.text = text
	alert.show()
	alert_timer.start()

func _hide_alert() -> void:
	alert.hide()
