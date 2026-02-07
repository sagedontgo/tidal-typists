class_name Inventory
extends Panel

signal slot_pressed(slot_index: int, item)

@export var main_inventory: Inventory
@onready var slot_container := $MarginContainer/SlotContainer

var _slots: Array[Node] = []
var _items: Array = []

const HELD_ITEM_OFFSET := Vector2(16, 16)

var _held_item = null
var _held_from_slot_index := -1
var _held_label: Label
var _held_icon: TextureRect

func _ready() -> void:
	print("🔧 Inventory._ready() called - Node: ", get_path())
	_setup_held_visual_nodes()
	_cache_slots()
	_items.resize(_slots.size())
	print("  - Resized _items to ", _items.size(), " slots (all null)")
	refresh()
	
	slot_pressed.connect(Callable(self, "_on_slot_clicked"))
	
	# Start hidden (will be opened by backpack)
	visible = false
	print("  - Inventory ready, waiting for game.gd to load saved data")

func add_fishing_items():
	"""Add starting fishing items to inventory"""
	
	# Load your pixel art assets
	var basic_rod_icon = load("res://assets/items/basic_rod.png")  # Adjust path!
	var basic_bait_icon = load("res://assets/items/basic_bait.png")  # Adjust path!
	
	# Add Basic Fishing Rod
	add_item({
		"name": "Basic Rod",
		"type": "fishing_rod",
		"icon": basic_rod_icon,
		"power": 10,
		"durability": 100
	})
	
	# Add Basic Bait (stackable)
	add_item({
		"name": "Basic Bait",
		"type": "bait",
		"icon": basic_bait_icon,
		"count": 20,
		"stackable": true,
		"max_stack": 99
	})
	
	print("✅ Added fishing items to inventory")

func _input(event: InputEvent) -> void:
	# Prevent WASD and arrow keys from moving focus in inventory
	if visible and event is InputEventKey:
		if event.is_action("ui_up") or event.is_action("ui_down") or \
		   event.is_action("ui_left") or event.is_action("ui_right"):
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Update held item visual position to follow mouse cursor
	if _held_icon != null and _held_icon.visible:
		_held_icon.global_position = get_viewport().get_mouse_position() + HELD_ITEM_OFFSET
	if _held_label != null and _held_label.visible:
		_held_label.global_position = get_viewport().get_mouse_position() + HELD_ITEM_OFFSET

func _setup_held_visual_nodes() -> void:
	if _held_icon != null:
		return
	
	# Create TextureRect to show item icon when holding
	_held_icon = TextureRect.new()
	_held_icon.name = "HeldItemIcon"
	_held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_icon.z_index = 999
	_held_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_held_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_held_icon.custom_minimum_size = Vector2(32, 32)  # Icon size
	_held_icon.visible = false
	add_child(_held_icon)
	
	# Create Label as fallback for items without icons
	_held_label = Label.new()
	_held_label.name = "HeldItemLabel"
	_held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_label.z_index = 999
	_held_label.visible = false
	add_child(_held_label)
	
	set_process(true)

# NEW: Open/close inventory (called by backpack item)
func toggle_inventory():
	if visible and _held_item != null:
		# Try to return held item before closing
		var empty_index := _find_first_empty_slot()
		if empty_index == -1:
			return  # Keep open if can't return item
		set_item(empty_index, _held_item)
		_clear_held()
	
	visible = not visible
	_update_held_visual()
	
	# Switch cursor mode when opening/closing inventory
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show normal cursor
		_hide_custom_cursor(true)  # Hide custom cursor sprite
		print("Inventory opened - Normal cursor active")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide OS cursor
		_hide_custom_cursor(false)  # Show custom cursor sprite
		print("Inventory closed - Custom cursor active")
	
	print("Inventory ", "opened" if visible else "closed")

func _hide_custom_cursor(should_hide: bool) -> void:
	# Find and hide/show the custom cursor sprite
	var scene = get_tree().current_scene
	if scene != null:
		var cursor = scene.get_node_or_null("Cursor")
		if cursor != null:
			cursor.visible = not should_hide

func _update_held_visual() -> void:
	if _held_icon == null or _held_label == null:
		return
	
	# If we have an item being held
	if visible and _held_item != null:
		# Check if item has an icon (texture)
		if _held_item is Dictionary and _held_item.has("icon") and _held_item["icon"] != null:
			# Show the icon
			_held_icon.texture = _held_item["icon"]
			_held_icon.visible = true
			_held_label.visible = false
		else:
			# Show text label as fallback
			_held_icon.visible = false
			_held_label.visible = true
			_held_label.text = _item_to_text(_held_item)
	else:
		# Nothing held, hide both
		_held_icon.visible = false
		_held_label.visible = false

