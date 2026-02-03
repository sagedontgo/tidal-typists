extends Panel

signal slot_pressed(slot_index: int, item)

@onready var slot_container := $MarginContainer/SlotContainer

var _slots: Array[Node] = []
var _items: Array = []

const INVENTORY_TOGGLE_ACTION := "inventory_toggle"
const HELD_ITEM_OFFSET := Vector2(16, 16)

var _held_item = null
var _held_from_slot_index := -1 # legacy (kept for now; no longer used for swapping)
var _held_label: Label

func _ready() -> void:
	_ensure_inventory_toggle_keybind()
	_setup_held_label()
	_cache_slots()
	_items.resize(_slots.size())
	refresh()
	
	add_item("Sword")
	add_item("Potion")
	add_item("Shield")
	
	slot_pressed.connect(Callable(self, "_on_slot_clicked"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INVENTORY_TOGGLE_ACTION):
		_toggle_inventory_panel()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if _held_label != null and _held_label.visible:
		_held_label.global_position = get_viewport().get_mouse_position() + HELD_ITEM_OFFSET

func _ensure_inventory_toggle_keybind() -> void:
	if not InputMap.has_action(INVENTORY_TOGGLE_ACTION):
		InputMap.add_action(INVENTORY_TOGGLE_ACTION)
	
	# Bind "I" (physical key) if it isn't already bound.
	for existing in InputMap.action_get_events(INVENTORY_TOGGLE_ACTION):
		if existing is InputEventKey and existing.physical_keycode == KEY_I:
			return
	
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_I
	InputMap.action_add_event(INVENTORY_TOGGLE_ACTION, ev)

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

func _toggle_inventory_panel() -> void:
	# If we're holding an item, try to return it before closing.
	if visible and _held_item != null:
		var empty_index := _find_first_empty_slot()
		if empty_index == -1:
			# No room to return the held item; keep inventory open.
			return
		set_item(empty_index, _held_item)
		_clear_held()
	
	visible = not visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN)
	_update_held_visual()

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
	# Click-to-pick, click-to-place.
	if _held_item == null:
		if item == null:
			return
		
		_held_item = item
		_held_from_slot_index = slot_index
		clear_slot(slot_index)
		_update_held_visual()
		return
	
	# Minecraft-style: place held item into clicked slot, then hold whatever was there.
	var target_item = get_item(slot_index)
	set_item(slot_index, _held_item)
	_held_item = target_item
	if _held_item == null:
		_clear_held()
	else:
		_update_held_visual()
	
