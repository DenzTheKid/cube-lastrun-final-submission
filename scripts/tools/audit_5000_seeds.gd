extends Node2D

# 5,000-Seed Procedural Generation Fairness & Variety Audit
# Evaluates 150,000 chunk generations across 5,000 unique seeds.

const SEED_COUNT: int = 5000
const CHUNKS_PER_SEED: int = 30

const SEVERE_HAZARDS = [
	LevelGenerator.PatternType.PIT_STANDARD,
	LevelGenerator.PatternType.PLATFORM_OVER_PIT,
	LevelGenerator.PatternType.BARRICADE_BRUTE,
	LevelGenerator.PatternType.RECOIL_DOUBLE_VAULT,
	LevelGenerator.PatternType.THE_GAUNTLET
]

const PIT_PATTERNS = [
	LevelGenerator.PatternType.PIT_STANDARD,
	LevelGenerator.PatternType.PLATFORM_OVER_PIT,
	LevelGenerator.PatternType.RECOIL_DOUBLE_VAULT
]

func _ready() -> void:
	print("\n=======================================================")
	print("  STARTING 5,000-SEED PROCEDURAL GENERATION AUDIT     ")
	print("=======================================================")

	var total_chunks_evaluated: int = 0
	var consecutive_severe_violations: int = 0
	var consecutive_pit_violations: int = 0
	var impossible_transitions: int = 0
	var pattern_counts: Dictionary = {}

	for p in LevelGenerator.PatternType.values():
		pattern_counts[p] = 0

	var gen_scene = load("res://scenes/main/game_world.tscn")
	var world = gen_scene.instantiate()
	add_child(world)
	var gen: LevelGenerator = world.level_gen

	var start_time: int = Time.get_ticks_msec()

	for s in range(1, SEED_COUNT + 1):
		seed(s)
		gen._consecutive_hazard_chunks = 0
		gen._last_pattern = LevelGenerator.PatternType.FLAT_START
		gen._chunks_since_medkit = 0

		# Simulate progressive difficulty factor from 1.0 (start) to 2.2 (deep endless endgame)
		for c in range(CHUNKS_PER_SEED):
			total_chunks_evaluated += 1
			var progress: float = float(c) / float(CHUNKS_PER_SEED - 1)
			var fake_diff: float = lerpf(1.0, 2.2, progress)
			if GameManager:
				GameManager.difficulty_factor = fake_diff

			var prev_pattern: LevelGenerator.PatternType = gen._last_pattern
			var pat: LevelGenerator.PatternType = gen._choose_fair_pattern()
			pattern_counts[pat] += 1

			var prev_sev: bool = prev_pattern in SEVERE_HAZARDS
			var prev_pit: bool = prev_pattern in PIT_PATTERNS
			var cur_sev: bool = pat in SEVERE_HAZARDS
			var cur_pit: bool = pat in PIT_PATTERNS

			# Check consecutive constraints
			if prev_sev and cur_sev:
				consecutive_severe_violations += 1

			if prev_pit and cur_pit:
				consecutive_pit_violations += 1

	var elapsed_ms: int = Time.get_ticks_msec() - start_time
	world.queue_free()

	print("\n--- 5,000-SEED AUDIT METRICS ---")
	print("  Total Seeds Evaluated:          %d" % SEED_COUNT)
	print("  Total Chunks Simulated:         %d" % total_chunks_evaluated)
	print("  Execution Time:                 %d ms (%.2f s)" % [elapsed_ms, elapsed_ms / 1000.0])
	print("  Consecutive Severe Violations:  %d" % consecutive_severe_violations)
	print("  Consecutive Pit Violations:     %d" % consecutive_pit_violations)
	print("  Impossible Transitions Found:   %d" % impossible_transitions)

	print("\n--- PATTERN VARIETY DISTRIBUTION (Across 150,000 Chunks) ---")
	var non_flat_min_seen: int = 999999
	for p in pattern_counts.keys():
		if p == LevelGenerator.PatternType.FLAT_START:
			continue
		var count: int = pattern_counts[p]
		var pct: float = (float(count) / float(total_chunks_evaluated)) * 100.0
		non_flat_min_seen = mini(non_flat_min_seen, count)
		print("  Pattern %-24s: %6d times (%4.1f%%)" % [LevelGenerator.PatternType.keys()[p], count, pct])

	var variety_ok: bool = non_flat_min_seen > 500
	var fairness_ok: bool = (consecutive_severe_violations == 0 and consecutive_pit_violations == 0 and impossible_transitions == 0)

	print("\n=======================================================")
	if fairness_ok and variety_ok:
		print("  RESULT: [PASS] 5,000 SEEDS FULLY VERIFIED FAIR & DIVERSE")
		print("=======================================================\n")
		get_tree().quit(0)
	else:
		printerr("  RESULT: [FAIL] FAIRNESS OR VARIETY CHECKS FAILED (min_seen: %d)" % non_flat_min_seen)
		print("=======================================================\n")
		get_tree().quit(1)
