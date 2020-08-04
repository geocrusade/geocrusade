extends Node

export var CharacterScene: PackedScene
export var ProjectileScene : PackedScene

var characters := {}
var _projectiles = {}

onready var player : Player = $Player

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
	positions: Dictionary, 
	turn_angles: Dictionary, 
	inputs: Dictionary, 
	names: Dictionary,
	_targets: Dictionary,
	healths: Dictionary,
	powers: Dictionary,
	casts: Dictionary,
	projectiles: Dictionary,
	effects: Dictionary
) -> void:
	var user_id: String = ServerConnection.get_user_id()
	var username: String = names.get(user_id)
	var p = positions[user_id]
	var player_position := Vector3(p.x, p.y, p.z)
	player.setup(username, player_position, turn_angles[user_id], healths[user_id], powers[user_id], effects[user_id])
	player.connect("input_event", self, "_on_character_input_event", [ ServerConnection.get_user_id() ])
	
	var users = MatchController.users
	for id in users.keys():
		if id in positions:
			var user_p = positions[id]
			var character_position := Vector3(user_p.x, user_p.y, user_p.z)
			var user_dir = inputs[id].dir
			var character_direction := Vector3(user_dir.x, user_dir.y, user_dir.z)
			if not id in characters:
				create_character(
					id, 
					names[id], 
					character_position, 
					turn_angles[id],
					character_direction,
					healths[id],
					powers[id],
					casts,
					effects[id]
				)
			else:
				var character = characters[id]
				character.next_position = character_position
				character.next_turn_angle = turn_angles[id]
				character.next_input = character_direction
				character.next_jump = inputs[id].jmp == 1
				character.health = healths[id]
				character.power = powers[id]
				character.effects = effects[id]
				character.update_state()
				character.spawn()
				if id in casts:
					character.set_cast(casts[id])
					
	_update_projectiles(projectiles)

func create_character(
	id: String,
	username: String,
	position: Vector3,
	turn_angle: float,
	direction: Vector3,
	health: int,
	power: int,
	casts: Dictionary,
	effects: Array
) -> void:
	var character := CharacterScene.instance()
	#warning-ignore: return_value_discarded
	get_parent().add_child(character)
	character.direction = direction
	character.username = username
	character.health = health
	character.power = power
	character.effects = effects
	if id in casts:
		character.set_cast(casts[id])
	character.set_global_position(position)
	character.turn_to(turn_angle)
	character.spawn()
	character.connect("input_event", self, "_on_character_input_event", [ id ])
	characters[id] = character

func _on_users_changed() -> void:
	var users = MatchController.users

	for key in users:
		if not key in characters:
			create_character(key, users[key].username, Vector3.ZERO, 0.0, Vector3.ZERO, 100, 100, {}, [])

	var to_delete := []
	for key in characters.keys():
		if not key in users:
			to_delete.append(key)

	for key in to_delete:
		
		if player.target == characters[key]:
			player.target = null
	
		characters[key].despawn()
		#warning-ignore: return_value_discarded
		characters.erase(key)
		
func _on_state_updated(
	positions: Dictionary, 
	turn_angles: Dictionary, 
	inputs: Dictionary, 
	targets: Dictionary, 
	healths: Dictionary, 
	powers: Dictionary,
	casts: Dictionary,
	projectiles: Dictionary,
	effects: Dictionary
) -> void:
	var player_id = ServerConnection.get_user_id()
	player.health = healths[player_id]
	player.power = powers[player_id]
	player.effects = effects[player_id]
	
	if player_id in casts:
		player.set_cast(casts[player_id])
	else:
		player.cancel_cast()
	
	for key in characters:
		var character = characters[key]
		if key in positions:
			var p : Dictionary = positions[key]
			character.next_position = Vector3(p.x, p.y, p.z)
		if key in turn_angles:
			var t : float = turn_angles[key]
			character.next_turn_angle = t
		if key in inputs:
			var dir = inputs[key].dir
			character.next_input = Vector3(dir.x, dir.y, dir.z)
			character.next_jump = inputs[key].jmp == 1
		if key in targets:
			if targets[key] in characters:
				character.target = characters[targets[key]]
			elif targets[key] == ServerConnection.get_user_id():
				character.target = player
		else:
			character.target = null
		if key in healths:
			character.health = healths[key]
		if key in powers:
			character.power = powers[key]
		if key in effects:
			character.effects = effects[key]
		if key in casts:
			character.set_cast(casts[key])
		else:
			character.cancel_cast()
				
		character.update_state()
		
	_update_projectiles(projectiles)
			

func _on_character_input_event(
	_camera : Node, 
	event : InputEvent, 
	_click_position : Vector3, 
	_click_normal : Vector3, 
	_shape_idx : int, 
	target_id : String
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			var prev_target = player.target
			if target_id == ServerConnection.get_user_id():
				player.target = player
			elif target_id in characters:
				player.target = characters[target_id]
			if prev_target != player.target:
				MatchController.send_target(target_id)
				
func _update_projectiles(latest_projectiles : Dictionary) -> void:
	for id in latest_projectiles:
		var proj = latest_projectiles[id]
		var proj_pos = Vector3(proj.position.x, proj.position.y, proj.position.z)
		if id in _projectiles:
			_projectiles[id].update_position(proj_pos)
		else:
			var instance = ProjectileScene.instance()
			add_child(instance)
			instance.update_position(proj_pos)
			_projectiles[id] = instance
		
		if proj.to_id in characters:
			_projectiles[id].look_at(characters[proj.to_id].get_node("LineOfSitePoint").global_transform.origin, Vector3.UP)
		elif proj.to_id == ServerConnection.get_user_id():
			_projectiles[id].look_at(player.get_node("LineOfSitePoint").global_transform.origin, Vector3.UP)
	
	for id in _projectiles:
		if not id in latest_projectiles:
			_projectiles[id].queue_free()
			_projectiles.erase(id)
