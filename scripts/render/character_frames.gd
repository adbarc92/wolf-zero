class_name CharacterFrames
extends RefCounted
## Data-driven SpriteFrames builders for the player and enemy characters.
##
## Ported verbatim from main.gd::_build_player_frames()/_build_enemy_frames().
## The animation set (names, source PNGs, fps, loop flags) is encoded in the
## PLAYER / ENEMY data tables below, so a future sprite swap is a one-file edit:
## change the BASE path consts and/or the per-row file names.
##
## Each table row is: [anim_name: String, file: String, fps: float, loop: bool]
## The full source path for a row is BASE + file.

## FreeKnight Colour1 (player) strip directory.
const FK := "res://assets/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/"
## FreeKnight Colour2 (enemy) strip directory.
const FK2 := "res://assets/FreeKnight_v1/Colour2/NoOutline/120x80_PNGSheets/"

## All FreeKnight strips are 120x80 frames laid left-to-right.
const FRAME_W := 120
const FRAME_H := 80

## Player animation table: [anim, file, fps, loop]
const PLAYER := [
	["idle", "_Idle.png", 10.0, true],
	["run", "_Run.png", 14.0, true],
	["jump", "_Jump.png", 10.0, false],
	["fall", "_Fall.png", 10.0, false],
	["dash", "_Dash.png", 14.0, false],
	["roll", "_Roll.png", 14.0, false],
	["slide", "_Slide.png", 14.0, false],
	["light_1", "_Attack.png", 16.0, false],
	["light_2", "_Attack2.png", 16.0, false],
	["light_3", "_AttackCombo.png", 16.0, false],
	["light_4", "_AttackCombo.png", 16.0, false],
	["light_5", "_AttackCombo.png", 16.0, false],
	["hit", "_Hit.png", 12.0, false],
	["crouch", "_Crouch.png", 8.0, true],
	["crouch_walk", "_CrouchWalk.png", 12.0, true],
	["wall_slide", "_WallSlide.png", 10.0, true],
	["wall_climb", "_WallClimb.png", 12.0, true],
	["death", "_Death.png", 10.0, false],
	["jump_fall_inbetween", "_JumpFallInbetween.png", 10.0, false],
	["turn_around", "_TurnAround.png", 14.0, false],
	["crouch_transition", "_CrouchTransition.png", 14.0, false],
	["crouch_attack", "_CrouchAttack.png", 14.0, false],
	["light_1_nomove", "_AttackNoMovement.png", 16.0, false],
	["light_2_nomove", "_Attack2NoMovement.png", 16.0, false],
	["light_3_nomove", "_AttackComboNoMovement.png", 16.0, false],
	["light_4_nomove", "_AttackComboNoMovement.png", 16.0, false],
	["light_5_nomove", "_AttackComboNoMovement.png", 16.0, false],
]

## Enemy animation table: [anim, file, fps, loop]
const ENEMY := [
	["idle", "_Idle.png", 10.0, true],
	["run", "_Run.png", 12.0, true],
	["light_1", "_Attack.png", 14.0, false],
	["slide", "_Slide.png", 14.0, false],
	["hit", "_Hit.png", 12.0, false],
	["wall_slide", "_WallSlide.png", 10.0, true],
	["wall_climb", "_WallClimb.png", 12.0, true],
	["death", "_Death.png", 10.0, false],
	["jump_fall_inbetween", "_JumpFallInbetween.png", 10.0, false],
	["turn_around", "_TurnAround.png", 14.0, false],
	["crouch_transition", "_CrouchTransition.png", 14.0, false],
	["crouch_attack", "_CrouchAttack.png", 14.0, false],
	["light_1_nomove", "_AttackNoMovement.png", 16.0, false],
	["light_2_nomove", "_Attack2NoMovement.png", 16.0, false],
	["light_3_nomove", "_AttackComboNoMovement.png", 16.0, false],
	["light_4_nomove", "_AttackComboNoMovement.png", 16.0, false],
	["light_5_nomove", "_AttackComboNoMovement.png", 16.0, false],
]


## Build the player SpriteFrames (FreeKnight Colour1).
static func player() -> SpriteFrames:
	return _build(FK, PLAYER)


## Build the enemy SpriteFrames (FreeKnight Colour2).
static func enemy() -> SpriteFrames:
	return _build(FK2, ENEMY)


## Build a SpriteFrames from a base path and a [anim, file, fps, loop] table.
static func _build(base: String, table: Array) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for row in table:
		var anim: String = row[0]
		var file: String = row[1]
		var fps: float = row[2]
		var loop: bool = row[3]
		SpriteFramesBuilder.add_strip(sf, anim, load(base + file), FRAME_W, FRAME_H, fps, loop)
	return sf
