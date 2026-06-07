# Wolf-Zero — Game Shell / UI Flow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Wrap the slice in a real game shell: **Title → Play → Pause menu → Victory/Defeat → Restart/Title**, with a lives system and a clean level **restart**. Fully autonomous, asset-free (keyboard-driven text screens), headless-verifiable.

**Architecture:** `GameState` gains a `VICTORY` state + a lives counter and pure transition helpers. `ECS.clear_all()` already clears entities (systems stay registered), so **restart rebuilds the level in place** (free spawned nodes + `clear_all()` + reset `main` flags + re-spawn) — never `reload_current_scene()` (that would re-run `_initialize_ecs` and double-register systems). A `ScreenManager` (CanvasLayer, `PROCESS_MODE_ALWAYS` so it works while paused) renders the screen for the current `GameState.current_state` and handles menu input. `main.gd` starts in MENU (no auto-spawn), starts the level on confirm, and routes death→lose-life→respawn-or-defeat and goal→victory.

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; every command must self-terminate — use `--quit-after` for game runs; never leave a process running). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new classes.

**Branch:** `feat/audio` (rolling post-slice branch; HEAD ~`ff54ec8`).

**Inputs:** existing actions — `pause` (Esc), `jump`/confirm (Space), `attack_light` (J). Add a `restart` action (R) and reuse `jump`/`pause` for menu confirm/back. (Add `restart` to project.godot if not present.)

---

## Task 1: GameState — VICTORY state, lives, transitions (TDD)

**Files:** `scripts/autoload/game_state.gd`; Test `test/unit/test_game_flow.gd`.

- [ ] **Step 1: Add `VICTORY` to the `State` enum** (after `GAME_OVER`). Add fields near the top: `var lives: int = 3` and `const MAX_LIVES := 3`.
- [ ] **Step 2: Add pure-ish flow helpers:**
```gdscript
func begin_run() -> void:
	lives = MAX_LIVES
	current_checkpoint = 0
	current_state = State.PLAYING

## Consume a life on death. Returns true if the run is now over (defeat).
func lose_life() -> bool:
	lives = max(0, lives - 1)
	if lives <= 0:
		current_state = State.GAME_OVER
		return true
	return false

func win_run() -> void:
	current_state = State.VICTORY
```
- [ ] **Step 3: Failing test** `test/unit/test_game_flow.gd`:
```gdscript
extends GutTest

func test_begin_run_sets_playing_and_full_lives():
	GameState.begin_run()
	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_eq(GameState.lives, GameState.MAX_LIVES)

func test_lose_life_decrements_then_defeats_at_zero():
	GameState.begin_run()
	var defeated := false
	for i in range(GameState.MAX_LIVES):
		defeated = GameState.lose_life()
	assert_true(defeated, "defeated after losing all lives")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)

func test_win_sets_victory():
	GameState.begin_run()
	GameState.win_run()
	assert_eq(GameState.current_state, GameState.State.VICTORY)
```
(GameState is an autoload — accessible directly in tests.) RED → implement → GREEN.
- [ ] **Step 4:** suite green; parse check. **Commit:** `feat: GameState victory state + lives + run transitions`.

---

## Task 2: Clean level restart + title gating in main.gd

**Files:** `scripts/main/main.gd`, `project.godot` (add `restart` action). Verified by headless boot (starts at title, no entities until start) + suite.

