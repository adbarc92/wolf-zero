extends Node
## Global event bus for decoupled communication between game systems
##
## Usage: GameEvents.player_damaged.emit(damage, current_health)
## Usage: GameEvents.player_damaged.connect(_on_player_damaged)

# =============================================================================
# PLAYER EVENTS
# =============================================================================

signal player_spawned(entity_id: int)
signal player_damaged(damage: int, current_health: int)
signal player_died()
signal player_respawned()
signal player_healed(amount: int, current_health: int)

# =============================================================================
# COMBAT EVENTS
# =============================================================================

signal attack_performed(entity_id: int, attack_type: String)
signal combo_hit(entity_id: int, combo_count: int)
signal parry_success(entity_id: int)
signal enemy_damaged(entity_id: int, damage: int)
signal enemy_killed(entity_id: int, enemy_type: String)

# =============================================================================
# MOMENTUM EVENTS
# =============================================================================

signal momentum_changed(current: float, max_value: float, percent: float)
signal momentum_threshold_echo_reached()
signal momentum_threshold_damage_reached()
signal momentum_threshold_duration_reached()
signal momentum_threshold_ultimate_reached()
signal momentum_threshold_lost(threshold_name: String)

# =============================================================================
# ECHO EVENTS
# =============================================================================

signal echo_ready()
signal echo_not_ready()
signal echo_activated()
signal echo_ended()
signal echo_cooldown_updated(remaining: float, total: float)

# =============================================================================
# MOVEMENT EVENTS
# =============================================================================

signal player_jumped()
signal player_wall_jumped(direction: int)
signal player_double_jumped()
signal player_dashed()
signal player_landed()

# =============================================================================
# GAME STATE EVENTS
# =============================================================================

signal game_started()
signal game_paused()
signal game_resumed()
signal game_over()

signal mission_started(mission_id: int)
signal mission_completed(mission_id: int, stats: Dictionary)
signal mission_failed(mission_id: int)

signal checkpoint_reached(checkpoint_id: int)
signal checkpoint_loaded(checkpoint_id: int)

# =============================================================================
# UI EVENTS
# =============================================================================

signal ui_show_damage_number(position: Vector2, damage: int, is_critical: bool)
signal ui_show_message(text: String, duration: float)
signal ui_update_health(current: int, max_hp: int)
signal ui_update_momentum(current: float, max_val: float)
signal ui_update_echo_cooldown(remaining: float, total: float)

# =============================================================================
# LEVEL EVENTS
# =============================================================================

signal level_loaded(level_name: String)
signal level_unloaded()
signal door_opened(door_id: int)
signal switch_activated(switch_id: int)
signal hazard_triggered(hazard_id: int, entity_id: int)
