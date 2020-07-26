extends Node

export var WorldScene : PackedScene

func _ready() -> void:
	ServerConnection.connect("login_succeeded", self, "_on_login_succeeded")
	
func _on_login_succeeded() -> void:
	$Login.hide()
	add_child(WorldScene.instance())
