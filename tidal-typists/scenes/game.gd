extends Node2D

var hud = null
var inventory = null
var hotbar = null

func _ready():
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

func _on_hotbar_slot_changed(slot_index: int):
	if hotbar == null:
		return
	
	var item = hotbar.get_item(slot_index)
	if item != null:
		var name = item if item is String else (item.get("name", "Unknown") if item is Dictionary else "Unknown")
		print("🎯 Selected slot ", slot_index + 1, ": ", name)

func _on_hotbar_item_used(slot_index: int, item):
	if item == null:
		return
	
	var name = item if item is String else (item.get("name", "Unknown") if item is Dictionary else "Unknown")
	print("⚡ Used ", name, " from slot ", slot_index + 1)
