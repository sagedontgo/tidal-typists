extends Panel

# Direct references to labels
var name_label: Label = null
var rarity_label: Label = null
var desc_label: Label = null
var _ui_created: bool = false

# Rarity colors
const RARITY_COLORS = {
	"common": Color(0.6, 0.6, 0.6),
	"uncommon": Color(0.2, 0.8, 0.2),
	"rare": Color(0.3, 0.5, 1.0),
	"legendary": Color(1.0, 0.84, 0.0)
}

func _create_ui_if_needed() -> void:
	if _ui_created:
		return
		
	print("🎨 Creating tooltip UI...")
	
	# Clear any existing children first
	for child in get_children():
		child.queue_free()
	
	# Create container structure
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	# Create name label
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(name_label)
	print("  ✅ Name label created:", name_label != null)
	
	# Create rarity label
	rarity_label = Label.new()
	rarity_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(rarity_label)
	print("  ✅ Rarity label created:", rarity_label != null)
	
	# Create description label
	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(150, 0)
	vbox.add_child(desc_label)
	print("  ✅ Desc label created:", desc_label != null)
	
	_ui_created = true
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000
	
	print("✅ Tooltip UI creation complete!")

func show_tooltip(item, mouse_pos: Vector2) -> void:
	print("\n🎯 show_tooltip called")
	print("  Item:", item)
	print("  _ui_created:", _ui_created)
	
	# Create UI on first use
	_create_ui_if_needed()
	
	if item == null:
		print("  Item is null, hiding")
		hide()
		return
	
	# Double-check labels exist
	print("  Checking labels...")
	print("    name_label:", name_label)
	print("    rarity_label:", rarity_label)
	print("    desc_label:", desc_label)
	
	if name_label == null or rarity_label == null or desc_label == null:
		push_error("❌ Tooltip labels are STILL null after creation!")
		push_error("  This means _create_ui_if_needed() failed somehow")
		return
	
	print("  ✅ All labels valid, setting content...")
	
	# Handle Dictionary items
	if item is Dictionary:
		var item_name = item.get("name", "Unknown Item")
		var item_type = item.get("type", "")
		var rarity = item.get("rarity", "")
		var description = item.get("description", "")
		
		print("  Setting name to:", item_name)
		name_label.text = item_name
		
		# Set rarity for fish
		if item_type == "fish" and rarity != "":
			rarity_label.text = "Rarity: " + rarity.capitalize()
			rarity_label.visible = true
			
			if rarity in RARITY_COLORS:
				rarity_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
		else:
			rarity_label.visible = false
		
		# Set description
		if item_type == "fishing_rod":
			var power = item.get("power", 0)
			var durability = item.get("durability", 0)
			desc_label.text = "Power: %d\nDurability: %d%%" % [power, durability]
			desc_label.visible = true
		elif item_type == "bait":
			var count = item.get("count", 0)
			desc_label.text = "Quantity: %d" % count
			desc_label.visible = true
		elif item_type == "fish":
			var level = item.get("level", 1)
			if description != "":
				desc_label.text = description + "\nLevel: %d" % level
			else:
				desc_label.text = "Level: %d" % level
			desc_label.visible = true
		elif description != "":
			desc_label.text = description
			desc_label.visible = true
		else:
			desc_label.visible = false
	
	# Handle String items
	elif item is String:
		name_label.text = item
		rarity_label.visible = false
		desc_label.visible = false
	
	print("  Positioning...")
	position_tooltip(mouse_pos)
	print("  Showing...")
	show()
	print("✅ Tooltip shown!\n")

func position_tooltip(mouse_pos: Vector2) -> void:
	var offset = Vector2(15, 15)
	global_position = mouse_pos + offset
	
	# Keep within screen bounds
	await get_tree().process_frame
	
	var viewport_size = get_viewport_rect().size
	var tooltip_size = size
	
	if global_position.x + tooltip_size.x > viewport_size.x:
		global_position.x = mouse_pos.x - tooltip_size.x - 5
	
	if global_position.y + tooltip_size.y > viewport_size.y:
		global_position.y = mouse_pos.y - tooltip_size.y - 5

func hide_tooltip() -> void:
	hide()
