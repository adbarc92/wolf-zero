extends GutTest

const DebugOverlay = preload("res://scripts/ui/debug_overlay.gd")

func test_dash_binding_reports_c():
	assert_string_contains(DebugOverlay.describe_binding("dash"), "C",
		"dash is bound to the C key (read live from InputMap)")

func test_dodge_binding_reports_shift():
	assert_string_contains(DebugOverlay.describe_binding("dodge"), "Shift",
		"dodge is bound to Shift")

func test_unknown_action_returns_dash():
	assert_eq(DebugOverlay.describe_binding("not_an_action"), "-",
		"unknown actions return a placeholder")
