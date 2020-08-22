extends Control

onready var button = $Button
onready var label = $Label
onready var name_field = $LineEdit

func _ready() -> void:
	button.connect("pressed", self, "_start_login")
	ServerConnection.connect("login_started", self, "_show_logging_in_state")
	ServerConnection.connect("login_failed", self, "_show_login_fail_state")
	ServerConnection.connect("login_succeeded", self, "_show_login_success_state")

func _start_login() -> void:
	ServerConnection.login(name_field.text)

func _show_logging_in_state() -> void:
	label.text = "Logging in..."
	name_field.editable = false
	button.disabled = true
	
func _show_login_fail_state() -> void:
	_reset()
	label.text = "Login failed. Try again."

func _show_login_success_state() -> void:
	_reset()
	label.text = "Success!"

func _reset() -> void:
	name_field.clear()
	name_field.editable = true
	button.disabled = false