- [ ] **Step 1: Add `restart` input action** to `project.godot` (keyboard R = physical_keycode 82; mirror an existing action's format). 
- [ ] **Step 2: Don't auto-spawn on launch.** In `_ready`, replace `call_deferred("_spawn_test_scene")` with starting in the menu: `GameState.current_state = GameState.State.MENU` (the ScreenManager from Task 3 shows the title). Keep ECS init / signals / parallax.
- [ ] **Step 3: Extract level lifecycle:**
  - `_start_level()`: `GameState.begin_run()`, reset arena/flow fields (`_arenas_activated.clear()`, `_arena_enemies.clear()`, `_current_arena = -1`, `_won = false`), then `_player_spawn = LevelOne.SPAWN`, spawn player, `_build_level()`. (Move the current `_spawn_test_scene` body here.)
  - `_clear_level()`: free all entity nodes + level geometry + overlays, then reset ECS world:
```gdscript
func _clear_level() -> void:
	ECS.clear_all()
	for c in entities_node.get_children():
		c.queue_free()
	var world = game.get_node_or_null("World")
	if world:
		for c in world.get_children():
			c.queue_free()
	var win = get_node_or_null("WinLayer")
	if win:
		win.queue_free()
	_player_entity_id = -1
```
  - `_restart_level()`: `_clear_level()`; await a frame if needed; `_start_level()`.
- [ ] **Step 4:** Boot check (`--headless --path . --quit-after 150`): NO SCRIPT ERROR; "ECS initialized with 13 systems" prints but **no "Player spawned"** (we start in MENU now). Full suite green. **Commit:** `feat: title-gated start + clean in-place level restart`.

---

## Task 3: ScreenManager (Title / Pause / Victory / Defeat)

**Files:** Create `scripts/ui/screen_manager.gd`; Test `test/unit/test_screen_manager.gd`.

- [ ] **Step 1:** A `ScreenManager` (CanvasLayer, layer 200, `PROCESS_MODE_ALWAYS`) that builds a centered full-rect `Label` and updates its text from `GameState.state_changed`. A pure static helper maps state→text (TDD that):
```gdscript
class_name ScreenManager
extends CanvasLayer

var _label: Label

static func screen_text(state: int, lives: int) -> String:
	match state:
		GameState.State.MENU:
			return "WOLF ZERO\n\nNeo Edo\n\n[Enter] Begin"
		GameState.State.PAUSED:
			return "PAUSED\n\n[Esc] Resume    [R] Restart"
		GameState.State.VICTORY:
			return "VICTORY\n\n[R] Play Again"
		GameState.State.GAME_OVER:
			return "DEFEAT\n\n[R] Retry"
		_:
			return ""   # PLAYING etc. -> hidden

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 48)
	_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	add_child(_label)
	GameState.state_changed.connect(_on_state_changed)
	_refresh(GameState.current_state)

func _on_state_changed(new_state: int, _old: int) -> void:
	_refresh(new_state)

func _refresh(state: int) -> void:
	var t := screen_text(state, GameState.lives)
	_label.text = t
	_label.visible = t != ""
```
- [ ] **Step 2: Failing test** `test/unit/test_screen_manager.gd`:
```gdscript
extends GutTest
const SM = preload("res://scripts/ui/screen_manager.gd")

func test_screen_text_per_state():
	assert_true(SM.screen_text(GameState.State.MENU, 3).contains("Begin"))
	assert_true(SM.screen_text(GameState.State.PAUSED, 3).contains("Resume"))
	assert_true(SM.screen_text(GameState.State.VICTORY, 3).contains("VICTORY"))
	assert_true(SM.screen_text(GameState.State.GAME_OVER, 3).contains("DEFEAT"))
	assert_eq(SM.screen_text(GameState.State.PLAYING, 3), "", "no overlay while playing")
```
RED (`--import`) → implement → GREEN.
- [ ] **Step 3:** suite green. **Commit:** `feat: ScreenManager overlay for title/pause/victory/defeat`.

---

## Task 4: Wire the shell + flow, then review

**Files:** `scripts/main/main.gd`.

- [ ] **Step 1:** In `_ready`, add the ScreenManager: `add_child(ScreenManager.new())`. Start in MENU (Task 2).
- [ ] **Step 2: Menu/confirm input.** In `_unhandled_input`, handle by state:
  - MENU: on `jump` (Space) or ui_accept → `_start_level()`.
  - PLAYING: on `pause` (Esc) → `GameState.pause_game()`.
  - PAUSED: on `pause` → `GameState.resume_game()`; on `restart` (R) → `GameState.resume_game()` then `_restart_level()`.
  - VICTORY / GAME_OVER: on `restart` (R) → `_restart_level()`.
  (Note: `_unhandled_input` must run while paused — main is a Node; set its `process_mode` to `PROCESS_MODE_ALWAYS` in `_ready` so input is handled during PAUSED. Verify pause still freezes ECS — ECS is PAUSABLE, unaffected.)
- [ ] **Step 3: Death → lose life → respawn or defeat.** In the player-death finish (`_finish_player_death` from the dying flow), instead of always respawning: `if GameState.lose_life(): _on_defeat() else: <existing respawn + arena restore>`. `_on_defeat()` just leaves the player dead and lets GameState GAME_OVER drive the ScreenManager (pause ECS via `get_tree().paused = true` so the field freezes under the DEFEAT overlay).
- [ ] **Step 4: Goal → victory.** Where the win currently triggers (`_won`/`_show_victory`), call `GameState.win_run()` and `get_tree().paused = true` (freeze under the VICTORY overlay) instead of the ad-hoc WinLabel. Remove the old `WinLabel`/`_show_victory` usage (leave `_is_victory` if a test still needs it — check; `test_win_condition.gd` references `_is_victory`).
- [ ] **Step 5: Review.** `--import`; full suite green; boot to title (no entities). Then a scripted montage capture: start at MENU (screenshot title) → `GameState`-drive or simulate `_start_level()` → screenshot PLAYING → force `GameState.win_run()`/`get_tree().paused` → screenshot VICTORY → (reset) force lives to 0 via `lose_life` loop → screenshot DEFEAT. Confirm each overlay renders centered. **Commit:** `feat: wire game shell (title/pause/victory/defeat + restart + lives)`.

---

## Definition of Done
- [ ] Launch → centered **Title**; confirm starts the level.
- [ ] **Esc** pauses with a menu (resume / restart); pause freezes the field.
- [ ] Player death consumes a life and respawns at checkpoint; at 0 lives → **DEFEAT** (retry).
- [ ] Reaching the goal → **VICTORY** (play again).
- [ ] **Restart** rebuilds the level cleanly (no stale entities, no double-registered systems).
- [ ] All tests pass; clean boot; ~60 FPS.
