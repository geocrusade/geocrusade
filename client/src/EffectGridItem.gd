extends Control

onready var _color_rect : ColorRect = $ColorRect
onready var _count_label : Label = $ColorRect/Count
onready var _duration_label : Label = $Duration

func set_color(color : Color):
	_color_rect.color = color

func set_count(count : int):
	_count_label.text = String(count)

func set_duration(duration_seconds : int):
	_duration_label.text = "%ss" % duration_seconds
