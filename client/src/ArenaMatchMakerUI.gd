extends Control

signal match_play_pressed(team_size)
signal search_canceled
signal match_rejected
signal match_joined

onready var _play_panel = $PlayPanel
onready var _searching_panel = $SearchingPanel
onready var _match_ready_panel = $MatchReadyPanel

onready var _play_button_1v1 = $PlayPanel/Button1v1
onready var _play_button_2v2 = $PlayPanel/Button2v2
onready var _play_button_3v3 = $PlayPanel/Button3v3

onready var _cancel_search_button = $SearchingPanel/Cancel
onready var _search_team_size_label = $SearchingPanel/TeamSize

onready var _match_timeout_second_timer = $MatchReadyPanel/Timer
onready var _match_timeout_label = $MatchReadyPanel/TimeRemaining
onready var _match_timeout = 0
onready var _reject_match_button = $MatchReadyPanel/Reject
onready var _join_match_button = $MatchReadyPanel/Join

func show_searching(team_size : int):
	_play_panel.hide()
	_match_ready_panel.hide()
	_searching_panel.show()
	_search_team_size_label.text = String(team_size) + "v" + String(team_size)

func show_match_ready(timeout_seconds : float):
	_play_panel.hide()
	_searching_panel.hide()
	_match_ready_panel.show()
	_match_timeout = timeout_seconds
	_match_timeout_label.text = String(_match_timeout)
	_match_timeout_second_timer.connect("timeout", self, "_update_match_timeout")

func reset():
	_play_panel.show()
	_searching_panel.hide()
	_match_ready_panel.hide()
	_match_timeout_label.text = ""
	_match_timeout_second_timer.disconnect("timeout", self, "_update_match_timeout")
	_reject_match_button.disabled = false
	_join_match_button.disabled = false
	
func _update_match_timeout():
	_match_timeout -= 1
	if _match_timeout < 0:
		_reject_match()
	else:
		_match_timeout_label.text = String(_match_timeout)
	
func _play(team_size : int):
	show_searching(team_size)
	emit_signal("match_play_pressed", team_size)

func _cancel_search():
	reset()
	emit_signal("search_canceled")

func _join_match():
	_reject_match_button.disabled = true
	_join_match_button.disabled = true
	emit_signal("match_joined")
	
func _reject_match():
	reset()
	emit_signal("match_rejected")	

func _ready():
	
	_play_button_1v1.connect("button_up", self, "_play", [ 1 ])
	_play_button_2v2.connect("button_up", self, "_play", [ 2 ])
	_play_button_3v3.connect("button_up", self, "_play", [ 3 ])
	
	_cancel_search_button.connect("button_up", self, "_cancel_search")
	
	_reject_match_button.connect("button_up", self, "_reject_match")
	_join_match_button.connect("button_up", self, "_join_match")
