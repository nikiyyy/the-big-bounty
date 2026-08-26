class_name CombatAI
extends Resource
## Base combat brain. Subclass this per enemy type and override plan_move.
## Assign an instance in the Inspector on each NPC.

## How close this unit wants to end up. 1 = melee range.
@export var preferred_distance: int = 1


## Given the field and both positions, return the hex to end the turn on.
## Default behaviour: close the gap greedily, one step at a time.
func plan_move(field, from_hex: Vector2i, target_hex: Vector2i, movement: int) -> Vector2i:
	if field.hex_distance(from_hex, target_hex) <= preferred_distance:
		return from_hex

	# the target's own hex is occupied, so aim for the nearest free tile beside it
	var goal: Vector2i = from_hex
	var best: int = 1 << 30
	for n in field.hex_neighbors(target_hex):
		if field.is_occupied(n):
			continue
		var d: int = field.hex_distance(from_hex, n)
		if d < best:
			best = d
			goal = n
	if goal == from_hex:
		return from_hex

	var path: Array = field.find_path(from_hex, goal)
	if path.is_empty():
		return from_hex

	# walk the path only as far as the movement budget actually stretches
	var spent: int = 0
	var reached: Vector2i = from_hex
	for h in path:
		var step_cost: int = field.move_cost(h)
		if spent + step_cost > movement:
			break
		spent += step_cost
		reached = h
	return reached
