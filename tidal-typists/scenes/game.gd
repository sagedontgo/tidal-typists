extends Node2D

# Fishing variables
@onready var player = $Player
@onready var tilemap_water = $Water
@onready var casting_label = $CanvasLayer/FishingUI/CastingLabel
@onready var waiting_label = $CanvasLayer/FishingUI/WaitingLabel

var is_fishing = false
var fish_wait_timer = 0.0
var fish_wait_duration = 0.0

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
	print("✅ Inventory found!")

	if not (inventory is Inventory):
		var inv_child: Node = inventory.find_child("Inventory", true, false)
		if inv_child is Inventory:
			inventory = inv_child
			print("✅ Inventory script resolved from wrapper")
		else:
			print("❌ ERROR: Inventory script node not found under wrapper!")
			return
	
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
	
	print("\n=== Tidal Typist Ready! ===")
	print("Press I, click Sword, click hotbar slot!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not is_fishing:
		if is_player_near_water():
			start_fishing()

func is_player_near_water() -> bool:
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

func start_fishing() -> void:
	is_fishing = true
	player.can_move = false
	casting_label.visible = true
	waiting_label.visible = false
	
	await get_tree().create_timer(1.0).timeout
	casting_label.visible = false
	waiting_label.visible = true
	
	fish_wait_duration = randf_range(2.0, 5.0)
	fish_wait_timer = 0.0

func _process(delta: float) -> void:
	if is_fishing and waiting_label.visible:
		fish_wait_timer += delta
		if fish_wait_timer >= fish_wait_duration:
			catch_fish()

func catch_fish() -> void:
	is_fishing = false
	waiting_label.visible = false
	
	var fish_level = randi_range(1, 10)
	var fish_names = ["Bass", "Trout", "Salmon", "Catfish", "Pike"]
	var fish_name = fish_names[randi() % fish_names.size()]
	var fish_health = fish_level * 20
	var fish_max_damage = fish_level * 5
	
	GlobalData.current_fish = {
		"name": fish_name,
		"level": fish_level,
		"health": fish_health,
		"max_health": fish_health,
		"max_damage": fish_max_damage
	}
	GlobalData.rod_durability = 100
	
	get_tree().change_scene_to_file("res://scenes/combat.tscn")

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
