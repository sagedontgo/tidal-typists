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

# NEW: Track if opened by backpack (no longer uses 'I' key)
var _opened_by_backpack := false

func _ready() -> void:
	_setup_held_label()
	_cache_slots()
	_items.resize(_slots.size())
	refresh()
	
	# NEW: Add fishing items instead of Sword/Potion/Shield
	add_fishing_items()
	
	slot_pressed.connect(Callable(self, "_on_slot_clicked"))
	
	# Start hidden (will be opened by backpack)
	visible = false

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

func _process(_delta: float) -> void:
	if _held_label != null and _held_label.visible:
		_held_label.global_position = get_viewport().get_mouse_position() + HELD_ITEM_OFFSET

func _setup_held_label() -> void:
	if _held_label != null:
		return
	
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
	print("Inventory ", "opened" if visible else "closed")

func _update_held_visual() -> void:
	if _held_label == null:
		return
	
	_held_label.visible = visible and _held_item != null
	_held_label.text = _item_to_text(_held_item)

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
