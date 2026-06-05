extends GutTest

const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_idle_when_still_on_ground():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 0.0},
		{"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false},
		{"is_dashing": false})
	assert_eq(anim, "idle")

func test_run_when_moving_on_ground():
	var anim = Anim.derive_clip(
		{"x": 120.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "run")

func test_fall_when_airborne_descending():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 200.0}, {"on_ground": false},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "fall")

func test_dash_overrides_run():
	var anim = Anim.derive_clip(
		{"x": 800.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": true})
	assert_eq(anim, "dash")

func test_attack_clip_uses_combo_index():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": true, "attack_type": "light", "combo_current": 3},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "light_3")
