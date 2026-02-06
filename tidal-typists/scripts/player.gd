extends CharacterBody2D

const SPEED = 100.0

@onready var animated_sprite = $AnimatedSprite2D

var can_move = true

func _ready() -> void:
	# If we came back from combat, restore where we were.
	var gd := get_node_or_null("/root/GlobalData")
	if gd != null and bool(gd.get("has_saved_player_position")):
		global_position = gd.get("saved_player_position")

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
		# Save our current position so returning from combat doesn't
		# reset us to the scene's default spawn point.
		var gd := get_node_or_null("/root/GlobalData")
		if gd != null:
			gd.set("has_saved_player_position", true)
			gd.set("saved_player_position", global_position)

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
