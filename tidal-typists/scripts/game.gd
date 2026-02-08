extends Node2D

# Fishing variables
@onready var player = $Player
@onready var tilemap_water = $Water
@onready var casting_label = $CanvasLayer/FishingUI/CastingLabel
@onready var waiting_label = $CanvasLayer/FishingUI/WaitingLabel

var is_fishing = false
var fish_wait_timer = 0.0
var fish_wait_duration = 0.0
var cast_position: Vector2 = Vector2.ZERO

# HUD/Inventory variables
var hud = null
var inventory = null
var hotbar = null

func _ready() -> void:
	# Fishing setup
	casting_label.visible = false
	waiting_label.visible = false
	
	# Inventory setup
	await get_tree().process_frame
	
	hud = get_node_or_null("HUD")
	if hud == null:
		print("❌ ERROR: HUD not found!")
		return
	print("✅ HUD found!")
	
	inventory = hud.get_node_or_null("Inventory")
	if inventory == null:
		print("❌ ERROR: Inventory not found!")
		return
	print("✅ Inventory found! Type: ", inventory.get_class())

	if not (inventory is Inventory):
		print("⚠️ Inventory is a wrapper, finding child with Inventory script...")
		var inv_child: Node = inventory.find_child("Inventory", true, false)
		if inv_child is Inventory:
			inventory = inv_child
			print("✅ Inventory script resolved from wrapper")
		else:
			print("❌ ERROR: Inventory script node not found under wrapper!")
			return
	else:
		print("✅ Inventory has correct script directly")
	
	hotbar = hud.get_node_or_null("Hotbar")
	if hotbar == null:
		print("❌ ERROR: Hotbar not found!")
		return
	print("✅ Hotbar found!")
	
	if not hotbar.has_method("get_item"):
		print("❌ ERROR: Hotbar missing script!")
		return
	print("✅ Hotbar has correct script")
	
	hotbar.main_inventory = inventory
	print("✅ Connected hotbar to inventory")
	
	hotbar.slot_changed.connect(_on_hotbar_slot_changed)
	hotbar.item_used.connect(_on_hotbar_item_used)
	print("✅ Signals connected")
	
	# Load saved inventory/hotbar items from GlobalData (if any)
	var loaded_inventory = false
	var loaded_hotbar = false
	
	print("\n🔍 === INVENTORY INITIALIZATION ===")
	print("Inventory node: ", inventory)
	print("Is Inventory class: ", inventory is Inventory)
	print("Has load_from_global: ", inventory.has_method("load_from_global"))
	
	# Check GlobalData state
	var gd = get_node_or_null("/root/GlobalData")
	if gd != null:
		print("\n📊 GlobalData state:")
		print("  - has_initialized_inventory: ", gd.has_initialized_inventory)
		print("  - has_initialized_hotbar: ", gd.has_initialized_hotbar)
		print("  - saved_inventory_items size: ", gd.saved_inventory_items.size())
		print("  - saved_hotbar_items size: ", gd.saved_hotbar_items.size())
	else:
		print("❌ ERROR: GlobalData not found!")
	
	if inventory.has_method("load_from_global"):
		loaded_inventory = inventory.load_from_global()
		print("📊 load_from_global returned: ", loaded_inventory)
	
	if hotbar.has_method("load_from_global"):
		loaded_hotbar = hotbar.load_from_global()
		print("📊 Hotbar load_from_global returned: ", loaded_hotbar)
	
	print("\n🎯 === DECISION TIME ===")
	# Only add starting items if we didn't load saved items
	if not loaded_inventory:
		print("🆕 No saved inventory found - adding starting fishing items")
		if inventory.has_method("add_fishing_items"):
			inventory.add_fishing_items()
	else:
		print("♻️ Using saved inventory items - NOT adding new items")
	
	if not loaded_hotbar:
		print("🆕 No saved hotbar found - setting up hotbar items")
		# Setup hotbar with backpack and map on first run
		if hotbar.has_method("setup_hotbar_items"):
			hotbar.setup_hotbar_items()
		if hotbar.has_method("lock_special_items"):
			hotbar.lock_special_items()
	else:
		print("♻️ Using saved hotbar items - NOT setting up new items")
	print("=== INITIALIZATION COMPLETE ===\n")
	
	print("\n=== Tidal Typist Ready! ===")

func _input(event: InputEvent) -> void:
	# Handle fishing rod casting with left mouse click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_fishing:
			# Don't cast if inventory is open
			if inventory != null and inventory.visible:
				return
			
			# Check if player has fishing rod equipped in hotbar
			if has_fishing_rod_equipped():
				# Check if clicking near water
				var mouse_pos = get_viewport().get_mouse_position()
				if is_click_near_water(mouse_pos):
					start_fishing(mouse_pos)
				else:
					print("⚠️ Can't cast there - click on water within range!")
			else:
				print("⚠️ You need to equip a fishing rod to fish!")

func has_fishing_rod_equipped() -> bool:
	"""Check if player currently has a fishing rod selected in hotbar"""
	if hotbar == null:
		return false
	
	var current_item = hotbar.get_current_item()
	if current_item is Dictionary and current_item.has("type"):
		if current_item["type"] == "fishing_rod":
			return true
	return false

