extends Button

var slot_index := -1
var _inventory: Node = null
var _item = null

func setup(inventory: Node, index: int) -> void:
	_inventory = inventory
	slot_index = index
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	_refresh()

func set_item(item) -> void:
	_item = item
	_refresh()

func get_item():
	return _item

func _on_pressed() -> void:
	if _inventory == null:
		return
	
	if _inventory.has_method("_on_slot_pressed"):
		_inventory._on_slot_pressed(slot_index)

func _refresh() -> void:
	if _item == null:
		text = ""
		# Light color for empty slot
		add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
		return
	
	# Item exists - use warm text color
	add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1.0))  # Warm cream
	
	# Add text outline for readability
	add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 1.0))  # Dark brown
	add_theme_constant_override("outline_size", 2)
	
	if _item is String:
		text = _item
		return
	
	if _item is Dictionary and _item.has("name"):
		text = str(_item["name"])
		return
	
	text = str(_item)
	
	# Add hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	# Subtle highlight on hover
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	# Return to normal
	modulate = Color(1.0, 1.0, 1.0, 1.0)
