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
		elif power < ServerConnection.get_ability(ServerConnection.game_config.ability_codes.FIRE).primary.power_cost:
			_show_alert("Not enough power!")
		elif not _target_in_range(ServerConnection.game_config.ability_codes.FIRE):
			_show_alert("Targe t too far!")
		elif not _is_facing_target():
			_show_alert("Not facing target!")
#		elif not _is_target_in_line_of_sight():
#			_show_alert("Target not in line of sight!")
		else:
			MatchController.send_start_cast([ ServerConnection.game_config.ability_codes.FIRE ])
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			_right_button_pressed =  event.pressed
		if event.button_index == BUTTON_LEFT:
			_left_button_pressed =event.pressed

	
func _physics_process(_delta: float) -> void:
	direction = _get_direction()
	if direction != Vector3.ZERO and hud.get_cast_bar_value() > 0:
		.cancel_cast()
		MatchController.send_cancel_cast()
		
	if _right_button_pressed:
		global_transform.basis = camera.get_horizontal_basis()

func setup(username: String, position: Vector3, turn_angle: float, health : int, power : int) -> void:
	print("SETUP PLAYER")
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
	elif target == self:
		return true
	var from : Vector3 = get_node("LineOfSitePoint").global_transform.origin
	var to : Vector3 = target.get_node("LineOfSitePoint").global_transform.origin
	var hit = get_world().direct_space_state.intersect_ray(from, to)
	return hit and hit.collider == target

func _is_facing_target() -> bool:
	var direction = global_transform.origin - target.global_transform.origin 
	return direction.dot(global_transform.basis.z) > 0

func _target_in_range(ability_code : int) -> bool:
	return target.global_transform.origin.distance_to(global_transform.origin) < ServerConnection.get_ability(ability_code).primary.max_target_distance 

func _show_alert(text : String) -> void:
	alert.text = text
	alert.show()
	alert_timer.start()

func _hide_alert() -> void:
	alert.hide()
