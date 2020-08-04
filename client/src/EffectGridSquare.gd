extends Control


onready var _color_rect : ColorRect = $ColorRect
onready var _stack_count : Label = $StackCount
onready var _time_remaining : Label = $TimeRemaining

func set_color(color : Color) -> void:
	_color_rect.color = color

func set_stack_count(count : int) -> void:
	_stack_count.text = String(count)

func set_time_remaining(time_seconds : float) -> void:
	_time_remaining.text = String(time_seconds)
