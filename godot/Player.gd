extends KinematicBody

onready var player_network_id = int(self.name)

const MS_PER_TICK = (1.0 / 60)
const MS_PER_MOVE_BATCH = MS_PER_TICK * 20
const PUPPET_UPDATE_QUEUE_SIZE = int(0.1 / MS_PER_TICK)

var tick = 0

# For master of player
var moves = []
var move_corrections = []

# For peers
var puppet_update_queue = []
var puppet_ticks_since_update = 0

# For server
var move_requests = []

remote func request_move(move, start_pos):
	var master_id = get_network_master()
	if get_tree().is_network_server() and master_id  == get_tree().get_rpc_sender_id():
		move_requests.append({move = move, start_pos = start_pos })

remote func correct_move(tick, start_pos):
	if get_tree().get_rpc_sender_id() == 1:
		move_corrections.append({ tick = tick, start_pos = start_pos })

puppet func update_puppet(direction, start_pos, tick):
	if get_tree().get_rpc_sender_id() == 1:
		var new_update = { direction = direction, start_pos = start_pos, tick = tick }
		var insert_index = puppet_update_queue.bsearch_custom(new_update, self, "_compare_puppet_update")
		puppet_update_queue.insert(insert_index, new_update)
			

func _compare_puppet_update(update_a, update_b):
	return update_a.tick < update_b.tick

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
		if move_requests.size() > 0:
			var request = move_requests.pop_front()
			for peer_id in get_tree().get_network_connected_peers():
				if peer_id != master_id:
					rpc_unreliable_id(peer_id, "update_puppet", request.move.direction, current_pos, tick)
			
			if current_pos != request.start_pos:
				rpc_unreliable_id(master_id, "correct_move", request.move.tick, current_pos)
			
			_move(request.move.direction, delta)

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
		
		if not is_server:
			while move_corrections.size() > 0:
				var correction = move_corrections.pop_front()
				if correction.tick < tick and correction.tick >= moves[0].tick:
					var to_correct_index = correction.tick - moves[0].tick
					global_transform.origin = correction.start_pos
					for i in range(to_correct_index, moves.size()):
						var m = moves[i]
						_move(m.direction, m.delta)
					if move_corrections.empty():
						.force_update_transform()
						current_pos = global_transform.origin
					
			var move = { direction = direction, tick = tick, delta = delta }
			moves.append(move)
			rpc_unreliable_id(1, "request_move", move, current_pos)
		else:
			rpc_unreliable("update_puppet", direction, current_pos)
		
		_move(direction, delta)
	else:
		var queue_size = puppet_update_queue.size()
		var next_exists = queue_size >= 2
		var current_exists = queue_size > 0
		if current_exists and not next_exists:
			var current_update = puppet_update_queue[0]
			if puppet_ticks_since_update == 0:
				global_transform.origin = current_update.start_pos
			_move(current_update.direction, delta)
			# @TODO revisit this - currently players stop moving until next
			puppet_ticks_since_update += 1
		elif current_exists and next_exists:
			var current_update = puppet_update_queue[0]
			var next_update = puppet_update_queue[1]
			var ticks_between = next_update.tick - current_update.tick
			if ticks_between == 1:
				puppet_update_queue.pop_front()
				puppet_ticks_since_update = 0
				global_transform.origin = current_update.start_pos
				_move(current_update.direction, delta)
			elif ticks_between > 1 and ticks_between > puppet_ticks_since_update:
				global_transform.origin = current_update.start_pos.linear_interpolate(next_update.start_pos, float(puppet_ticks_since_update) / ticks_between)
				puppet_ticks_since_update += 1
			elif ticks_between > 1 and ticks_between <= puppet_ticks_since_update:
				puppet_update_queue.pop_front()
				puppet_ticks_since_update = 0
				
	tick += 1
	
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
	
	
