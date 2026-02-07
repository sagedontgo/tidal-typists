extends CharacterBody2D

const SPEED = 100.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var nickname_label = $NicknameLabel

var can_move = true

func _ready() -> void:
	var gd := get_node_or_null("/root/GlobalData")
	
	# Load the correct sprite based on gender selection
	load_character_sprite()
	
	# If we came back from combat, restore where we were
	if gd != null and bool(gd.get("has_saved_player_position")):
		global_position = gd.get("saved_player_position")
	
	# Update nickname display
	if gd != null and gd.get("player_nickname") != "":
		nickname_label.text = gd.get("player_nickname")
	else:
		nickname_label.text = "Player"

func load_character_sprite():
	"""Load the correct sprite sheet based on player's gender"""
	var gd := get_node_or_null("/root/GlobalData")
	if gd == null:
		print("⚠️ GlobalData not found, using default sprite")
		return
	
	var gender = gd.get("player_gender")
	
	# Determine which sprite sheet to use
	var sprite_frames: SpriteFrames
	
	if gender == "Male (placeholder)" or gender == "Male":
		sprite_frames = load("res://assets/characters/male_animations.tres")
		print("✅ Loaded MALE character sprite")
	elif gender == "Female (placeholder)" or gender == "Female":
		sprite_frames = load("res://assets/characters/female_animations.tres")
		print("✅ Loaded FEMALE character sprite")
	else:
		# Default to male if no gender selected
		sprite_frames = load("res://assets/characters/male_animations.tres")
		print("⚠️ No gender selected, defaulting to male sprite")
	
	# Apply the sprite frames
	if sprite_frames and animated_sprite:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idle")
	else:
		print("❌ Failed to load sprite frames!")

func _physics_process(_delta: float) -> void:
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Save current position for combat return
		var gd := get_node_or_null("/root/GlobalData")
		if gd != null:
			gd.set("has_saved_player_position", true)
			gd.set("saved_player_position", global_position)

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
