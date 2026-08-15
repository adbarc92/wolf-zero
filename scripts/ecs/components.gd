class_name Components
extends RefCounted
## Component factory and definitions for Wolf-Zero
##
## Components are pure data containers. Each static function returns a
## dictionary with default values that can be customized.

# =============================================================================
# CORE COMPONENTS
# =============================================================================

## Position in world space
static func position(x: float = 0.0, y: float = 0.0) -> Dictionary:
	return {
		"x": x,
		"y": y,
		"previous_x": x,
		"previous_y": y,
	}


## Velocity for movement
static func velocity(vx: float = 0.0, vy: float = 0.0) -> Dictionary:
	return {
		"x": vx,
		"y": vy,
		"max_speed": 400.0,
		"acceleration": 2000.0,
		"friction": 1500.0,
	}


## Sprite/visual representation
static func sprite(texture_path: String = "", flip_h: bool = false) -> Dictionary:
	return {
		"texture_path": texture_path,
		"flip_h": flip_h,
		"animation": "idle",
		"frame": 0,
		"visible": true,
		"modulate": Color.WHITE,
		"frame_set": "player",
		"z_index": 0,
	}


## Collision data
static func collision(width: float = 32.0, height: float = 64.0) -> Dictionary:
	return {
		"width": width,
		"height": height,
		"offset_x": 0.0,
		"offset_y": 0.0,
		"layer": 1,
		"mask": 1,
		"on_ground": false,
		"on_wall": false,
		"on_ceiling": false,
		"wall_direction": 0,  # -1 left, 0 none, 1 right
	}


# =============================================================================
# COMBAT COMPONENTS
# =============================================================================

## Health and damage
static func health(max_hp: int = 100) -> Dictionary:
	return {
		"current": max_hp,
		"max": max_hp,
		"invincible": false,
		"invincibility_timer": 0.0,
		"invincibility_duration": 0.5,
		"hurt_timer": 0.0,
	}


## Weapon data
static func weapon(damage: int = 10, attack_speed: float = 0.3) -> Dictionary:
	return {
		"damage": damage,
		"attack_speed": attack_speed,  # Time between attacks
		"combo_max": 5,
		"combo_current": 0,
		"combo_timer": 0.0,
		"combo_window": 0.8,  # Time to continue combo
		"attack_timer": 0.0,
		"is_attacking": false,
		"attack_type": "none",  # "light", "heavy_up", "heavy_forward", "heavy_down"
		"hitbox_active": false,
		"unblockable": false,
	}


## Projectile (kinematic, travels in a direction until it hits or expires)
static func projectile(damage: int = 8, speed: float = 600.0, team: String = "enemy") -> Dictionary:
	return {
		"damage": damage,
		"speed": speed,
		"direction": 1,
		"team": team,
		"lifetime": 3.0,
		"elapsed": 0.0,
		"radius": 16.0,
	}


## Momentum gauge: composure, carried by every combatant.
##
## Blocking spends it, parries and landed attacks build it, and zero is Broken.
## These defaults are the player's shape: the bar starts EMPTY and idle-decays,
## so the opening of a fight has to be offensive because aggression is what funds
## the ability to defend. Enemies use `enemy_momentum()` instead.
static func momentum(max_value: float = 100.0) -> Dictionary:
	return {
		"current": 0.0,
		"max": max_value,
		"decay_rate": 5.0,  # Per second when not in combat
		"decay_delay": 2.0,  # Seconds before decay starts
		"decay_timer": 0.0,
		"gain_attack": 5.0,
		"gain_parry": 15.0,
		# Momentum torn off an attacker whose blow this entity parries. 34 of 100
		# means three parries Break any enemy, or end any one boss phase.
		"parry_drain": 34.0,
		# Filling the bar banks a Charge and drops back to here, never to zero,
		# so the best play does not leave the player defenceless.
		"bank_floor": 40.0,
		"charges": 0,
		"charges_max": 3,
		# Broken: spent down to zero. Staggered, unable to act, and open to a
		# Deathblow until the timer expires and the bar recovers to bank_floor.
		"broken": false,
		"broken_timer": 0.0,
		"broken_duration": 2.0,
	}


## An enemy's Momentum: full at spawn, no idle decay, and recovering to full.
##
## Only the player's parries move it, so Breaking something is always the
## player's doing rather than something that happens by standing still.
static func enemy_momentum(max_value: float = 100.0) -> Dictionary:
	var data := momentum(max_value)
	data.current = max_value
	data.decay_rate = 0.0
	data.bank_floor = max_value
	data.broken_duration = 2.5  # A slightly wider opening to land the Deathblow
	return data


# =============================================================================
# ECHO COMPONENTS
# =============================================================================

## Holographic Echo data. Deploying an Echo costs one Charge — that is its only
## cost and its only gate, so there is no cooldown and no momentum threshold here.
static func echo_data() -> Dictionary:
	return {
		"recording": [],  # Array of recorded frames
		"max_record_time": 3.0,  # Seconds to record
		"is_recording": true,
	}


## Active Echo instance (for the spawned echo entity)
static func echo_instance() -> Dictionary:
	return {
		"playback_index": 0,
		"playback_timer": 0.0,
		"duration": 3.0,
		"elapsed": 0.0,
		"owner_entity": -1,
		"recorded_actions": [],
	}


