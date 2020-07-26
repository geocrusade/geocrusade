extends Spatial

onready var label = $Label
onready var camera_node = get_tree().root.get_camera()

func _process(_delta):
	var target_pos_3d = self.global_transform.origin
	var target_pos_2d = camera_node.unproject_position(target_pos_3d)
	label.set_global_position(target_pos_2d)
	
func set_text(text):
	label.text = text
