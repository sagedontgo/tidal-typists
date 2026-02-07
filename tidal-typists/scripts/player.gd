extends CharacterBody2D

const SPEED = 100.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var nickname_label = $NicknameLabel

var can_move = true

func _ready() -> void:
	# If we came back from combat, restore where we were.
	var gd := get_node_or_null("/root/GlobalData")
	if gd != null and bool(gd.get("has_saved_player_position")):
		global_position = gd.get("saved_player_position")
	
	# Update nickname display
	if gd != null and gd.get("player_nickname") != "":
		nickname_label.text = gd.get("player_nickname")
	else:
		nickname_label.text = "Player"

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
	# TEST: Backslash key to instantly start a fight (for testing only)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSLASH:
		# Save our current position so returning from combat doesn't
		# reset us to the scene's default spawn point.
		var gd := get_node_or_null("/root/GlobalData")
		if gd != null:
			gd.set("has_saved_player_position", true)
			gd.set("saved_player_position", global_position)
			
			# Generate a fresh random fish for this fight
			gd.current_fish = gd.roll_random_fish()
			# Reset rod durability to 100%
			gd.rod_durability = 100
			
			print("🎣 TEST FIGHT! Fish: ", gd.current_fish.get("name"), " Lv.", gd.current_fish.get("level"), " HP: ", gd.current_fish.get("health"))
		
		# Save inventory/hotbar state before transitioning to combat
		var scene = get_tree().current_scene
		if scene != null:
			var hud = scene.get_node_or_null("HUD")
			if hud != null:
				var inventory_node = hud.get_node_or_null("Inventory")
				var hotbar = hud.get_node_or_null("Hotbar")
				
				# Resolve inventory wrapper if needed (same as game.gd does)
				if inventory_node != null:
					if not inventory_node.has_method("save_to_global"):
						# It's a wrapper, find the actual Inventory script
						var inv_child = inventory_node.find_child("Inventory", true, false)
						if inv_child != null and inv_child.has_method("save_to_global"):
							inventory_node = inv_child
					
					if inventory_node.has_method("save_to_global"):
						inventory_node.save_to_global()
						print("💾 Saved inventory from player.gd")
				
				if hotbar != null and hotbar.has_method("save_to_global"):
					hotbar.save_to_global()
					print("💾 Saved hotbar from player.gd")

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
