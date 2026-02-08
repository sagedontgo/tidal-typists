extends Control

# Hotbar with LOCKED backpack (slot 9) and map (slot 8)
# Backpack and Map cannot be moved from their slots

signal slot_changed(slot_index: int)
signal item_used(slot_index: int, item)

@onready var slot_container := $HBoxContainer

var _slots: Array[Node] = []
var _items: Array = []
var _current_slot: int = 0

var main_inventory: Node = null
var map_view: Node = null

func _get_main_inventory_script() -> Inventory:
	if main_inventory is Inventory:
		return main_inventory as Inventory

	if main_inventory != null:
		var child := (main_inventory as Node).find_child("Inventory", true, false)
		if child is Inventory:
			return child as Inventory

		for n in (main_inventory as Node).get_children():
			if n is Inventory:
				return n as Inventory

	var cs := get_tree().current_scene
	if cs != null:
		var any_inv := cs.find_child("Inventory", true, false)
		if any_inv is Inventory:
			return any_inv as Inventory

	return null

func _ready() -> void:
	_cache_slots()
	_items.resize(_slots.size())
	refresh()
	update_selection()
	
	print("Hotbar ready with ", _slots.size(), " slots")

func setup_hotbar_items():
	"""Setup hotbar with backpack and map on the right side"""
	
	# Load your pixel art assets - ADJUST THESE PATHS TO YOUR ACTUAL FILE LOCATIONS!
	var backpack_icon = load("res://assets/items/backpack.png")
	var map_icon = load("res://assets/items/map.png")

	
	# Slots 1-7 are empty and available for other items
	
	# Right side - System tools (locked)
	# Slot 8: Map (second from right) - LOCKED
	set_item(7, {
		"name": "Map",
		"type": "tool_map",
		"icon": map_icon,
		"action": "open_map",
		"locked": true
	})
	
	# Slot 9: Backpack (rightmost) - LOCKED
	set_item(8, {
		"name": "Backpack",
		"type": "tool_backpack",
		"icon": backpack_icon,
		"action": "open_inventory",
		"locked": true
	})
	
	print("✅ Hotbar configured: Slots 1-7 free, Map=8, Backpack=9")

func lock_special_items():
	"""Mark slots 8 and 9 as locked - cannot move these items"""
	if _slots.size() > 7:
		_slots[7].set_meta("locked", true)
		print("🔒 Slot 8 (Map) locked")
	if _slots.size() > 8:
		_slots[8].set_meta("locked", true)
		print("🔒 Slot 9 (Backpack) locked")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Check if inventory is open (to prevent duplicate handling)
	var inv := _get_main_inventory_script()
	var inventory_is_open = inv != null and inv.visible
	
	if event is InputEventKey:
		# Prevent WASD/arrow keys from moving focus in hotbar when inventory is closed
		if not inventory_is_open:
			if event.is_action("ui_up") or event.is_action("ui_down") or \
			   event.is_action("ui_left") or event.is_action("ui_right"):
				get_viewport().set_input_as_handled()
				return
		
		if event.pressed and not event.echo:
			var key_code = event.keycode
			
			# Keys 1-9
			if key_code >= KEY_1 and key_code <= KEY_9:
				select_slot(key_code - KEY_1)
				get_viewport().set_input_as_handled()
			# Key 0 (selects slot 9 - the backpack!)
			elif key_code == KEY_0 and _slots.size() >= 10:
				select_slot(9)
				get_viewport().set_input_as_handled()
			# Use item (E key)
			elif key_code == KEY_E:
				use_current_item()
				get_viewport().set_input_as_handled()
	
	# Mouse wheel scrolling
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_slot((_current_slot - 1 + _slots.size()) % _slots.size())
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_slot((_current_slot + 1) % _slots.size())
			get_viewport().set_input_as_handled()

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

