class_name CharacterFrames
extends RefCounted
## Data-driven SpriteFrames builders for the player, enemy and boss characters.
##
## Art: Mattz Art "Samurai" 2D pixel-art bundle (see assets/samurai/LICENSE.txt).
##   player -> FULL Samurai      (96x96 frames)
##   enemy  -> Samurai #2         (96x64 frames)
##   boss   -> Demon Samurai      (128x108 frames)
## Every sheet is a single-row horizontal strip (one PNG per animation), so
## SpriteFramesBuilder.add_strip slices them directly — no grid extractor needed.
##
## The animation set (names, source PNGs, fps, loop flags) is encoded in the
## PLAYER / ENEMY / BOSS tables below, so a future sprite swap (e.g. the neon
## recolor) is a one-file edit: change a BASE path const and/or the per-row files.
##
## Each table row is: [anim_name: String, file: String, fps: float, loop: bool]
## The full source path for a row is BASE + file. Rows may point at the same file
## to ALIAS a clip the source art lacks (e.g. roll -> dash) — AnimationSystem only
## plays clips the SpriteFrames actually has, so every clip derive_clip can emit
## must be present (real or aliased) to avoid a missing-clip last-frame hold.

## Mattz Art samurai strip directories.
const PLAYER_BASE := "res://assets/samurai/player/"
const ENEMY_BASE := "res://assets/samurai/enemy/"
const BOSS_BASE := "res://assets/samurai/boss/"

## Per-character frame size (single-row strips, height = sheet height).
const PLAYER_W := 96
const PLAYER_H := 96
const ENEMY_W := 96
const ENEMY_H := 64
const BOSS_W := 128
const BOSS_H := 108

## Player animation table: [anim, file, fps, loop]. (FULL Samurai)
## Aliases: roll/slide -> dash; crouch -> idle; crouch_walk -> run;
## crouch_attack -> attack1; crouch_transition/turn_around -> idle; light_4 -> attack3.
const PLAYER := [
	["idle", "idle.png", 10.0, true],
	["run", "run.png", 14.0, true],
	["jump", "jump.png", 10.0, false],
	["fall", "jump_fall.png", 10.0, false],
	["jump_fall_inbetween", "jump_transition.png", 10.0, false],
	["dash", "dash.png", 14.0, false],
	["roll", "dash.png", 14.0, false],
	["slide", "dash.png", 14.0, false],
	["hit", "hurt.png", 12.0, false],
	["crouch", "idle.png", 8.0, true],
	["crouch_walk", "run.png", 12.0, true],
	["crouch_attack", "attack1.png", 16.0, false],
	["crouch_transition", "idle.png", 14.0, false],
	["wall_slide", "wall_slide.png", 10.0, true],
	["wall_climb", "climbing.png", 12.0, true],
	["turn_around", "idle.png", 14.0, false],
	["death", "death.png", 10.0, false],
	["light_1", "attack1.png", 16.0, false],
	["light_2", "attack2.png", 16.0, false],
	["light_3", "attack3.png", 16.0, false],
	["light_4", "attack3.png", 16.0, false],
	["light_5", "special.png", 16.0, false],
	["light_1_nomove", "attack1.png", 16.0, false],
	["light_2_nomove", "attack2.png", 16.0, false],
	["light_3_nomove", "attack3.png", 16.0, false],
	["light_4_nomove", "attack3.png", 16.0, false],
	["light_5_nomove", "special.png", 16.0, false],
]

## Enemy animation table: [anim, file, fps, loop]. (Samurai #2)
## Aliases: slide -> dash; wall_slide/wall_climb/turn_around/crouch_transition -> idle;
## jump_fall_inbetween -> jump; crouch_attack/light_1_nomove -> attack1.
const ENEMY := [
	["idle", "idle.png", 10.0, true],
	["run", "run.png", 12.0, true],
	["light_1", "attack1.png", 14.0, false],
	["slide", "dash.png", 14.0, false],
	["hit", "hurt.png", 12.0, false],
	["wall_slide", "idle.png", 10.0, true],
	["wall_climb", "idle.png", 12.0, true],
	["death", "death.png", 10.0, false],
	["jump_fall_inbetween", "jump.png", 10.0, false],
	["turn_around", "idle.png", 14.0, false],
	["crouch_transition", "idle.png", 14.0, false],
	["crouch_attack", "attack1.png", 14.0, false],
	["light_1_nomove", "attack1.png", 16.0, false],
	["light_2_nomove", "attack2.png", 16.0, false],
	["light_3_nomove", "attack3.png", 16.0, false],
	["light_4_nomove", "attack3.png", 16.0, false],
	["light_5_nomove", "attack3.png", 16.0, false],
]

## Boss animation table: [anim, file, fps, loop]. (Demon / Wolf Samurai)
## Covers the full clip set derive_clip can emit. The boss is grounded, so the
## airborne/wall/crouch clips alias to idle/run/defend; light_5 -> jump_attack.
const BOSS := [
	["idle", "idle.png", 8.0, true],
	["run", "run.png", 10.0, true],
	["jump", "idle.png", 10.0, false],
	["fall", "idle.png", 10.0, false],
	["jump_fall_inbetween", "idle.png", 10.0, false],
	["dash", "run.png", 12.0, false],
	["roll", "run.png", 12.0, false],
	["slide", "run.png", 12.0, false],
	["hit", "hurt.png", 12.0, false],
	["crouch", "defend.png", 8.0, true],
	["crouch_walk", "run.png", 10.0, true],
	["crouch_attack", "attack1.png", 14.0, false],
	["crouch_transition", "defend.png", 12.0, false],
	["wall_slide", "idle.png", 10.0, true],
	["wall_climb", "idle.png", 10.0, true],
	["turn_around", "idle.png", 12.0, false],
	["death", "death.png", 10.0, false],
	["light_1", "attack1.png", 14.0, false],
	["light_2", "attack2.png", 14.0, false],
	["light_3", "attack3.png", 14.0, false],
	["light_4", "attack3.png", 14.0, false],
	["light_5", "jump_attack.png", 14.0, false],
	["light_1_nomove", "attack1.png", 14.0, false],
	["light_2_nomove", "attack2.png", 14.0, false],
	["light_3_nomove", "attack3.png", 14.0, false],
	["light_4_nomove", "attack3.png", 14.0, false],
	["light_5_nomove", "jump_attack.png", 14.0, false],
]


## Build the player SpriteFrames (FULL Samurai).
static func player() -> SpriteFrames:
	return _build(PLAYER_BASE, PLAYER, PLAYER_W, PLAYER_H)


## Build the enemy SpriteFrames (Samurai #2).
static func enemy() -> SpriteFrames:
	return _build(ENEMY_BASE, ENEMY, ENEMY_W, ENEMY_H)


## Build the boss SpriteFrames (Demon / Wolf Samurai) — a distinct sheet, not a
## tinted enemy reuse. main.gd assigns this via the "boss" frame_set.
static func boss() -> SpriteFrames:
	return _build(BOSS_BASE, BOSS, BOSS_W, BOSS_H)


## Build a SpriteFrames from a base path, a [anim, file, fps, loop] table and a
## per-character frame size.
static func _build(base: String, table: Array, frame_w: int, frame_h: int) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for row in table:
		var anim: String = row[0]
		var file: String = row[1]
		var fps: float = row[2]
		var loop: bool = row[3]
		SpriteFramesBuilder.add_strip(sf, anim, load(base + file), frame_w, frame_h, fps, loop)
	return sf
