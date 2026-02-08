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
	
	# Connect to hotbar item usage
	connect_to_hotbar()

func connect_to_hotbar():
	"""Connect to hotbar's item_used signal"""
	await get_tree().process_frame
	
	var scene = get_tree().current_scene
	if scene != null:
		var hud = scene.get_node_or_null("HUD")
		if hud != null:
			var hotbar = hud.get_node_or_null("Hotbar")
			if hotbar != null and hotbar.has_signal("item_used"):
				if not hotbar.item_used.is_connected(_on_hotbar_item_used):
					hotbar.item_used.connect(_on_hotbar_item_used)
					print("✅ Connected to hotbar item_used signal")

func _on_hotbar_item_used(slot_index: int, item):
	"""Called when player presses E on a hotbar item"""
	if item == null:
		return
	
	# Check if it's a fishing rod
	var item_type = ""
	if item is Dictionary:
		item_type = item.get("type", "")
	
	if item_type == "fishing_rod":
		use_fishing_rod()
	elif item_type == "bait":
		print("🪱 Used bait (not implemented yet)")
	else:
		print("Used item: ", item)

func use_fishing_rod():
	"""Use the fishing rod to start fishing"""
	if is_fishing:
		print("⚠️ Already fishing!")
		return
	
	# Check if we have the FishingSystem node
	if fishing_system == null:
		print("❌ FishingSystem not found!")
		return
	
	# Start fishing through the system
	fishing_system.start_fishing()

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

func _input(event: InputEvent) -> void:
	# F key for testing fishing animation only
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if is_fishing:
			stop_fishing()
		else:
			start_fishing()
		get_viewport().set_input_as_handled()
		return
	
	# Backslash for instant combat test
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSLASH:
		var gd := get_node_or_null("/root/GlobalData")
		if gd != null:
			gd.set("has_saved_player_position", true)
			gd.set("saved_player_position", global_position)
			gd.current_fish = gd.roll_random_fish()
			gd.rod_durability = 100
			print("🎣 TEST FIGHT! Fish: ", gd.current_fish.get("name"), " Lv.", gd.current_fish.get("level"), " HP: ", gd.current_fish.get("health"))

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
