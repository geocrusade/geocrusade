extends Spatial

onready var parent_node = get_parent_spatial()
onready var ui_node = get_node("Control")
onready var camera_node = get_tree().root.get_camera()

func _process(_delta):
	var target_pos_3d = self.global_transform.origin
	var target_pos_2d = camera_node.unproject_position(target_pos_3d)
	ui_node.set_position(target_pos_2d)
	
func set_text(text):
	get_node("Control/Label").text = text