func select_slot(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	
	_current_slot = index
	update_selection()
	slot_changed.emit(_current_slot)
	
	var item = get_item(_current_slot)
	if item != null:
		var item_name = _get_item_name(item)
		print("Hotbar selected slot ", _current_slot + 1, ": ", item_name)

func update_selection() -> void:
	for i in range(_slots.size()):
		var slot = _slots[i]
		if i == _current_slot:
			_apply_selected_style(slot)
		else:
			_apply_normal_style(slot)

func _apply_selected_style(slot: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.71, 0.53, 0.35, 0.95)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.95, 0.78, 0.38, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	slot.add_theme_stylebox_override("normal", style)
	slot.add_theme_stylebox_override("hover", style)
	slot.add_theme_stylebox_override("pressed", style)

func _apply_normal_style(slot: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.31, 0.25, 0.20, 0.90)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.45, 0.35, 0.27, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	slot.add_theme_stylebox_override("normal", style)
	slot.add_theme_stylebox_override("hover", style)
	slot.add_theme_stylebox_override("pressed", style)

func use_current_item() -> void:
	var item = get_item(_current_slot)
	if item == null:
		return
	
	if item is Dictionary:
		var action = item.get("action", "")
		
		match action:
			"open_inventory":
				open_inventory()
				return
			"open_map":
				open_map()
				return
	
	item_used.emit(_current_slot, item)
	print("Used item: ", _get_item_name(item))

func open_inventory():
	var inv = _get_main_inventory_script()
	if inv and inv.has_method("toggle_inventory"):
		inv.toggle_inventory()
		print("📦 Opened inventory via backpack!")
	else:
		print("⚠️ Inventory not found!")

func open_map():
	if map_view == null:
		map_view = get_tree().current_scene.find_child("MapView", true, false)
		if map_view == null:
			map_view = get_tree().current_scene.find_child("Map", true, false)
	
	if map_view != null:
		if map_view.has_method("toggle_map"):
			map_view.toggle_map()
		else:
			map_view.visible = not map_view.visible
		print("🗺️ Toggled map view!")
	else:
		print("⚠️ Map view not found!")

func _get_item_name(item) -> String:
	if item is String:
		return item
	if item is Dictionary and item.has("name"):
		return str(item["name"])
	return "Unknown"

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
	# Check if slot is locked before allowing interaction
	if slot_index < _slots.size():
		var slot = _slots[slot_index]
		if slot.get_meta("locked", false):
			print("🔒 This item is locked and cannot be moved!")
			return
	
	select_slot(slot_index)
	
	if main_inventory != null:
		var inv = _get_main_inventory_script()
		if inv != null and inv._held_item != null:
			_handle_inventory_swap(slot_index)
			return
	
	var item = get_item(slot_index)
	if item == null:
		return
	
	if main_inventory != null:
		var inv = _get_main_inventory_script()
		if inv != null:
			inv._held_item = item
			inv._held_from_slot_index = -1
			clear_slot(slot_index)
			inv._update_held_visual()
			print("Picked up from hotbar: ", _get_item_name(item))

func _handle_inventory_swap(slot_index: int) -> void:
	var inv = _get_main_inventory_script()
	if inv == null:
		return
	
	var held = inv._held_item
	var current = get_item(slot_index)
	
	set_item(slot_index, held)
	inv._held_item = current
	
	if current == null:
		inv._clear_held()
		print("Placed ", _get_item_name(held), " into hotbar slot ", slot_index + 1)
	else:
		inv._update_held_visual()
		print("Swapped ", _get_item_name(held), " with ", _get_item_name(current))

func get_current_item():
	return get_item(_current_slot)

# Save/Load hotbar state to GlobalData
func save_to_global() -> void:
	var gd = get_node_or_null("/root/GlobalData")
	if gd != null:
		gd.saved_hotbar_items = _items.duplicate()
		gd.has_initialized_hotbar = true
		print("✅ Saved hotbar items to GlobalData (", _items.size(), " slots)")

func load_from_global() -> bool:
	var gd = get_node_or_null("/root/GlobalData")
	print("📥 Hotbar load_from_global called")
	if gd != null:
		print("  - has_initialized_hotbar: ", gd.has_initialized_hotbar)
		print("  - saved_hotbar_items size: ", gd.saved_hotbar_items.size())
		
		if gd.has_initialized_hotbar:
			# Restore items if array sizes match
			if gd.saved_hotbar_items.size() == _items.size():
				# Use deep copy to avoid reference issues
				_items = []
				for item in gd.saved_hotbar_items:
					if item is Dictionary:
						_items.append(item.duplicate())
					else:
						_items.append(item)
				
				refresh()
				print("✅ Loaded hotbar items from GlobalData")
				# Debug: print items
				for i in range(min(5, _items.size())):
					if _items[i] != null:
						var item_name = _items[i].get("name", "Unknown") if _items[i] is Dictionary else str(_items[i])
						print("    Slot ", i, ": ", item_name)
					else:
						print("    Slot ", i, ": (empty)")
				return true
			else:
				print("⚠️ Hotbar size mismatch, skipping load")
		else:
			print("  - No previous hotbar initialization found")
	return false
