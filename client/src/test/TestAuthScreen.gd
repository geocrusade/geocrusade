extends Node

onready var _auth_screen = $AuthScreen

onready var _timer = $Timer

func _ready():
	_auth_screen.connect("auth_requested", self, "_start_auth")
	_timer.connect("timeout", self, "_finish_auth")
	
func _start_auth(username):
	print(username)
	_timer.start(2)

func _finish_auth():
	_auth_screen.reset()
	_auth_screen.hide()
