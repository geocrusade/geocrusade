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
			return
		
		var composite_ability = _get_new_composite_ability(ServerConnection.game_config.ability_codes.FIRE)
		if power < composite_ability.power_cost:
			_show_alert("Not enough power!")
		elif not _target_in_range(composite_ability.max_target_distance):
			_show_alert("Target too far!")
		elif not _is_facing_target():
			_show_alert("Not facing target!")
		elif not _is_target_in_line_of_sight():
			_show_alert("Target not in line of sight!")
		elif not is_casting():
			cast_ability_codes = [ ServerConnection.game_config.ability_codes.FIRE ]
			MatchController.send_start_cast(cast_ability_codes)
		elif cast_ability_codes.size() < ServerConnection.game_config.max_composite_ability_size:
			cast_ability_codes.append(ServerConnection.game_config.ability_codes.FIRE)
			MatchController.send_cast_update([ ServerConnection.game_config.ability_codes.FIRE  ])
		else:
			_show_alert("Can't cast more abilities!")
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			_right_button_pressed =  event.pressed
		if event.button_index == BUTTON_LEFT:
			_left_button_pressed =event.pressed
	
	
func _physics_process(_delta: float) -> void:
	direction = _get_direction()
	if direction != Vector3.ZERO and is_casting():
		.cancel_cast()
		MatchController.send_cancel_cast()
		
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
	elif target == self:
		return true
	var from : Vector3 = get_node("LineOfSitePoint").global_transform.origin
	var to : Vector3 = target.get_node("LineOfSitePoint").global_transform.origin
	var hit = get_world().direct_space_state.intersect_ray(from, to)
	return hit and hit.collider == target

func _is_facing_target() -> bool:
	if target == self:
		return true
	var direction = global_transform.origin - target.global_transform.origin 
	return direction.dot(global_transform.basis.z) < 0

func _target_in_range(max_distance : int) -> bool:
	return target.global_transform.origin.distance_to(global_transform.origin) <= max_distance

func _get_new_composite_ability(next_ability_code : int) -> Dictionary:
	var codes = cast_ability_codes.duplicate()
	if codes.size() > 0:
		codes.append(next_ability_code)
		var composite_ability = ServerConnection.get_ability(codes[0]).primary.duplicate(true)
		for i in range(1, codes.size()):
			var secondary = ServerConnection.get_ability(codes[i]).secondary
			composite_ability.max_target_distance += secondary.max_target_distance
			composite_ability.power_cost += secondary.power_cost
			# add more as needed 
		return composite_ability
	else:
		return ServerConnection.get_ability(next_ability_code).primary
		
func _show_alert(text : String) -> void:
	alert.text = text
	alert.show()
	alert_timer.start()

func _hide_alert() -> void:
	alert.hide()
