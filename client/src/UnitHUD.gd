extends Control

export var effects_grid_item : PackedScene
export var hostile_health_bar_style : StyleBoxFlat
export var friendly_health_bar_style : StyleBoxFlat
export var is_hostile : bool = false

onready var _cast_bar : ProgressBar = $CastBar
onready var _cast_bar_label : Label = $CastBar/Label
onready var _health_bar : ProgressBar = $HealthBar
onready var _name_label : Label = $HealthBar/Name
onready var _power_bar : ProgressBar = $PowerBar
onready var _effects_grid : GridContainer = $EffectsGrid

func set_is_hostile(is_hostile  : bool):
	self.is_hostile = is_hostile
	var style = friendly_health_bar_style
	if is_hostile:
		style = hostile_health_bar_style
	_health_bar.set("custom_styles/fg", style)
	
		
func _ready():
	set_is_hostile(is_hostile)

func set_cast(time : float, total_time : float, label : String):
	_cast_bar.value = (time / total_time) * 100
	_cast_bar_label.text = label
	if round(_cast_bar.value) == 0:
		_cast_bar.hide()
	else:
		_cast_bar.show()

func set_health(value : float):
	_health_bar.value = value

func set_power(value : float):
	_power_bar.value = value

func set_name(text : String):
	_name_label.text = text

func set_effect(effect_code: int, color : Color, duration_seconds : int, count : int):
	var item_name = String(effect_code)
	var item = _effects_grid.get_node(item_name)
	if item == null:
		item = effects_grid_item.instance()
		_effects_grid.add_child(item)
		item.name = item_name
		item.set_color(color)
	
	item.set_duration(duration_seconds)
	item.set_count(count)

func remove_effect(effect_code):
	var item = _effects_grid.get_node(String(effect_code))
	if item != null:
		_effects_grid.remove_child(item)
		item.queue_free()
