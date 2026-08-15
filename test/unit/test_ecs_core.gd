extends GutTest
## Core ECS manager: entity lifecycle, component storage, queries, node mapping,
## system registration, and the clear_all() reset that in-place restart relies on.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

var ecs


func before_each():
	# Deliberately not added to the scene tree: _physics_process must not drive
	# registered systems while these tests step through state by hand.
	ecs = ECSScript.new()
	autofree(ecs)


# =============================================================================
# ENTITY LIFECYCLE
# =============================================================================

func test_entity_ids_are_handed_out_sequentially():
	assert_eq(ecs.create_entity(), 0, "first entity is 0")
	assert_eq(ecs.create_entity(), 1, "ids increment")


func test_created_entity_exists_and_unknown_ids_do_not():
	var e = ecs.create_entity()
	assert_true(ecs.entity_exists(e), "created entity exists")
	assert_false(ecs.entity_exists(999), "never-created id does not exist")


func test_destroy_entity_removes_it_and_all_its_components():
	var e = ecs.create_entity()
	ecs.add_component(e, "health", Components.health(50))
	ecs.add_component(e, "momentum", Components.momentum())

	ecs.destroy_entity(e)

	assert_false(ecs.entity_exists(e), "entity is gone")
	assert_false(ecs.has_component(e, "health"), "health went with it")
	assert_null(ecs.get_component(e, "momentum"), "momentum went with it")


func test_destroying_an_unknown_entity_is_a_noop():
	ecs.create_entity()
	ecs.destroy_entity(999)
	assert_eq(ecs.get_debug_info().entity_count, 1, "the live entity is untouched")


func test_destroying_one_entity_leaves_its_siblings_components_intact():
	var a = ecs.create_entity()
	var b = ecs.create_entity()
	ecs.add_component(a, "health", Components.health(10))
	ecs.add_component(b, "health", Components.health(20))

	ecs.destroy_entity(a)

	assert_true(ecs.has_component(b, "health"), "sibling keeps its component")
	assert_eq(ecs.get_component(b, "health").current, 20, "and its data")


func test_entity_signals_fire_on_create_and_destroy():
	watch_signals(ecs)
	var e = ecs.create_entity()
	assert_signal_emitted_with_parameters(ecs, "entity_created", [e])

	ecs.destroy_entity(e)
	assert_signal_emitted_with_parameters(ecs, "entity_destroyed", [e])


# =============================================================================
# COMPONENTS
# =============================================================================

func test_add_component_returns_the_same_dictionary_it_stores():
	var e = ecs.create_entity()
	var returned = ecs.add_component(e, "health", Components.health(75))

	returned.current = 5
	assert_eq(ecs.get_component(e, "health").current, 5,
		"the returned dict is the stored one, so writes through it stick")


func test_get_component_returns_null_when_absent():
	var e = ecs.create_entity()
	assert_null(ecs.get_component(e, "health"), "component never added")
	assert_null(ecs.get_component(e, "nonexistent_type"), "type never seen at all")


func test_remove_component_drops_only_that_component():
	var e = ecs.create_entity()
	ecs.add_component(e, "health", Components.health())
	ecs.add_component(e, "dodge", Components.dodge())

	ecs.remove_component(e, "health")

	assert_false(ecs.has_component(e, "health"), "removed")
	assert_true(ecs.has_component(e, "dodge"), "the other one stays")


func test_remove_component_that_is_not_there_is_a_noop():
	var e = ecs.create_entity()
	ecs.remove_component(e, "health")
	assert_false(ecs.has_component(e, "health"), "still absent, no crash")


func test_has_components_requires_every_listed_type():
	var e = ecs.create_entity()
	ecs.add_component(e, "health", Components.health())
	ecs.add_component(e, "dodge", Components.dodge())

	var present: Array[String] = ["health", "dodge"]
	var partly_missing: Array[String] = ["health", "momentum"]

	assert_true(ecs.has_components(e, present), "has both")
	assert_false(ecs.has_components(e, partly_missing), "missing one fails the set")


func test_component_signals_fire_on_add_and_remove():
	var e = ecs.create_entity()
	watch_signals(ecs)

	ecs.add_component(e, "health", Components.health())
	assert_signal_emitted_with_parameters(ecs, "component_added", [e, "health"])

	ecs.remove_component(e, "health")
	assert_signal_emitted_with_parameters(ecs, "component_removed", [e, "health"])


func test_get_all_components_returns_only_that_entitys_components():
	var a = ecs.create_entity()
	var b = ecs.create_entity()
	ecs.add_component(a, "health", Components.health())
	ecs.add_component(a, "dodge", Components.dodge())
	ecs.add_component(b, "momentum", Components.momentum())

	var all = ecs.get_all_components(a)

	assert_eq(all.size(), 2, "two components for a")
	assert_true(all.has("health") and all.has("dodge"), "the right two")
	assert_false(all.has("momentum"), "b's component is not included")


# =============================================================================
# QUERIES
# =============================================================================

func test_get_entities_with_returns_empty_for_an_unseen_type():
	assert_eq(ecs.get_entities_with("health"), [], "no entity has ever had one")


