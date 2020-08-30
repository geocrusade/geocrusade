extends Spatial


onready var _client_player_scene := preload("res://src/ClientPlayer.tscn")
onready var _character_scene := preload("res://src/Character.tscn")

var client_player_character_id : String

var _character_nodes : Dictionary

func set_characters(characters : Dictionary) -> void:
	for id in characters:
		if not id in _character_nodes:
			_add_character(id, characters[id])
		else:
			_update_character(id, characters[id])

func _add_character(id : String, character : Dictionary) -> void:
	var node : Spatial = null
	if id == client_player_character_id:
		node = _client_player_scene.instance()
	else:
		node = _character_scene.instance()
	_character_nodes[id] = node
	.add_child(node)
	
func _update_character(id : String, character : Dictionary) -> void:
	var node : Spatial = _character_nodes[id]
	node.global_transform.origin = Vector3(character.Position.X, character.Position.Y, character.Position.Z)
	node.global_transform.basis.z = Vector3(character.Rotation.X, character.Rotation.Y, character.Rotation.Z)
