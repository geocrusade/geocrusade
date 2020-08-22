class_name Character
extends KinematicBody

enum States { ON_GROUND, IN_AIR }

signal spawned
signal despawned

const SCALE_BASE := Vector3(1, 1.5, 1)
const SCALE_SQUASHED := SCALE_BASE * Vector3(1.25, 0.5, 1)
const SCALE_STRETCHED := SCALE_BASE * Vector3(0.8, 1.35, 1) 
const ANIM_IN_DURATION := 0.1
const ANIM_OUT_DURATION := 0.25

const JUMP_SPEED := 35.0
const GRAVITY := 100.0
const ACCELERATION := 1000.0
const DRAG_AMOUNT := 0.3

var state: int = States.ON_GROUND

var velocity := Vector3.ZERO
var direction := Vector3.ZERO
var username := "" setget _set_username

var health : int = 100 setget _set_health
var power : int = 100 setget _set_power
var target : Character = null setget _set_target

var effects : Dictionary = {} setget _set_effects

var speed : float = 1000

var last_position := Vector3.ZERO
var last_input := Vector3.ZERO
var next_position := Vector3.ZERO
var next_input := Vector3.ZERO
var next_jump := false
var next_rotation := Vector3.FORWARD

var cast_ability_codes : Array = []

onready var tween := $Tween
onready var mesh := $CSGMesh
onready var collider := $CollisionShape
onready var cast_timer := $CastTimer

onready var hud := $HUD

func _physics_process(delta: float) -> void:
	move(delta)

	match state:
		States.ON_GROUND:
			if not is_on_floor():
				state = States.IN_AIR
				stretch()
		States.IN_AIR:
			if is_on_floor():
				state = States.ON_GROUND
				velocity.y = 0
				squash()

func set_hidden() -> void:
	.hide()
	hud.hide()

func move(delta: float) -> void:
	var vel = direction.normalized() * speed * delta
	velocity.x = vel.x
	velocity.z = vel.z
	if direction.x == 0:
		velocity.x = lerp(velocity.x, 0, DRAG_AMOUNT)
	if direction.z == 0:
		velocity.z = lerp(velocity.z, 0, DRAG_AMOUNT)
	velocity.y -= GRAVITY * delta
	velocity = move_and_slide(velocity, Vector3.UP)

func jump() -> void:
	stretch()
	velocity.y += JUMP_SPEED
	state = States.IN_AIR

func get_turn_angle() -> float:
	return fmod(rotation_degrees.y, 360.0)
	
func set_rotation(z_basis: Vector3) -> void:
	.global_rotate(Vector3.UP, global_transform.basis.z.angle_to(z_basis))

func start_cast(ability_codes : Array, start_time : float = 0) -> void:
	var cast_time_seconds : float = 0
	var cast_bar_label = ""
	for i in range(ability_codes.size()):
		var config = ServerConnection.get_ability(ability_codes[i])
		if i == 0:
			cast_time_seconds += config.primary.cast_duration_seconds
			cast_bar_label += config.name
		else:
			cast_bar_label += "," + config.name
			cast_time_seconds += config.secondary.cast_duration_seconds
	hud.set_cast_bar_label(cast_bar_label)
	cast_timer.start(cast_time_seconds - start_time)

func set_cast(cast : Dictionary) -> void:
	var cast_bar_label = ""
	hud.set_cast_bar(cast.elapsed_time_seconds, cast.composite_ability.cast_duration_seconds)
	hud.set_cast_bar_label(cast.composite_ability.name)
	cast_ability_codes = cast.ability_codes
	
func cancel_cast() -> void:
	hud.set_cast_bar(0.0, 1.0)
	hud.set_cast_bar_label("")
	cast_ability_codes.clear()
	
func is_casting() -> bool:
	return hud.get_cast_bar_value() > 0 or cast_ability_codes.size() > 0

func stretch() -> void:
	tween.interpolate_property(
		mesh,
		"scale",
		SCALE_BASE,
		SCALE_STRETCHED,
		ANIM_IN_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	tween.interpolate_property(
		mesh,
		"scale",
		SCALE_STRETCHED,
		SCALE_BASE,
		ANIM_OUT_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		ANIM_IN_DURATION
	)
	tween.start()

func squash() -> void:
	tween.interpolate_property(
		mesh, 
		"scale", 
		SCALE_BASE, 
		SCALE_SQUASHED, 
		ANIM_IN_DURATION, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_OUT
	)
	tween.interpolate_property(
		mesh,
		"scale",
		SCALE_SQUASHED,
		SCALE_BASE,
		ANIM_IN_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		ANIM_IN_DURATION
	)
	tween.start()

func spawn() -> void:
	.show()
	hud.show()
	tween.interpolate_property(
		mesh, 
		"scale", 
		Vector3.ZERO, 
		SCALE_BASE, 
		0.75, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_OUT
	)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("spawned")

func despawn() -> void:
	tween.interpolate_property(
		mesh, 
		"scale", 
		SCALE_BASE, 
		Vector3.ZERO, 
		1.0, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_IN
	)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("despawned")
	queue_free()

func update_state() -> void:
	if next_jump:
		jump()
		next_jump = false

	if global_transform.origin.distance_squared_to(next_position) > 5:
		tween.interpolate_method(self, "set_global_position", global_transform.origin, next_position, 0.2)
		tween.start()
	else:
		var anticipated := last_position + velocity * 0.2
		tween.interpolate_method(self, "move_to_position", global_transform.origin, anticipated, 0.2)
		tween.start()

	direction.x = last_input.x
	direction.z = last_input.z
	
	self.set_rotation(next_rotation)

	last_input = next_input
	last_position = next_position


func set_global_position(pos: Vector3) -> void:
	global_transform.origin = pos
	
func move_to_position(new_position: Vector3) -> void:
	var distance := new_position - global_transform.origin
	move_and_slide(distance, Vector3.UP)

func _set_username(value: String) -> void:
	username = value
	hud.set_username(value)
	
func _set_health(value : int) -> void:
	health = value
	hud.set_health(value)

func _set_power(value : int) -> void:
	power = value
	hud.set_power(value)
	
func _set_effects(new_effects : Dictionary) -> void:
	for code in effects:
		if not code in new_effects:
			var effect_config = ServerConnection.get_effect(code)
			hud.remove_effect(effect_config.name)
			
	
	for code in new_effects:
		var new_eff = new_effects[code]
		var effect_config = ServerConnection.get_effect(code)
		var color_config = effect_config.color
		var color = Color(color_config.r, color_config.g, color_config.b)
		var effect_name = effect_config.name
		if not code in effects:
			hud.add_effect(effect_name, color, new_eff.remaining_seconds, new_eff.stack_count)
		else:
			hud.update_effect(effect_name, new_eff.remaining_seconds, new_eff.stack_count)
	
	effects = new_effects
	
func _set_target(value : Character) -> void:
	if target != value:
		target = value
		if target != null:
			hud.set_target_username(value.username)
		else:
			hud.set_target_username("")