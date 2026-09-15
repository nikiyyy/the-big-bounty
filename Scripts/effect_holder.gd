class_name EffectHolder
extends RefCounted
## Owns a unit's active effects and computes modified stat values.
## Held by each unit; not a Node, so it costs nothing.

var active: Array = []      # of { effect: Effect, turns_left: int }


func add(effect: Effect) -> void:
	if effect == null:
		return
	# refresh rather than stack the same effect
	for entry in active:
		if entry["effect"].display_name == effect.display_name:
			entry["turns_left"] = effect.duration
			return
	active.append({"effect": effect, "turns_left": effect.duration})


func clear() -> void:
	active.clear()


func has_any() -> bool:
	return not active.is_empty()


## Tick at the start of the owner's turn. Returns the effects that expired.
func advance() -> Array:
	var expired: Array = []
	var kept: Array = []
	for entry in active:
		entry["turns_left"] -= 1
		if entry["turns_left"] <= 0:
			expired.append(entry["effect"])
		else:
			kept.append(entry)
	active = kept
	return expired


## Layer every active effect over a base stat value.
func modify(stat_name: String, base: int) -> int:
	var value: int = base
	for entry in active:
		value = entry["effect"].apply_to(stat_name, value)
	return value


func describe() -> String:
	var parts: Array = []
	for entry in active:
		parts.append("%s (%d)" % [entry["effect"].display_name, entry["turns_left"]])
	return ", ".join(parts) if not parts.is_empty() else "—"
