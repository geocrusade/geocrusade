extends Spatial

onready var control : Control = $Control
onready var health_bar : ProgressBar = $Control/HealthBar
onready var power_bar : ProgressBar = $Control/PowerBar
onready var cast_bar : ProgressBar = $Control/CastBar
onready var cast_bar_label : Label = $Control/CastBar/Label
onready var username_label : Label = $Control/Username
onready var target_label : Label = $Control/Target
onready var targeting_highlight : ColorRect = $Control/TargetingHighlight
onready var camera_node = get_tree().root.get_camera()

var _x_offset = 0
var _y_offset = 0

var _enabled = true 

func _ready():
	$VisibilityNotifier.connect("camera_entered", self, "_camera_entered")
	$VisibilityNotifier.connect("camera_exited", self, "_camera_exited")
	_x_offset = control.rect_position.x
	_y_offset = control.rect_position.y

func _process(_delta):
	if _enabled:
		var target_pos_3d = self.global_transform.origin
		var target_pos_2d = camera_node.unproject_position(target_pos_3d)
		target_pos_2d.x += _x_offset
		target_pos_2d.y += _y_offset
		control.set_global_position(target_pos_2d)
	
func set_username(value : String):
	username_label.text = value

func set_target_username(value : String):
	if value == username_label.text:
		target_label.text = "--SELF--"
	elif value == ServerConnection.get_username():
		target_label.text = "--YOU--"
	else:
		target_label.text = value

func set_as_target(as_target : bool) -> void:
	if as_target:
		targeting_highlight.show()
	else:
		targeting_highlight.hide()

func set_health(value : int) -> void:
	health_bar.value = value
	
func set_power(value : int) -> void:
	power_bar.value = value

func set_cast_bar(current_seconds : float, total_seconds : float) -> void:
	cast_bar.ratio = current_seconds / total_seconds

func get_cast_bar_value() -> float:
	return cast_bar.ratio

func set_cast_bar_label(value : String) -> void:
	cast_bar_label.text = value

func _camera_entered(_camera) -> void:
	_enabled = true
	control.show()

func _camera_exited(_camera) -> void:
	_enabled = false
	control.hide()
