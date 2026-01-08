extends Node
## Global game state manager
##
## Tracks current game state, mission progress, player stats, and save data.

# =============================================================================
# ENUMS
# =============================================================================

enum State {
	MENU,
	PLAYING,
	PAUSED,
	CUTSCENE,
	GAME_OVER,
	LOADING,
}

# =============================================================================
# SIGNALS
# =============================================================================

signal state_changed(new_state: State, old_state: State)

# =============================================================================
# STATE
# =============================================================================

var current_state: State = State.MENU:
	set(value):
		if value != current_state:
			var old = current_state
			current_state = value
			state_changed.emit(current_state, old)

## Current mission being played
var current_mission: int = -1

## Current checkpoint in mission
var current_checkpoint: int = 0

## Player entity ID (set by player spawner)
var player_entity_id: int = -1

## Is this a solo game or co-op
var is_solo: bool = true

# =============================================================================
# PLAYER PROGRESSION (Saved)
# =============================================================================

var player_data: Dictionary = {
	"level": 1,
	"xp": 0,
	"xp_to_next": 100,
	"skill_points": 0,

	# Currency
	"neon_yen": 0,
	"echo_fragments": 0,
	"legacy_tokens": 0,

	# Unlocked abilities
	"has_dash": false,
	"has_grapple": false,
	"has_air_dash": false,

	# Echo upgrades
	"echo_record_time": 3.0,
	"echo_cooldown": 8.0,
	"echo_duration": 3.0,
	"echo_solid": false,
	"echo_dual": false,

	# Unlocked weapons
	"weapons": ["plasma_katana"],
	"equipped_weapon": "plasma_katana",

	# Weapon upgrades: weapon_name -> tier (1-5)
	"weapon_tiers": {
		"plasma_katana": 1,
	},

	# Skills: skill_id -> unlocked
	"skills_blade": {},
	"skills_shadow": {},
	"skills_echo": {},
}

## Mission progress: mission_id -> completion data
var mission_progress: Dictionary = {}

## Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"haptic_feedback": true,
	"gesture_sensitivity": 1.0,
	"control_scheme": "gesture",  # "gesture" or "buttons"
	"colorblind_mode": "none",  # "none", "protanopia", "deuteranopia", "tritanopia"
	"screen_shake": true,
}

# =============================================================================
# SAVE/LOAD
# =============================================================================

const SAVE_PATH = "user://save_data.json"


func save_game() -> void:
	var save_data = {
		"player_data": player_data,
		"mission_progress": mission_progress,
		"settings": settings,
		"current_mission": current_mission,
		"current_checkpoint": current_checkpoint,
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved successfully")
	else:
		push_error("Failed to save game: " + str(FileAccess.get_open_error()))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false

	var save_data = json.get_data()

	if save_data.has("player_data"):
		_merge_dict(player_data, save_data.player_data)
	if save_data.has("mission_progress"):
		mission_progress = save_data.mission_progress
	if save_data.has("settings"):
		_merge_dict(settings, save_data.settings)
	if save_data.has("current_mission"):
		current_mission = save_data.current_mission
	if save_data.has("current_checkpoint"):
		current_checkpoint = save_data.current_checkpoint

	print("Game loaded successfully")
	return true


func _merge_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key):
			target[key] = source[key]


# =============================================================================
# PROGRESSION
# =============================================================================

func add_xp(amount: int) -> void:
	player_data.xp += amount

	while player_data.xp >= player_data.xp_to_next and player_data.level < 30:
		player_data.xp -= player_data.xp_to_next
		player_data.level += 1
		player_data.skill_points += 1
		player_data.xp_to_next = _calculate_xp_to_next(player_data.level)
		GameEvents.ui_show_message.emit("Level Up! Lv.%d" % player_data.level, 2.0)


func _calculate_xp_to_next(level: int) -> int:
	# XP curve: each level needs more XP
	return 100 + (level * 50)


func add_currency(currency_type: String, amount: int) -> void:
	match currency_type:
		"neon_yen":
			player_data.neon_yen += amount
		"echo_fragments":
			player_data.echo_fragments += amount
		"legacy_tokens":
			player_data.legacy_tokens += amount


func unlock_ability(ability: String) -> void:
	match ability:
		"dash":
			player_data.has_dash = true
		"grapple":
			player_data.has_grapple = true
		"air_dash":
			player_data.has_air_dash = true


func unlock_weapon(weapon_id: String) -> void:
	if weapon_id not in player_data.weapons:
		player_data.weapons.append(weapon_id)
		player_data.weapon_tiers[weapon_id] = 1


func upgrade_weapon(weapon_id: String) -> bool:
	if weapon_id not in player_data.weapon_tiers:
		return false
	if player_data.weapon_tiers[weapon_id] >= 5:
		return false

	player_data.weapon_tiers[weapon_id] += 1
	return true


func complete_mission(mission_id: int, stats: Dictionary) -> void:
	mission_progress[str(mission_id)] = {
		"completed": true,
		"best_time": stats.get("time", 0),
		"best_score": stats.get("score", 0),
		"rank": stats.get("rank", "C"),
	}

	# Unlock next mission
	if mission_id < 12:
		if not mission_progress.has(str(mission_id + 1)):
			mission_progress[str(mission_id + 1)] = { "unlocked": true }

	save_game()


func is_mission_unlocked(mission_id: int) -> bool:
	if mission_id == 1:
		return true
	return mission_progress.get(str(mission_id), {}).get("unlocked", false) or \
		   mission_progress.get(str(mission_id), {}).get("completed", false)


# =============================================================================
# GAME FLOW
# =============================================================================

func start_mission(mission_id: int) -> void:
	current_mission = mission_id
	current_checkpoint = 0
	current_state = State.PLAYING
	GameEvents.mission_started.emit(mission_id)


func pause_game() -> void:
	if current_state == State.PLAYING:
		current_state = State.PAUSED
		get_tree().paused = true
		GameEvents.game_paused.emit()


func resume_game() -> void:
	if current_state == State.PAUSED:
		current_state = State.PLAYING
		get_tree().paused = false
		GameEvents.game_resumed.emit()


func return_to_menu() -> void:
	get_tree().paused = false
	current_state = State.MENU
	current_mission = -1
	# Load menu scene


func _ready() -> void:
	load_game()
