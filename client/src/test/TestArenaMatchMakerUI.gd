extends Control


onready var ui = $ArenaMatchMakerUI
onready var _search_timer = $SearchTimer

func _ready():
	ui.connect("match_play_pressed", self, "_on_play_match")
	ui.connect("match_joined", self, "_on_match_joined")
	ui.connect("match_rejected", self, "_on_match_rejected")
	ui.connect("search_canceled", self, "_on_search_canceled")

	
func _on_play_match(team_size):
	_search_timer.start(3)
	_search_timer.connect("timeout", self, "_on_search_complete")
	
func _on_search_complete():
	ui.show_match_ready(5)
	_search_timer.disconnect("timeout", self, "_on_search_complete")
	
func _on_match_joined():
	print("match joined")
	ui.reset()
	
func _on_match_rejected():
	print("match rejected")

func _on_search_canceled():
	print("search canceled")
