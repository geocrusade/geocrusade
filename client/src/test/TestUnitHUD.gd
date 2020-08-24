extends Control

onready var hud = $UnitHUD

var _health = 0
var _power = 0
var _cast = 0
var _effects = {
	0: {
		stacks = 0,
		duration = 3,
		color = Color.green
	},
	1: {
		stacks = 0,
		duration = 2,
		color = Color.blue
	},
	2: {
		stacks = 0,
		duration = 5,
		color = Color.pink
	}
}

func _process(delta):
	hud.set_health(_health)
	hud.set_power(_power)
	hud.set_cast(_cast, 3, "fire")
	hud.set_name("GiantSlayer")
	
	_health += 1
	_power += 1
	_cast += delta
	if _health >= 100:
		_health = 0
	if _power >= 100:
		_power = 0
	if _cast >= 3:
		_cast = 0
	
	for code in _effects:
		var effect = _effects[code]
		effect.duration = effect.duration - delta
		effect.stacks = fmod(effect.stacks + 1, 4)
		hud.set_effect(code, effect.color, effect.duration, effect.stacks)
		if round(effect.duration) == 0:
			hud.remove_effect(code)
			_effects.erase(code)

