extends SceneTree

func _init():
	print("Starting Inventory System Verification...")
	var inv_script = load("res://scripts/survival/inventory.gd")
	var stats_script = load("res://scripts/survival/survival_stats.gd")
	
	var inv = inv_script.new()
	var stats = stats_script.new()
	inv.add_child(stats)
	
	# Test 1: Add items
	var remaining = inv.add_item("wood", 70) # max stack is 64, so should use 2 slots: 64 and 6
	assert(remaining == 0, "Wood should be added completely")
	assert(inv.get_item_count("wood") == 70, "Total wood should be 70")
	assert(inv.slots[0]["count"] == 64, "First slot should have 64 wood")
	assert(inv.slots[1]["count"] == 6, "Second slot should have 6 wood")
	print("Test 1 Passed: Stacking and slot filling")
	
	# Test 2: Hotbar selection
	inv.set_active_hotbar_slot(3)
	assert(inv.get_active_slot_index() == 3, "Active slot should be 3")
	inv.next_hotbar_slot()
	assert(inv.get_active_slot_index() == 4, "Active slot should be 4")
	inv.prev_hotbar_slot()
	assert(inv.get_active_slot_index() == 3, "Active slot should be 3")
	print("Test 2 Passed: Hotbar slot selection and navigation")
	
	# Test 3: Food consumption
	stats.current_hunger = 50.0
	stats.current_health = 70.0
	inv.add_item("cooked_meat", 2)
	# cooked_meat was added to slot 2 (since 0 and 1 are wood)
	var consumed = inv.consume_item(2, stats)
	assert(consumed, "Food should be consumed")
	assert(stats.current_hunger == 95.0, "Hunger should be 50 + 45 = 95")
	assert(stats.current_health == 100.0, "Health should be 70 + 30 = 100")
	assert(inv.slots[2]["count"] == 1, "One meat remaining")
	print("Test 3 Passed: Food consumption restores hunger and health")
	
	# Test 4: Relic bonus calculation
	inv.add_item("sneakers", 3) # 3 * 0.15 = 0.45 (45% speed bonus)
	inv.add_item("sacred_feather", 1) # 1 extra jump
	var speed_bonus = inv.get_relic_bonus("speed_multiplier_bonus")
	var extra_jumps = inv.get_relic_bonus("extra_jumps")
	assert(is_equal_approx(speed_bonus, 0.45), "Speed bonus should be 0.45")
	assert(int(extra_jumps) == 1, "Extra jumps should be 1")
	print("Test 4 Passed: Muck Relics bonus accumulation")
	
	# Test 5: Swapping slots
	var ok_swap = inv.swap_slots(0, 5)
	assert(ok_swap, "Swap should succeed")
	assert(inv.slots[0] == null, "Slot 0 should now be null")
	assert(inv.slots[5]["id"] == "wood" and inv.slots[5]["count"] == 64, "Slot 5 should have 64 wood")
	print("Test 5 Passed: Slot swap")
	
	print("All Inventory System tests passed successfully!")
	quit(0)
