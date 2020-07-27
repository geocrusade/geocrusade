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

const MAX_SPEED := 200.0
const JUMP_SPEED := 35.0
const GRAVITY := 100.0
const ACCELERATION := 1000.0
const DRAG_AMOUNT := 0.3

var state: int = States.ON_GROUND

var velocity := Vector3.ZERO
var direction := Vector3.ZERO
var username := "" setget _set_username

var last_position := Vector3.ZERO
var last_input := Vector3.ZERO
var next_position := Vector3.ZERO
var next_input := Vector3.ZERO
var next_jump := false
var next_turn_angle := 0.0

onready var tween := $Tween
onready var mesh := $CSGMesh
onready var collider := $CollisionShape
onready var username_label := $Label3D

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
	$Label3D/Label.hide()

func move(delta: float) -> void:
	var accel = direction.normalized() * ACCELERATION * delta
	velocity.x = accel.x
	velocity.z = accel.z
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	velocity.z = clamp(velocity.z, -MAX_SPEED, MAX_SPEED)
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

func turn_to(y_degree: float) -> void:
	mesh.rotation_degrees.y = y_degree
	collider.rotation_degrees.y = y_degree

func get_turn_angle() -> float:
	return mesh.rotation_degrees.y

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
	$Label3D/Label.show()
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

	if global_transform.origin.distance_squared_to(last_position) > 10:
		tween.interpolate_method(self, "set_global_position", global_transform.origin, last_position, 0.2)
		tween.start()
	else:
		var anticipated := last_position + velocity * 0.2
		tween.interpolate_method(self, "move_to_position", global_transform.origin, anticipated, 0.2)
		tween.start()

	direction.x = last_input.x
	direction.z = last_input.z
	
	turn_to(next_turn_angle)

	last_input = next_input
	last_position = next_position


func set_global_position(pos: Vector3) -> void:
	global_transform.origin = pos
	
func move_to_position(new_position: Vector3) -> void:
	var distance := new_position - global_transform.origin
	move_and_slide(distance, Vector3.UP)

func _set_username(value: String) -> void:
	username = value
	username_label.set_text(value)