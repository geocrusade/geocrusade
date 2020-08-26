extends Control

onready var _ui = $AuthUI

onready var _timer = $Timer

func _ready():
	_ui.connect("auth_requested", self, "_start_auth")
	_timer.connect("timeout", self, "_finish_auth")
	
func _start_auth(username):
	print(username)
	_timer.start(2)

func _finish_auth():
	_ui.reset()
