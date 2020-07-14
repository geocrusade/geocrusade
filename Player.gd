extends KinematicBody

onready var player_network_id = int(self.name)

# For master of player
var move_request_window = []
var move_request_count = 0
var move_request_correction = { request_number = -1 }
var last_corrected_move_request_number = -1

# For peer clients
var puppet_direction = Vector3.ZERO
var puppet_position = Vector3.ZERO
var puppet_position_set = true

# For server
var last_move_request_number = -1
var move_request = { number = -1 }

remote func request_move(direction, start_pos, number):
	if get_tree().is_network_server() and get_network_master()  == get_tree().get_rpc_sender_id():
		set_deferred("move_request", { direction = direction, start_pos = start_pos, number = number})

master func correct_move_request(start_pos, request_number):
	if get_tree().get_rpc_sender_id() == 1:
		set_deferred("move_request_correction", { start_pos = start_pos, request_number = request_number })
		
remote func update_puppet(direction, position):
	if get_tree().get_rpc_sender_id() == 1:
		set_deferred("puppet_direction", direction)
		set_deferred("puppet_position_set", false)
		set_deferred("puppet_position", position)

func set_player_name(new_name):
	get_node("PlayerName").set_text(new_name)
	
func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	var is_server = get_tree().is_network_server()
	var is_master = is_network_master()
	var master_id = get_network_master()
	var current_pos = global_transform.origin
	if is_server and not is_master:
		if move_request.number != last_move_request_number:
			last_move_request_number = move_request.number
			if move_request.start_pos != current_pos:
				rpc_unreliable_id(master_id, "correct_move_request", current_pos, move_request.number)

		if move_request.has("direction"):
			for peer_id in get_tree().get_network_connected_peers():
				if peer_id != master_id:
					rpc_unreliable_id(peer_id, "update_puppet", move_request.direction, current_pos)
			_move(move_request.direction, delta)
			

	elif is_master: 
		var direction = Vector3.ZERO
		if Input.is_action_pressed("Forward"):
			direction.z = 1
		elif Input.is_action_pressed("Backward"):
			direction.z = -1
	
		if Input.is_action_pressed("Left"):
			direction.x = 1
		elif Input.is_action_pressed("Right"):
			direction.x = -1
		
		if is_server:
			for peer_id in get_tree().get_network_connected_peers():
				rpc_unreliable_id(peer_id, "update_puppet", direction, current_pos)
		else:	
			_correct_master_position(delta)
			var request = { direction = direction, start_pos = current_pos, number = move_request_count }
			rpc_unreliable_id(1, "request_move", direction, current_pos, move_request_count)
			move_request_count += 1
			move_request_window.append(request)
			if move_request_window.size() > int(1.0 / delta):
				move_request_window.pop_front()
		
		_move(direction, delta)
		
	else:
		if not puppet_position_set and current_pos != puppet_position:
			puppet_position_set = true
			global_transform.origin = puppet_position
		_move(puppet_direction, delta)

func _correct_master_position(delta):
	var correction_number = move_request_correction.request_number
	if correction_number != last_corrected_move_request_number and correction_number < move_request_count and correction_number >= move_request_window[0].number:
		var corrected_request_index = correction_number - move_request_window[0].number
		var corrected_request = move_request_window[corrected_request_index] 
		corrected_request.start_pos = move_request_correction.start_pos
		move_request_window[corrected_request_index] = corrected_request
		global_transform.origin = move_request_correction.start_pos
		_move(corrected_request.direction, delta)
		.force_update_transform()
		for i in range(corrected_request_index+1, move_request_window.size()):
			var r = move_request_window[i]
			var new_start_pos = global_transform.origin
			if new_start_pos != r.start_pos:
				r.start_pos = new_start_pos
				move_request_window[i] = r
				_move(corrected_request.direction, delta)
				.force_update_transform()
			else:
				break
	
func _move(direction, delta):
	var velocity = direction.normalized()
	var forward_speed = 20
	var backward_speed = 15

	if velocity.z > 0:
		velocity.z *= forward_speed
		velocity.x *= forward_speed
	else:
		velocity.z *= backward_speed
		velocity.x *= backward_speed
	
	.move_and_collide(velocity * delta)
