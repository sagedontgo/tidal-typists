extends Area2D

# Shop Trigger - Place this in front of the blue building
# FIXED VERSION: Properly saves player position

@onready var shop_prompt: Label = null

var player_in_range = false

func _ready():
	create_shop_prompt()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("🏪 Shop trigger ready!")

func create_shop_prompt():
	"""Create a floating 'Press E to Shop' label"""
	shop_prompt = Label.new()
	shop_prompt.text = "Press E to Shop"
	shop_prompt.add_theme_font_size_override("font_size", 20)
	shop_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
	shop_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	shop_prompt.add_theme_constant_override("outline_size", 3)
	shop_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_prompt.position = Vector2(-75, -50)
	shop_prompt.size = Vector2(150, 30)
	
	add_child(shop_prompt)
	shop_prompt.visible = false

func _on_body_entered(body):
	"""Player entered shop trigger area"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		if shop_prompt:
			shop_prompt.visible = true
		print("🏪 Near shop! Press E to open")

func _on_body_exited(body):
	"""Player left shop trigger area"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false
		if shop_prompt:
			shop_prompt.visible = false
		print("👋 Left shop area")

func _input(event):
	"""Handle E key to open shop"""
	if not player_in_range:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			open_shop()
			get_viewport().set_input_as_handled()

func open_shop():
	"""Open the shop scene - FIXED VERSION"""
	print("🏪 Opening shop...")
	
	# CRITICAL FIX: Save player position to GlobalData FIRST!
	save_player_position()
	
	# THEN save inventory and hotbar
	save_game_state()
	
	# NOW transition to shop
	SceneTransition.fade_to_scene("res://scenes/shop.tscn")

func save_player_position():
	"""CRITICAL FIX: Save player position before going to shop"""
	var gd = get_node_or_null("/root/GlobalData")
	if gd == null:
		print("❌ GlobalData not found!")
		return
	
	# Find the player node
	var scene = get_tree().current_scene
	if scene == null:
		return
	
	var player = scene.get_node_or_null("Player")
	if player == null:
		# Try to find player in scene
		player = scene.find_child("Player", true, false)
	
	if player != null:
		# Save position to GlobalData
		gd.has_saved_player_position = true
		gd.saved_player_position = player.global_position
		print("✅ Saved player position: ", player.global_position)
	else:
		print("⚠️ Player not found, position not saved!")

func save_game_state():
	"""Save inventory/hotbar before going to shop"""
	var scene = get_tree().current_scene
	if scene == null:
		return
	
	var hud = scene.get_node_or_null("HUD")
	if hud == null:
		return
	
	var inventory = hud.get_node_or_null("Inventory")
	var hotbar = hud.get_node_or_null("Hotbar")
	
	# Handle inventory wrapper
	if inventory != null and not (inventory is Inventory):
		var inv_child = inventory.find_child("Inventory", true, false)
		if inv_child is Inventory:
			inventory = inv_child
	
	print("💾 Saving inventory/hotbar...")
	
	if inventory != null and inventory.has_method("save_to_global"):
		inventory.save_to_global()
		print("✅ Saved inventory")
	
	if hotbar != null and hotbar.has_method("save_to_global"):
		hotbar.save_to_global()
		print("✅ Saved hotbar")
