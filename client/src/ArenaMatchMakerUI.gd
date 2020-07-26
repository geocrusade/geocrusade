extends Control

onready var FindPanel : Panel = $FindPanel
onready var Find1v1 : Button = $FindPanel/Find1v1
onready var Find2v2 : Button = $FindPanel/Find2v2
onready var Find3v3 : Button = $FindPanel/Find3v3

onready var SearchingPanel : Panel = $SearchingPanel
onready var CancelSearch : Button = $SearchingPanel/Cancel

onready var TimeRemaining : Label = $MatchFoundPanel/TimeRemaining
onready var CancelMatch : Button = $MatchFoundPanel/Cancel
onready var JoinMatch : Button =  $MatchFoundPanel/Join

var _match_team_size : int  = 2
var _seconds_remaining_to_enter_match = 0

func _ready() -> void:
	MatchController.connect("arena_match_search_started", self, "_on_search_started")
	MatchController.connect("arena_match_search_failed", self, "_on_search_failed")
	MatchController.connect("arena_match_search_canceled", self, "_on_search_canceled")
	MatchController.connect("arena_match_found", self, "_on_match_found")
	MatchController.connect("arena_match_joined", self, "_on_match_joined")
	MatchController.connect("arena_match_join_failed", self, "_on_match_join_failed")
	Find1v1.connect("button_up", self, "_search_for_arena_match", [ 1 ])
	Find2v2.connect("button_up", self, "_search_for_arena_match", [ 2 ])
	Find3v3.connect("button_up", self, "_search_for_arena_match", [ 3 ])
	CancelSearch.connect("button_up", self, "_cancel_search")
	CancelMatch.connect("button_up", self, "_cancel_found_match")
	JoinMatch.connect("button_up", self, "_join_match")
	
func _search_for_arena_match(team_size: int) -> void:
	_match_team_size = team_size
	MatchController.search_for_arena_match(team_size)
	Find1v1.disabled = true
	Find2v2.disabled = true
	Find3v3.disabled = true

func _on_search_started() -> void:
	FindPanel.hide()
	SearchingPanel.show()
	$SearchingPanel/MatchType.text = String(_match_team_size) + "v" + String(_match_team_size)

func _on_search_failed() -> void:
	FindPanel.show()
	Find1v1.disabled = false
	Find2v2.disabled = false
	Find3v3.disabled = false
	SearchingPanel.hide()
	$FindPanel/Title.text = "Failed. Try again."

func _on_search_canceled() -> void:
	FindPanel.show()
	SearchingPanel.hide()

func _cancel_search() -> void:
	MatchController.cancel_search_for_arena_match()

func _on_match_found(seconds_until_expire : float) -> void:
	_seconds_remaining_to_enter_match = seconds_until_expire
	$MatchFoundPanel/Timer.connect("timeout", self, "_after_each_second")
	SearchingPanel.hide()
	$MatchFoundPanel.show()
	
func _join_match() -> void:
	$MatchFoundPanel/Join.disabled = true
	$MatchFoundPanel/Cancel.disabled = true
	MatchController.join_arena_match()

func _on_match_joined() -> void:
	hide()
	_reset()

func _on_match_join_failed() -> void:
	$MatchFoundPanel/Join.disabled = false
	$MatchFoundPanel/Cancel.disabled = false
	$MatchFoundPanel/Title.text = "Failed. Try again."

func _cancel_found_match() -> void:
	MatchController.cancel_search_for_arena_match()
	_reset()

func _after_each_second() -> void:
	_seconds_remaining_to_enter_match = _seconds_remaining_to_enter_match - 1
	TimeRemaining.text = String(_seconds_remaining_to_enter_match)
	if _seconds_remaining_to_enter_match == 0:
		_reset()
	
func _reset() -> void:
	$MatchFoundPanel/Timer.disconnect("timeout", self, "_after_each_second")
	$MatchFoundPanel.hide()
	SearchingPanel.hide()
	FindPanel.show()
	