func _clear_held() -> void:
	_held_item = null
	_held_from_slot_index = -1
	_update_held_visual()

func _item_to_text(item) -> String:
	if item == null:
		return ""
	if item is String:
		return item
	if item is Dictionary and item.has("name"):
		return str(item["name"])
	return str(item)

func _cache_slots() -> void:
	_slots.clear()
	
	for child in slot_container.get_children():
		_slots.append(child)
	
	for i in range(_slots.size()):
		var slot = _slots[i]
		if slot.has_method("setup"):
			slot.setup(self, i)

func refresh() -> void:
	for i in range(_slots.size()):
		_update_slot(i)

func get_slot_count() -> int:
	return _slots.size()

func get_item(slot_index: int):
	if slot_index < 0 or slot_index >= _items.size():
		return null
	return _items[slot_index]

func set_item(slot_index: int, item) -> void:
	if slot_index < 0 or slot_index >= _items.size():
		return
	_items[slot_index] = item
	_update_slot(slot_index)

func clear_slot(slot_index: int) -> void:
	set_item(slot_index, null)

func add_item(item) -> bool:
	var empty_index := _find_first_empty_slot()
	if empty_index == -1:
		return false
	set_item(empty_index, item)
	return true

func swap_slots(a: int, b: int) -> void:
	if a < 0 or b < 0:
		return
	if a >= _items.size() or b >= _items.size():
		return
	
	var tmp = _items[a]
	_items[a] = _items[b]
	_items[b] = tmp
	
	_update_slot(a)
	_update_slot(b)

func _find_first_empty_slot() -> int:
	for i in range(_items.size()):
		if _items[i] == null:
			return i
	return -1

func _update_slot(slot_index: int) -> void:
	var slot = _slots[slot_index]
	if slot.has_method("set_item"):
		slot.set_item(_items[slot_index])

func _on_slot_pressed(slot_index: int) -> void:
	slot_pressed.emit(slot_index, get_item(slot_index))
	
func _on_slot_clicked(slot_index: int, item) -> void:
	# Click-to-pick, click-to-place
	if _held_item == null:
		if item == null:
			return
		
		_held_item = item
		_held_from_slot_index = slot_index
		clear_slot(slot_index)
		_update_held_visual()
		return
	
	# Place held item into clicked slot
	var target_item = get_item(slot_index)
	set_item(slot_index, _held_item)
	_held_item = target_item
	if _held_item == null:
		_clear_held()
	else:
		_update_held_visual()

# Save/Load inventory state to GlobalData
func save_to_global() -> void:
	var gd = get_node_or_null("/root/GlobalData")
	if gd != null:
		gd.saved_inventory_items = _items.duplicate()
		gd.has_initialized_inventory = true
		print("💾 === SAVING INVENTORY TO GLOBALDATA ===")
		print("  - Total slots: ", _items.size())
		print("  - has_initialized_inventory set to: true")
		# Show first few items being saved
		for i in range(min(5, _items.size())):
			if _items[i] != null:
				var item_name = _items[i].get("name", "Unknown") if _items[i] is Dictionary else str(_items[i])
				print("    Slot ", i, ": ", item_name)
			else:
				print("    Slot ", i, ": empty")
		print("=== SAVE COMPLETE ===\n")

func load_from_global() -> bool:
	var gd = get_node_or_null("/root/GlobalData")
	print("📥 load_from_global called")
	print("  - GlobalData exists: ", gd != null)
	if gd != null:
		print("  - has_initialized_inventory: ", gd.has_initialized_inventory)
		print("  - saved_inventory_items size: ", gd.saved_inventory_items.size())
		print("  - current _items size: ", _items.size())
		
		if gd.has_initialized_inventory:
			# Restore items if array sizes match
			if gd.saved_inventory_items.size() == _items.size():
				# Use deep copy to avoid reference issues
				_items = []
				for item in gd.saved_inventory_items:
					if item is Dictionary:
						_items.append(item.duplicate())
					else:
						_items.append(item)
				
				refresh()
				print("✅ Loaded inventory items from GlobalData")
				# Debug: print first few items
				for i in range(min(5, _items.size())):
					if _items[i] != null:
						var item_name = _items[i].get("name", "Unknown") if _items[i] is Dictionary else str(_items[i])
						print("    Slot ", i, ": ", item_name)
					else:
						print("    Slot ", i, ": (empty)")
				return true
			else:
				print("⚠️ Inventory size mismatch, skipping load (saved:", gd.saved_inventory_items.size(), " vs current:", _items.size(), ")")
		else:
			print("  - No previous inventory initialization found")
	return false