func test_get_entities_with_finds_every_holder():
	var a = ecs.create_entity()
	var b = ecs.create_entity()
	var c = ecs.create_entity()
	ecs.add_component(a, "health", Components.health())
	ecs.add_component(c, "health", Components.health())

	var found = ecs.get_entities_with("health")

	assert_eq(found.size(), 2, "two holders")
	assert_true(a in found and c in found, "the right two")
	assert_false(b in found, "the non-holder is excluded")


func test_get_entities_with_all_intersects_the_requested_types():
	var both = ecs.create_entity()
	var only_health = ecs.create_entity()
	ecs.add_component(both, "health", Components.health())
	ecs.add_component(both, "dodge", Components.dodge())
	ecs.add_component(only_health, "health", Components.health())

	var required: Array[String] = ["health", "dodge"]
	var found = ecs.get_entities_with_all(required)

	assert_eq(found, [both], "only the entity holding both")


func test_get_entities_with_all_of_nothing_is_empty():
	var e = ecs.create_entity()
	ecs.add_component(e, "health", Components.health())
	var empty: Array[String] = []
	assert_eq(ecs.get_entities_with_all(empty), [],
		"an empty requirement list matches nothing, not everything")


# =============================================================================
# NODE MAPPING (hybrid ECS)
# =============================================================================

func test_entity_and_node_map_to_each_other():
	var node = Node2D.new()
	autofree(node)
	var e = ecs.create_entity_with_node(node)

	assert_eq(ecs.get_entity_node(e), node, "entity -> node")
	assert_eq(ecs.get_node_entity(node), e, "node -> entity")


func test_get_node_entity_returns_minus_one_for_an_unmapped_node():
	var node = Node2D.new()
	autofree(node)
	assert_eq(ecs.get_node_entity(node), -1, "unmapped node reports -1")


func test_destroying_an_entity_clears_both_directions_of_the_mapping():
	var node = Node2D.new()
	autofree(node)
	var e = ecs.create_entity_with_node(node)

	ecs.destroy_entity(e)

	assert_null(ecs.get_entity_node(e), "entity -> node cleared")
	assert_eq(ecs.get_node_entity(node), -1, "node -> entity cleared")


# =============================================================================
# SYSTEMS
# =============================================================================

func test_register_system_injects_the_ecs_reference():
	var system = MomentumSystem.new()
	ecs.register_system(system)
	assert_eq(system.ecs, ecs, "the system can reach the manager it was registered with")


func test_get_system_finds_a_registered_system_by_script():
	var system = MomentumSystem.new()
	ecs.register_system(system)
	assert_eq(ecs.get_system(MomentumSystem), system, "found by class")


func test_get_system_returns_null_when_not_registered():
	assert_null(ecs.get_system(MomentumSystem), "nothing registered")


func test_unregister_system_removes_it():
	var system = MomentumSystem.new()
	ecs.register_system(system)
	ecs.unregister_system(system)
	assert_null(ecs.get_system(MomentumSystem), "no longer registered")


func test_set_system_enabled_toggles_the_flag():
	var system = MomentumSystem.new()
	ecs.register_system(system)

	ecs.set_system_enabled(MomentumSystem, false)
	assert_false(system.enabled, "disabled")

	ecs.set_system_enabled(MomentumSystem, true)
	assert_true(system.enabled, "re-enabled")


func test_systems_run_in_registration_order():
	# Registration order is load-bearing: PhysicsSyncSystem must settle positions
	# before AnimationSystem reads them, and so on down the list.
	ecs.register_system(MomentumSystem.new())
	ecs.register_system(DodgeSystem.new())

	assert_eq(ecs.get_debug_info().systems,
		["momentum_system.gd", "dodge_system.gd"],
		"systems report in the order they were registered")


# =============================================================================
# CLEAR_ALL (in-place restart)
# =============================================================================

func test_clear_all_removes_every_entity_and_component():
	var a = ecs.create_entity()
	var b = ecs.create_entity()
	ecs.add_component(a, "health", Components.health())
	ecs.add_component(b, "momentum", Components.momentum())

	ecs.clear_all()

	assert_false(ecs.entity_exists(a), "entity a gone")
	assert_false(ecs.entity_exists(b), "entity b gone")
	assert_eq(ecs.get_entities_with("health"), [], "component store emptied")
	assert_eq(ecs.get_debug_info().entity_count, 0, "nothing left")


func test_clear_all_rewinds_the_id_counter():
	# Restart re-spawns the player expecting a fresh id space.
	ecs.create_entity()
	ecs.create_entity()

	ecs.clear_all()

	assert_eq(ecs.create_entity(), 0, "ids start over from 0 after a clear")


func test_clear_all_drops_node_mappings():
	var node = Node2D.new()
	autofree(node)
	ecs.create_entity_with_node(node)

	ecs.clear_all()

	assert_eq(ecs.get_node_entity(node), -1, "stale node no longer resolves")


func test_clear_all_keeps_systems_registered():
	# Systems outlive a restart; only entity/component state is thrown away.
	var system = MomentumSystem.new()
	ecs.register_system(system)

	ecs.clear_all()

	assert_eq(ecs.get_system(MomentumSystem), system, "system survives clear_all")
