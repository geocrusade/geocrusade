extends Node

export var CharacterScene: PackedScene

var characters := {}

onready var player : Player = get_parent().get_node("Player")

func _ready() -> void:
	#warning-ignore: return_value_discarded
	MatchController.connect(
		"initial_state_received", self, "_on_initial_state_received"
	)
		#warning-ignore: return_value_discarded
	MatchController.connect("users_changed", self, "_on_users_changed")
	#warning-ignore: return_value_discarded
	MatchController.connect("state_updated", self, "_on_state_updated")
	
func _on_initial_state_received(
	positions: Dictionary, turn_angles: Dictionary, inputs: Dictionary, names: Dictionary
) -> void:
	var user_id: String = ServerConnection.get_user_id()
	var username: String = names.get(user_id)
	var p = positions[user_id]
	var player_position := Vector3(p.x, p.y, p.z)
	print(player_position)
	player.setup(username, player_position, turn_angles[user_id])

	var users = MatchController.users
	for id in users.keys():
		if id in positions:
			var user_p = positions[id]
			var character_position := Vector3(user_p.x, user_p.y, user_p.z)
			var user_dir = inputs[id].dir
			var character_direction := Vector3(user_dir.x, user_dir.y, user_dir.z)
			if not id in characters:
				create_character(
					id, names[id], character_position, turn_angles[id], character_direction
				)
			else:
				var character = characters[id]
				character.next_position = character_position
				character.next_turn_angle = turn_angles[id]
				character.next_input = character_direction
				character.next_jump = inputs[id].jmp == 1
				character.update_state()
				character.spawn()

func create_character(
	id: String,
	username: String,
	position: Vector3,
	turn_angle: float,
	direction: Vector3
) -> void:
	var character := CharacterScene.instance()
	#warning-ignore: return_value_discarded
	get_parent().add_child(character)
	character.direction = direction
	character.username = username
	character.set_global_position(position)
	character.turn_to(turn_angle)
	characters[id] = character
	character.spawn()
		
func _on_users_changed() -> void:
	var users = MatchController.users

	for key in users:
		if not key in characters:
			create_character(key, users[key].username, Vector3.ZERO, 0.0, Vector3.ZERO)

	var to_delete := []
	for key in characters.keys():
		if not key in users:
			to_delete.append(key)

	for key in to_delete:
		characters[key].despawn()
		#warning-ignore: return_value_discarded
		characters.erase(key)
		
func _on_state_updated(positions: Dictionary, turn_angles: Dictionary, inputs: Dictionary) -> void:
	var update := false
	for key in characters:
		update = false
		if key in positions:
			var p : Dictionary = positions[key]
			characters[key].next_position = Vector3(p.x, p.y, p.z)
			update = true
		if key in turn_angles:
			var t : float = turn_angles[key]
			characters[key].next_turn_angle = t
			update = true
		if key in inputs:
			var dir = inputs[key].dir
			characters[key].next_input = Vector3(dir.x, dir.y, dir.z)
			characters[key].next_jump = inputs[key].jmp == 1
			update = true
		if update:
			characters[key].update_state()
