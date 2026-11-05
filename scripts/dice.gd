class_name Dice
extends RefCounted
## Dadi di DragonQuest [2.6-2.7]: D10 (0 = 10), D100 (00 = 100), D5 = D10/2 per eccesso.

var rng := RandomNumberGenerator.new()


func _init(seme: int = 0) -> void:
	if seme == 0:
		rng.randomize()
	else:
		rng.seed = seme


func d10() -> int:
	return rng.randi_range(1, 10)


func d5() -> int:
	return int(ceil(d10() / 2.0))


func d100() -> int:
	return rng.randi_range(1, 100)


func nd10(n: int) -> int:
	var t := 0
	for i in n:
		t += d10()
	return t


func d10_mod(mod: int) -> int:
	## D10 + modificatore, mai sotto 1 [2.7].
	return max(1, d10() + mod)
