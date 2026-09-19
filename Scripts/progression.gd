class_name Progression
extends RefCounted
## XP thresholds and level-up rules. The one place the curve is defined.

const MAX_LEVEL := 50
const BASE_XP := 100        ## XP needed for level 2
const GROWTH := 1.18        ## each level costs this much more than the last
const POINTS_PER_LEVEL := 1


## Total XP needed to reach a level from zero.
static func total_for_level(level: int) -> int:
	if level <= 1:
		return 0
	var total: float = 0.0
	var step: float = BASE_XP
	for _i in range(1, mini(level, MAX_LEVEL)):
		total += step
		step *= GROWTH
	return int(total)


## The level a given total XP earns.
static func level_for_xp(xp: int) -> int:
	var level: int = 1
	while level < MAX_LEVEL and xp >= total_for_level(level + 1):
		level += 1
	return level


## XP still needed for the next level, and how far through this one we are.
static func progress(xp: int) -> Dictionary:
	var level: int = level_for_xp(xp)
	if level >= MAX_LEVEL:
		return {"level": level, "into": 0, "needed": 0, "ratio": 1.0, "maxed": true}

	var floor_xp: int = total_for_level(level)
	var ceil_xp: int = total_for_level(level + 1)
	var into: int = xp - floor_xp
	var span: int = maxi(1, ceil_xp - floor_xp)

	return {
		"level": level,
		"into": into,
		"needed": span,
		"ratio": clampf(float(into) / float(span), 0.0, 1.0),
		"maxed": false,
	}
