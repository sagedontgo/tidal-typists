extends CharacterBody2D

const SPEED = 100.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var nickname_label = $NicknameLabel
@onready var fishing_system = $FishingSystem  # The FishingSystem node

var can_move = true
var is_fishing = false
var last_direction = Vector2.DOWN

func _ready() -> void:
	var gd := get_node_or_null("/root/GlobalData")
	
	load_character_sprite()
	
	if gd != null and bool(gd.get("has_saved_player_position")):
		global_position = gd.get("saved_player_position")
	
	if gd != null and gd.get("player_nickname") != "":
		nickname_label.text = gd.get("player_nickname")
	else:
		nickname_label.text = "Player"

func has_fishing_rod_equipped() -> bool:
	"""Check if player has a fishing rod in their hotbar"""
	var scene = get_tree().current_scene
	if scene != null:
		var hud = scene.get_node_or_null("HUD")
		if hud != null:
			var hotbar = hud.get_node_or_null("Hotbar")
			if hotbar != null and hotbar.has_method("get_current_item"):
				var current_item = hotbar.get_current_item()
				if current_item is Dictionary:
					return current_item.get("type", "") == "fishing_rod"
	return false

func is_rod_broken() -> bool:
	"""Check if the fishing rod is broken (0 durability)"""
	var gd := get_node_or_null("/root/GlobalData")
	if gd == null:
		return false
	
	var current_durability = gd.current_rod.get("current_durability", 100)
	return current_durability <= 0

func is_inventory_open() -> bool:
	"""Check if inventory UI is currently open"""
	var scene = get_tree().current_scene
	if scene != null:
		var hud = scene.get_node_or_null("HUD")
		if hud != null:
			var inventory = hud.get_node_or_null("Inventory")
			if inventory != null:
				return inventory.visible
	return false

func is_on_water() -> bool:
	"""Check if player is standing on water tile"""
	var tile_map = get_tree().current_scene.find_child("WaterTileMap", true, false)
	if tile_map == null:
		tile_map = get_tree().current_scene.find_child("Water", true, false)
	
	if tile_map == null:
		print("⚠️ Water TileMap not found!")
		return false
	
	# Get the tile position under the player
	var player_tile_pos = tile_map.local_to_map(tile_map.to_local(global_position))
	
	# Check if there's a tile at this position
	var tile_data = tile_map.get_cell_tile_data(player_tile_pos)
	
	# If there's a tile, we're on water
	return tile_data != null

func use_fishing_rod():
	"""Use the fishing rod to start fishing - only works on water"""
	if is_fishing:
		print("⚠️ Already fishing!")
		return
	
	# *** NEW: Check if rod is broken ***
	if is_rod_broken():
		print("⚠️ Your fishing rod is broken! Repair it at the shop.")
		show_broken_rod_message()
		return
	
	# Check if we're on water
	if not is_on_water():
		print("⚠️ You need to be on water to fish!")
		return
	
	# Check if we have the FishingSystem node
	if fishing_system == null:
		print("❌ FishingSystem not found!")
		return
	
	# Start fishing through the system (this calls start_fishing() below which plays animation)
	fishing_system.start_fishing()

func show_broken_rod_message():
	"""Show a temporary message when trying to use broken rod"""
	# This could be enhanced with a UI label, but for now just print
	# You can add a CanvasLayer with a Label here if desired
	pass

func load_character_sprite():
	"""Load the correct sprite sheet based on player's gender"""
	var gd := get_node_or_null("/root/GlobalData")
	if gd == null:
		print("⚠️ GlobalData not found, using default sprite")
		return
	
	var gender = gd.get("player_gender")
	var sprite_frames: SpriteFrames
	
	if gender == "Male (placeholder)" or gender == "Male":
		sprite_frames = load("res://assets/characters/male_animations.tres")
		print("✅ Loaded MALE character sprite")
	elif gender == "Female (placeholder)" or gender == "Female":
		sprite_frames = load("res://assets/characters/female_animations.tres")
		print("✅ Loaded FEMALE character sprite")
	else:
		sprite_frames = load("res://assets/characters/male_animations.tres")
		print("⚠️ No gender selected, defaulting to male sprite")
	
	if sprite_frames and animated_sprite:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idle")
	else:
		print("❌ Failed to load sprite frames!")