func is_click_near_water(click_pos: Vector2) -> bool:
	"""Check if the clicked position is near water tiles"""
	# Convert screen position to world position
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * click_pos
	
	# Check if click is on water tile
	var click_tile = tilemap_water.local_to_map(world_pos - tilemap_water.global_position)
	if tilemap_water.get_cell_source_id(click_tile) != -1:
		# Also check if player is close enough to the clicked water
		if player.position.distance_to(world_pos) <= 200.0:  # Max casting distance
			return true
	return false

func is_player_near_water() -> bool:
	"""Check if player is standing next to water (for other uses)"""
	var player_tile = tilemap_water.local_to_map(player.position - tilemap_water.global_position)
	var adjacent_tiles = [
		Vector2i(player_tile.x + 1, player_tile.y),
		Vector2i(player_tile.x - 1, player_tile.y),
		Vector2i(player_tile.x, player_tile.y + 1),
		Vector2i(player_tile.x, player_tile.y - 1)
	]
	
	for adj in adjacent_tiles:
		if tilemap_water.get_cell_source_id(adj) != -1:
			return true
	return false

func start_fishing(click_pos: Vector2) -> void:
	"""Start fishing at the clicked position"""
	is_fishing = true
	player.can_move = false
	cast_position = get_viewport().get_canvas_transform().affine_inverse() * click_pos
	
	# Trigger fishing animation on player
	if player.has_method("start_fishing"):
		player.start_fishing()
	
	casting_label.visible = true
	waiting_label.visible = false
	
	print("🎣 Casting fishing rod at position: ", cast_position)
	
	# Show "Casting..." for 1 second
	await get_tree().create_timer(1.0).timeout
	casting_label.visible = false
	waiting_label.visible = true
	
	# Fish can bite anywhere within 20 seconds
	# Random chance for bite to occur
	fish_wait_duration = randf_range(3.0, 20.0)
	fish_wait_timer = 0.0
	
	print("🐟 Waiting for fish bite... (", int(fish_wait_duration), " seconds)")

func _process(delta: float) -> void:
	if is_fishing and waiting_label.visible:
		fish_wait_timer += delta
		
		# Update waiting label
		waiting_label.text = "Waiting for bite... (Right-click to cancel)"
		
		# Check if fish bites
		if fish_wait_timer >= fish_wait_duration:
			on_fish_bite()
		
		# Timeout after 20 seconds if no bite
		if fish_wait_timer >= 20.0:
			print("⏰ No bite... fish got away")
			cancel_fishing()
		
		# Cancel fishing if player presses right mouse button
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			cancel_fishing()

func cancel_fishing() -> void:
	"""Cancel fishing if player right-clicks or moves"""
	if is_fishing:
		is_fishing = false
		waiting_label.visible = false
		casting_label.visible = false
		player.can_move = true
		
		# Stop fishing animation on player
		if player.has_method("stop_fishing"):
			player.stop_fishing()
		
		print("❌ Fishing cancelled")

func on_fish_bite() -> void:
	"""Called when a fish bites the hook"""
	print("🐟 Fish bite detected!")
	catch_fish()

func catch_fish() -> void:
	is_fishing = false
	waiting_label.visible = false
	player.can_move = true
	
	# Save player position before combat
	GlobalData.has_saved_player_position = true
	GlobalData.saved_player_position = player.global_position
	print("💾 Saved player position: ", player.global_position)
	
	# Generate random fish for combat
	GlobalData.current_fish = GlobalData.roll_random_fish()
	GlobalData.rod_durability = 100
	
	# *** CRITICAL FIX: Save inventory/hotbar BEFORE any scene transition ***
	print("\n💾 === SAVING INVENTORY BEFORE COMBAT ===")
	if inventory != null and inventory.has_method("save_to_global"):
		inventory.save_to_global()
		print("✅ Saved inventory to GlobalData")
		
		# Debug: Show what was saved
		var gd = get_node_or_null("/root/GlobalData")
		if gd:
			print("📦 Inventory saved with ", gd.saved_inventory_items.size(), " slots:")
			for i in range(gd.saved_inventory_items.size()):
				var item = gd.saved_inventory_items[i]
				if item != null:
					var item_name = item.get("name", "Unknown") if item is Dictionary else str(item)
					print("  Slot %d: %s" % [i, item_name])
	else:
		print("❌ ERROR: Could not save inventory!")
	
	if hotbar != null and hotbar.has_method("save_to_global"):
		hotbar.save_to_global()
		print("✅ Saved hotbar to GlobalData")
	else:
		print("❌ ERROR: Could not save hotbar!")
	print("=== SAVE COMPLETE ===\n")
	
	# Switch to normal cursor for combat UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# *** FIX: Use only ONE scene transition method ***
	await SceneTransition.fade_to_scene("res://scenes/combat.tscn")

func _on_hotbar_slot_changed(slot_index: int):
	if hotbar == null:
		return
	
	var item = hotbar.get_item(slot_index)
	if item != null:
		var itemName = item if item is String else (item.get("itemName", "Unknown") if item is Dictionary else "Unknown")
		print("🎯 Selected slot ", slot_index + 1, ": ", itemName)

func _on_hotbar_item_used(slot_index: int, item):
	if item == null:
		return
	
	var itemName = item if item is String else (item.get("itemName", "Unknown") if item is Dictionary else "Unknown")
	print("⚡ Used ", itemName, " from slot ", slot_index + 1)	
