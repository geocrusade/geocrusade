extends Control

signal color_saved(color)

export var skin_material : SpatialMaterial

onready var _picker : ColorPicker = $ColorPicker
onready var _edit_button : Button = $EditButton
onready var _save_button : Button = $SaveButton
onready var _cancel_button : Button = $CancelButton

onready var _saved_color : Color = skin_material.albedo_color

func set_skin_color(color : Color):
	skin_material.albedo_color = color

func _ready():
	_picker.color = _saved_color
	_picker.connect("color_changed", self, "set_skin_color")
	_edit_button.connect("button_up", self, "_edit")
	_save_button.connect("button_up", self, "_save")
	_cancel_button.connect("button_up", self, "_reset")

func _edit():
	_picker.show()
	_save_button.show()
	_cancel_button.show()
	_edit_button.hide()

func _save():
	_saved_color = skin_material.albedo_color
	emit_signal("color_saved", _saved_color)
	_reset()
	
func _reset():
	_picker.hide()
	_save_button.hide()
	_cancel_button.hide()
	_edit_button.show()
	set_skin_color(_saved_color)