func _physics_process(_delta: float) -> void:
	if is_fishing:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1
	elif Input.is_action_pressed("ui_left"):
		direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
	
	if direction != Vector2.ZERO:
		last_direction = direction
		update_animation(direction)
	else:
		animated_sprite.play("idle")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()

func update_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("move_right")
		animated_sprite.flip_h = direction.x < 0
	else:
		animated_sprite.flip_h = false
		if direction.y > 0:
			animated_sprite.play("move_down")
		else:
			animated_sprite.play("move_up")

func start_fishing():
	"""Start fishing animation in the direction player is facing"""
	is_fishing = true
	can_move = false
	
	# Choose fishing animation based on last direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x < 0:
			animated_sprite.play("fishing_left")
		else:
			animated_sprite.play("fishing_right")
	else:
		if last_direction.y > 0:
			animated_sprite.play("fishing_down")
		else:
			animated_sprite.play("fishing_up")
	
	print("🎣 Started fishing animation (direction: ", get_fishing_direction_name(), ")")

func play_hook_animation():
	"""Play the hook animation based on current fishing direction"""
	# Choose hook animation based on last direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x < 0:
			animated_sprite.play("hook_left")
		else:
			animated_sprite.play("hook_right")
	else:
		if last_direction.y > 0:
			animated_sprite.play("hook_down")
		else:
			animated_sprite.play("hook_up")
	
	print("🎣 Playing hook animation (direction: ", get_fishing_direction_name(), ")")
	
	# Wait for the animation to finish
	await animated_sprite.animation_finished

func stop_fishing():
	"""Stop fishing and return to idle"""
	is_fishing = false
	can_move = true
	animated_sprite.play("idle")
	print("✅ Stopped fishing animation")

func get_fishing_direction_name() -> String:
	"""Helper to get current fishing direction as string"""
	if abs(last_direction.x) > abs(last_direction.y):
		return "left" if last_direction.x < 0 else "right"
	else:
		return "down" if last_direction.y > 0 else "up"

func _save_inventory_and_hotbar():
	"""Helper function to save inventory before combat transitions"""
	var scene = get_tree().current_scene
	if scene == null:
		print("⚠️ Can't save - no scene")
		return
	
	var hud = scene.get_node_or_null("HUD")
	if hud == null:
		print("⚠️ Can't save - no HUD")
		return
	
	var inventory = hud.get_node_or_null("Inventory")
	var hotbar = hud.get_node_or_null("Hotbar")
	
	# Handle inventory wrapper
	if inventory != null and not (inventory is Inventory):
		var inv_child = inventory.find_child("Inventory", true, false)
		if inv_child is Inventory:
			inventory = inv_child
	
	print("\n💾 === SAVING BEFORE COMBAT (from player test) ===")
	
	if inventory != null and inventory.has_method("save_to_global"):
		inventory.save_to_global()
		print("✅ Saved inventory")
	else:
		print("❌ Could not save inventory")
	
	if hotbar != null and hotbar.has_method("save_to_global"):
		hotbar.save_to_global()
		print("✅ Saved hotbar")
	else:
		print("❌ Could not save hotbar")
	
	print("=== SAVE COMPLETE ===\n")

func _input(event: InputEvent) -> void:
	# Left click for fishing (only when fishing rod is equipped and inventory is closed)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Don't trigger fishing if inventory is open
			if not is_inventory_open():
				if has_fishing_rod_equipped() and not is_fishing:
					use_fishing_rod()
		
		# Right click to cancel fishing
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_fishing and fishing_system != null:
				fishing_system.stop_fishing()
				print("🚫 Fishing cancelled by player")
	
	# Backslash for instant combat test
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSLASH:
		# *** FIX: Save inventory BEFORE test fight ***
		_save_inventory_and_hotbar()
		
		var gd := get_node_or_null("/root/GlobalData")
		if gd != null:
			gd.set("has_saved_player_position", true)
			gd.set("saved_player_position", global_position)
			gd.current_fish = gd.roll_random_fish()
			
			# *** FIX: Use current rod durability instead of resetting ***
			gd.rod_durability = gd.current_rod.get("current_durability", 100)
			print("🎣 TEST FIGHT! Fish: ", gd.current_fish.get("name"), " Lv.", gd.current_fish.get("level"), " HP: ", gd.current_fish.get("health"))
			print("🎣 Rod durability: ", gd.rod_durability)

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