# =============================================================================
# MOVEMENT COMPONENTS
# =============================================================================

## Player input state
static func input_state() -> Dictionary:
	return {
		"move_direction": 0.0,  # -1 to 1
		"jump_pressed": false,
		"jump_just_pressed": false,
		"crouch_pressed": false,
		"attack_light": false,
		"attack_heavy": false,
		"attack_direction": Vector2.ZERO,
		"dodge_pressed": false,
		"dash_pressed": false,
		"parry_pressed": false,
		"parry_held": false,
		"echo_pressed": false,
		"facing": 1,  # 1 right, -1 left
	}


## Platforming abilities
static func platformer(jump_force: float = -600.0) -> Dictionary:
	return {
		"jump_force": jump_force,
		"gravity": 1800.0,
		"max_fall_speed": 1200.0,
		"coyote_time": 0.1,
		"coyote_timer": 0.0,
		"jump_buffer_time": 0.1,
		"jump_buffer_timer": 0.0,
		"jumps_max": 1,
		"jumps_remaining": 1,
		"is_jumping": false,
		"can_wall_jump": true,
		"can_wall_run": true,
		"wall_run_timer": 0.0,
		"wall_run_duration": 0.5,
		# Unlockable abilities
		"has_dash": false,
		"has_grapple": false,
		"has_air_dash": false,
		"dash_cooldown": 0.0,
		# Time re-armed onto dash_cooldown after a dash. The player overrides this
		# to a near-zero value so dash reads as a movement verb, not a resource.
		"dash_cooldown_time": 0.6,
		"dash_duration": 0.2,
		"dash_speed": 800.0,
		"is_dashing": false,
		# Set when a jump leaves the ground mid-dash. While true, MovementSystem
		# preserves the dash's horizontal speed for the arc instead of clamping
		# back to max_speed. Cleared on landing or on steering the other way.
		"dash_jumping": false,
		"is_sliding": false,
		"slide_timer": 0.0,
		"slide_duration": 0.35,
		"slide_speed": 700.0,
	}


## Parry window state
static func parry() -> Dictionary:
	return {
		"is_parrying": false,
		"parry_timer": 0.0,
		"parry_window": 0.2,
		"cooldown": 0.0,
		"cooldown_duration": 0.5,
		"is_blocking": false,
		"block_damage_mult": 0.3,
		# Momentum spent per blocked hit, as a multiple of the raw damage: a block
		# pays for the blow in composure as well as chipping health.
		"block_cost_mult": 1.0,
	}


## Dodge/roll state
static func dodge() -> Dictionary:
	return {
		"is_dodging": false,
		"dodge_timer": 0.0,
		"dodge_duration": 0.3,
		"dodge_speed": 600.0,
		"dodge_cooldown": 0.0,
		"cooldown_duration": 0.5,
		"i_frame_start": 0.05,
		"i_frame_end": 0.25,
	}


# =============================================================================
# AI COMPONENTS
# =============================================================================

## AI behavior
static func ai(behavior_type: String = "patrol") -> Dictionary:
	return {
		"behavior_type": behavior_type,  # "patrol", "chase", "attack", "idle"
		"state": "idle",
		"target_entity": -1,
		"detection_range": 300.0,
		"attack_range": 50.0,
		"patrol_points": [],
		"patrol_index": 0,
		"wait_timer": 0.0,
		"attack_cooldown": 0.0,
		"stagger_timer": 0.0,
		"can_be_distracted": true,  # By Echo
	}


## Boss controller state.
static func boss(boss_name: String = "Crimson Ronin") -> Dictionary:
	return {
		"name": boss_name,
		"is_final": true,
		"kind": "crimson_ronin",
		"phase": 1,
		"state": "intro",
		"state_timer": 1.2,
		"pattern": "",
		"staggered": false,
		"stagger_timer": 0.0,
		"facing": -1,
		"detection_range": 900.0,
	}


## Enemy-specific data
static func enemy(enemy_type: String = "ronin_drone") -> Dictionary:
	return {
		"type": enemy_type,
		"telegraph_time": 0.8,  # Warning before attack
		"telegraph_timer": 0.0,
		"is_telegraphing": false,
		"has_armor": false,
		"armor_hits": 0,
		"facing": 1,
		"is_ranged": false,
		"behavior": "melee",
		"blink_timer": 2.5,
		"cloak_timer": 0.0,
		"support_timer": 3.0,
	}


# =============================================================================
# TAGS (empty components used for filtering)
# =============================================================================

static func tag_player() -> Dictionary:
	return { "is_player": true }


static func tag_enemy() -> Dictionary:
	return { "is_enemy": true }


static func tag_echo() -> Dictionary:
	return { "is_echo": true }


static func tag_projectile() -> Dictionary:
	return { "is_projectile": true }


static func tag_interactable() -> Dictionary:
	return { "is_interactable": true }


static func tag_hazard() -> Dictionary:
	return { "is_hazard": true }


## Marks an entity as dying (plays death anim, then despawns/respawns).
static func dying() -> Dictionary:
	return {"timer": 0.6}
