extends Control

# Hotbar for Tidal Typist - Compatible with click-based inventory system
# Uses the same click-to-pick, click-to-place mechanics

signal slot_changed(slot_index: int)
signal item_used(slot_index: int, item)

@onready var slot_container := $HBoxContainer

var _slots: Array[Node] = []
var _items: Array = []
var _current_slot: int = 0

# Reference to the main inventory (for shared held item)
var main_inventory: Node = null

func _ready() -> void:
	_cache_slots()
	_items.resize(_slots.size())
	refresh()
	update_selection()
	
	# Example items for testing
	add_item("Basic Rod")
	add_item("Bait")
	print("Hotbar ready with ", _slots.size(), " slots")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Handle number key presses (1-9, 0)
	if event is InputEventKey and event.pressed and not event.echo:
		var key_code = event.keycode
		
		# Keys 1-9
		if key_code >= KEY_1 and key_code <= KEY_9:
			select_slot(key_code - KEY_1)
			get_viewport().set_input_as_handled()
		# Key 0 (slot 10)
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
	
	# Setup each slot with hotbar reference
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
		var item_name = item if item is String else (item.get("name", "Unknown") if item is Dictionary else "Unknown")
		print("Hotbar selected slot ", _current_slot + 1, ": ", item_name)

func update_selection() -> void:
	# Update visual feedback for all slots
	for i in range(_slots.size()):
		var slot = _slots[i]
		
		# Apply selection style
		if i == _current_slot:
			_apply_selected_style(slot)
		else:
			_apply_normal_style(slot)

func _apply_selected_style(slot: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 1.0, 1.0)
	
	slot.add_theme_stylebox_override("normal", style)
	slot.add_theme_stylebox_override("hover", style)
	slot.add_theme_stylebox_override("pressed", style)

func _apply_normal_style(slot: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4)
	
	slot.add_theme_stylebox_override("normal", style)
	slot.add_theme_stylebox_override("hover", style)
	slot.add_theme_stylebox_override("pressed", style)

func use_current_item() -> void:
	var item = get_item(_current_slot)
	if item != null:
		item_used.emit(_current_slot, item)
		print("Used item from hotbar: ", item)

# Inventory-compatible methods (same API as inventory)
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

# This is called by the slot when clicked (just like inventory)
func _on_slot_pressed(slot_index: int) -> void:
	# First, select the slot
	
	select_slot(slot_index)
	
	# If we have a main_inventory reference and it has a held item,
	# allow placing/swapping with inventory's held item
	if main_inventory != null and main_inventory._held_item != null:
		_handle_inventory_swap(slot_index)
		return
	
	# Otherwise, handle click on hotbar itself (pick up from hotbar)
	var item = get_item(slot_index)
	if item == null:
		return
	
	# If inventory exists, use its held item system
	if main_inventory != null:
		main_inventory._held_item = item
		main_inventory._held_from_slot_index = -1  # -1 means from hotbar
		clear_slot(slot_index)
		main_inventory._update_held_visual()
		print("Picked up from hotbar: ", item)

func _handle_inventory_swap(slot_index: int) -> void:
	"""Handle placing/swapping when inventory has a held item"""
	if main_inventory == null:
		return
	
	var held = main_inventory._held_item
	var current = get_item(slot_index)
	
	# Place held item into hotbar slot
	set_item(slot_index, held)
	
	# Update inventory's held item with what was in the hotbar
	main_inventory._held_item = current
	
	if current == null:
		main_inventory._clear_held()
		print("Placed ", held, " into hotbar slot ", slot_index + 1)
	else:
		main_inventory._update_held_visual()
		print("Swapped ", held, " with ", current, " in hotbar slot ", slot_index + 1)

# Helper to get current item
func get_current_item():
	return get_item(_current_slot)
