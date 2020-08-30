extends Spatial

signal auth_requested(username)

onready var _logo = $TitleLogo
onready var _auth_form = $AuthFormUI
onready var _name_field : LineEdit = $AuthFormUI/NameField
onready var _play_button : Button = $AuthFormUI/PlayButton
onready var _camera : Camera = $Camera

onready var _default_play_button_text : String = _play_button.text

func hide():
	_auth_form.hide()
	_logo.hide()
	_camera.current = false
	.hide()

func show():
	_auth_form.show()
	_logo.show()
	_camera.current = false
	.show()

func reset():
	_play_button.disabled = true
	_play_button.text = _default_play_button_text
	_name_field.text = ""
	_name_field.editable = true

func _ready():
	_play_button.disabled = true
	# warning-ignore:return_value_discarded
	_name_field.connect("text_changed", self, "_on_name_changed")
	# warning-ignore:return_value_discarded
	_play_button.connect("button_up", self, "_on_play_button_pressed")

func _on_name_changed(_text : String):
	var length = _clean_name(_name_field.text).length()
	_play_button.disabled = length == 0 or length > 50

func _on_play_button_pressed():
	emit_signal("auth_requested", _clean_name(_name_field.text))
	_name_field.editable = false
	_play_button.disabled = true
	_play_button.text = "Loading..."

func _clean_name(name : String) -> String:
	return name.replace("  ", "").trim_prefix(" ").trim_suffix(" ")
