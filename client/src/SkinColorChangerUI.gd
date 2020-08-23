extends Control

export var skin_material : SpatialMaterial

onready var _red_slider = $RedSlider
onready var _green_slider = $GreenSlider
onready var _blue_slider = $BlueSlider
onready var _red_label = $RedSlider/RedLabel
onready var _green_label = $GreenSlider/GreenLabel
onready var _blue_label = $BlueSlider/BlueLabel
onready var _color_rect = $ColorRect


func set_skin_color(color : Color):
	skin_material.albedo_color = color

func _ready():
	_red_slider.connect("value_changed", self, "_value_changed", [_red_label])
	_green_slider.connect("value_changed", self, "_value_changed", [_green_label])
	_blue_slider.connect("value_changed", self, "_value_changed", [_blue_label])
	
func _value_changed(value : float, label : Label):
	label.text = String(value)
	var color = _get_color()
	_color_rect.color = color
	set_skin_color(color)

func _get_color() -> Color:
	return Color8(int(_red_label.text), int(_green_label.text), int(_blue_label.text))
