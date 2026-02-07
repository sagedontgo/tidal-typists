extends Button

var slot_index := -1
var _inventory: Node = null
var _item = null

# NEW: Icon display
@onready var icon_rect: TextureRect = null
@onready var count_label: Label = null

func _ready():
	# Setup icon display
	setup_icon_display()
	
	# Add hover effects
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(inventory: Node, index: int) -> void:
	_inventory = inventory
	slot_index = index
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	_refresh()

func setup_icon_display():
	"""Create icon and count label if they don't exist"""
	
	# Create icon TextureRect
	if not has_node("Icon"):
		icon_rect = TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.anchor_right = 1.0
		icon_rect.anchor_bottom = 1.0
		# Add some padding
		icon_rect.offset_left = 4
		icon_rect.offset_top = 4
		icon_rect.offset_right = -4
		icon_rect.offset_bottom = -4
		add_child(icon_rect)
	else:
		icon_rect = get_node("Icon")
	
	# Create count label for stackable items
	if not has_node("CountLabel"):
		count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.anchor_right = 1.0
		count_label.anchor_bottom = 1.0
		count_label.offset_left = -24
		count_label.offset_top = -20
		
		# Style the count
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		count_label.add_theme_constant_override("outline_size", 2)
		
		add_child(count_label)
	else:
		count_label = get_node("CountLabel")

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
	# Make sure we have the visual elements
	if icon_rect == null or count_label == null:
		setup_icon_display()
	
	if _item == null:
		# Empty slot
		if icon_rect:
			icon_rect.texture = null
		if count_label:
			count_label.text = ""
		text = ""  # Clear text as well
		
		# Light color for empty slot
		add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
		return
	
	# Item exists - use warm text color for any text
	add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1.0))
	add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 1.0))
	add_theme_constant_override("outline_size", 2)
	
	# Handle Dictionary items (with icons)
	if _item is Dictionary:
		# Display icon
		if _item.has("icon") and _item.icon != null:
			if icon_rect:
				icon_rect.texture = _item.icon
			text = ""  # No text if we have icon
		else:
			# No icon, show name as text
			if icon_rect:
				icon_rect.texture = null
			if _item.has("name"):
				text = str(_item["name"])
			else:
				text = str(_item)
		
		# Display count for stackable items
		if _item.has("count") and _item.count > 1:
			if count_label:
				count_label.text = str(_item.count)
		else:
			if count_label:
				count_label.text = ""
		
		return
	
	# Handle String items (legacy)
	if _item is String:
		if icon_rect:
			icon_rect.texture = null
		if count_label:
			count_label.text = ""
		text = _item
		return
	
	# Fallback
	if icon_rect:
		icon_rect.texture = null
	if count_label:
		count_label.text = ""
	text = str(_item)

func _on_mouse_entered():
	# Subtle highlight on hover
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	# Return to normal
	modulate = Color(1.0, 1.0, 1.0, 1.0)
