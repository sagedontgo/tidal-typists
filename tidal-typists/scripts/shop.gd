extends Control

@onready var rod_list = $VBoxContainer/HBoxContainer/RodShop/RodList
@onready var bait_list = $VBoxContainer/HBoxContainer/BaitShop/BaitList
@onready var fish_list = $VBoxContainer/HBoxContainer/SellShop/FishList
@onready var money_label = $VBoxContainer/MoneyLabel
@onready var current_equipment_label = $VBoxContainer/CurrentEquipment
@onready var buy_rod_button = $VBoxContainer/HBoxContainer/RodShop/BuyRodButton
@onready var repair_rod_button = $VBoxContainer/HBoxContainer/RodShop/RepairRodButton
@onready var buy_bait_button = $VBoxContainer/HBoxContainer/BaitShop/BuyBaitButton
@onready var sell_fish_button = $VBoxContainer/HBoxContainer/SellShop/SellFishButton
@onready var close_button = $VBoxContainer/CloseButton

var feedback_label: Label

func _ready() -> void:
	# *** FIX: Show normal cursor when shop opens ***
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("🖱️ Cursor set to visible for shop")
	
	# Set minimum sizes for ItemLists so they're visible
	if rod_list:
		rod_list.custom_minimum_size = Vector2(300, 200)
		print("✅ Rod list size set")
	
	if bait_list:
		bait_list.custom_minimum_size = Vector2(300, 200)
		print("✅ Bait list size set")
	
	if fish_list:
		fish_list.custom_minimum_size = Vector2(300, 200)
		print("✅ Fish list size set")
	
	# Make sure CurrentEquipment label exists
	if current_equipment_label == null:
		print("⚠️ CurrentEquipment label not found! Creating it...")
		create_equipment_label()
	
	create_feedback_label()
	populate_shop()
	update_displays()
	
	buy_rod_button.pressed.connect(on_buy_rod)
	repair_rod_button.pressed.connect(on_repair_rod)
	buy_bait_button.pressed.connect(on_buy_bait)
	sell_fish_button.pressed.connect(on_sell_fish)
	close_button.pressed.connect(on_close_shop)
	
	print("🏪 Shop ready!")

func create_equipment_label():
	"""Create CurrentEquipment label if missing"""
	var vbox = get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	
	current_equipment_label = Label.new()
	current_equipment_label.name = "CurrentEquipment"
	current_equipment_label.text = "Current Equipment: Loading..."
	current_equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(current_equipment_label)
	vbox.move_child(current_equipment_label, 2)  # After MoneyLabel

func create_feedback_label():
	"""Create a label for shop feedback messages"""
	feedback_label = Label.new()
	feedback_label.name = "FeedbackLabel"
	feedback_label.text = ""
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
	
	var vbox = get_node_or_null("VBoxContainer")
	if vbox:
		vbox.add_child(feedback_label)
		vbox.move_child(feedback_label, 3)  # After CurrentEquipment
	else:
		add_child(feedback_label)

func show_feedback(message: String, is_error: bool = false):
	"""Show temporary feedback message"""
	if feedback_label:
		feedback_label.text = message
		if is_error:
			feedback_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		else:
			feedback_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
		
		await get_tree().create_timer(3.0).timeout
		if feedback_label:
			feedback_label.text = ""

func populate_shop() -> void:
	print("\n🏪 === POPULATING SHOP ===")
	
	# Rod shop
	rod_list.clear()
	print("📊 Rod inventory size: ", GlobalData.rod_shop_inventory.size())
	for rod in GlobalData.rod_shop_inventory:
		var is_current = rod["name"] == GlobalData.current_rod.get("name", "")
		var prefix = "[EQUIPPED] " if is_current else ""
		var boosts = ""
		if rod.get("rarity_boost", 0) > 0 or rod.get("level_boost", 0) > 0:
			boosts = " (+%d%% rare, +%d lvl)" % [rod.get("rarity_boost", 0), rod.get("level_boost", 0)]
		var text = "%s%s - %d coins (Max HP: %d%s)" % [prefix, rod["name"], rod["price"], rod["max_durability"], boosts]
		rod_list.add_item(text)
		print("  Added rod: ", text)
	
	# Bait shop
	bait_list.clear()
	print("📊 Bait inventory size: ", GlobalData.bait_shop_inventory.size())
	for bait in GlobalData.bait_shop_inventory:
		var is_current = bait["name"] == GlobalData.current_bait.get("name", "")
		var prefix = "[EQUIPPED] " if is_current else ""
		var boosts = ""
		if bait.get("rarity_boost", 0) > 0 or bait.get("level_boost", 0) > 0:
			boosts = " (+%d%% rare, +%d lvl)" % [bait.get("rarity_boost", 0), bait.get("level_boost", 0)]
		var text = "%s%s - %d coins (Uses: %d%s)" % [prefix, bait["name"], bait["price"], bait["max_uses"], boosts]
		bait_list.add_item(text)
		print("  Added bait: ", text)
	
	# Fish sell list
	fish_list.clear()
	print("📊 Checking inventory for fish...")
	var fish_count = 0
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item.get("type") == "fish":
			var value = GlobalData.calculate_fish_value(item)
			var text = "%s Lv.%d [%s] - %d coins" % [item["name"], item["level"], item["rarity"].to_upper(), value]
			fish_list.add_item(text)
			fish_list.set_item_metadata(fish_list.get_item_count() - 1, i)
			fish_count += 1
			print("  Added fish: ", text)
	
	print("✅ Shop populated: %d rods, %d baits, %d fish" % [rod_list.get_item_count(), bait_list.get_item_count(), fish_count])
	print("=== POPULATION COMPLETE ===\n")

func update_displays():
	"""Update money and equipment displays"""
	update_money_display()
	update_equipment_display()

func update_money_display() -> void:
	if money_label:
		money_label.text = "💰 Money: %d coins" % GlobalData.player_money

func update_equipment_display():
	"""Show current rod and bait info"""
	if current_equipment_label:
		var rod_info = "🎣 Rod: %s (%d/%d HP)" % [
			GlobalData.current_rod.get("name", "None"),
			GlobalData.current_rod.get("current_durability", 0),
			GlobalData.current_rod.get("max_durability", 100)
		]
		var bait_info = "🪱 Bait: %s (%d uses)" % [
			GlobalData.current_bait.get("name", "None"),
			GlobalData.current_bait.get("uses_remaining", 0)
		]
		current_equipment_label.text = rod_info + " | " + bait_info
		print("✅ Equipment display: ", current_equipment_label.text)
	else:
		print("❌ CurrentEquipment label not found!")

func on_buy_rod() -> void:
	var selected = rod_list.get_selected_items()
	if selected.size() == 0:
		show_feedback("⚠️ Select a rod first!", true)
		return
	
	var rod_index = selected[0]
	var rod = GlobalData.rod_shop_inventory[rod_index]
	
	if rod["name"] == GlobalData.current_rod.get("name", ""):
		show_feedback("⚠️ You already have this rod!", true)
		return
	
	if GlobalData.player_money >= rod["price"]:
		GlobalData.player_money -= rod["price"]
		GlobalData.current_rod = rod.duplicate()
		GlobalData.current_rod["current_durability"] = rod["max_durability"]
		GlobalData.rod_durability = rod["max_durability"]
		
		# Update rod in inventory and hotbar
		update_rod_in_saved_items(rod)
		
		show_feedback("✅ Purchased %s!" % rod["name"], false)
		print("✅ Purchased %s for %d coins" % [rod["name"], rod["price"]])
		
		populate_shop()
		update_displays()
	else:
		var needed = rod["price"] - GlobalData.player_money
		show_feedback("⚠️ Need %d more coins!" % needed, true)

func on_repair_rod() -> void:
	var current_dur = GlobalData.current_rod.get("current_durability", 0)
	var max_dur = GlobalData.current_rod.get("max_durability", 100)
	
	if current_dur >= max_dur:
		show_feedback("⚠️ Rod is already at full health!", true)
		return
	
	var repair_cost = calculate_repair_cost()
	
	if GlobalData.player_money >= repair_cost:
		GlobalData.player_money -= repair_cost
		GlobalData.current_rod["current_durability"] = max_dur
		GlobalData.rod_durability = max_dur
		
		# Update durability in saved items
		update_rod_durability_in_saved_items(max_dur)
		
		show_feedback("✅ Rod repaired to full health!", false)
		print("✅ Repaired rod for %d coins" % repair_cost)
		
		update_displays()
	else:
		var needed = repair_cost - GlobalData.player_money
		show_feedback("⚠️ Need %d more coins to repair!" % needed, true)

func calculate_repair_cost() -> int:
	"""Calculate repair cost based on damage"""
	var current_dur = GlobalData.current_rod.get("current_durability", 0)
	var max_dur = GlobalData.current_rod.get("max_durability", 100)
	var damage = max_dur - current_dur
	
	return max(10, damage)

func on_buy_bait() -> void:
	var selected = bait_list.get_selected_items()
	if selected.size() == 0:
		show_feedback("⚠️ Select bait first!", true)
		return
	
	var bait_index = selected[0]
	var bait = GlobalData.bait_shop_inventory[bait_index]
	
	if GlobalData.player_money >= bait["price"]:
		GlobalData.player_money -= bait["price"]
		
		# If same bait type, add uses instead of replacing
		if bait["name"] == GlobalData.current_bait.get("name", ""):
			GlobalData.current_bait["uses_remaining"] += bait["max_uses"]
			show_feedback("✅ Refilled %s (+%d uses)!" % [bait["name"], bait["max_uses"]], false)
			print("✅ Refilled %s with %d more uses (total: %d)" % [bait["name"], bait["max_uses"], GlobalData.current_bait["uses_remaining"]])
			# Update count in saved items
			update_bait_in_saved_items(bait)
		else:
			GlobalData.current_bait = bait.duplicate()
			GlobalData.current_bait["uses_remaining"] = bait["max_uses"]
			show_feedback("✅ Purchased %s!" % bait["name"], false)
			print("✅ Purchased %s for %d coins" % [bait["name"], bait["price"]])
			# Update bait in saved items
			update_bait_in_saved_items(bait)
		
		populate_shop()
		update_displays()
	else:
		var needed = bait["price"] - GlobalData.player_money
		show_feedback("⚠️ Need %d more coins!" % needed, true)

func on_sell_fish() -> void:
	var selected = fish_list.get_selected_items()
	if selected.size() == 0:
		show_feedback("⚠️ Select a fish first!", true)
		return
	
	var list_index = selected[0]
	var inventory_index = fish_list.get_item_metadata(list_index)
	var fish = GlobalData.saved_inventory_items[inventory_index]
	
	if fish != null:
		var value = GlobalData.calculate_fish_value(fish)
		GlobalData.player_money += value
		GlobalData.saved_inventory_items[inventory_index] = null
		
		show_feedback("✅ Sold %s for %d coins!" % [fish["name"], value], false)
		print("✅ Sold %s Lv.%d [%s] for %d coins" % [fish["name"], fish["level"], fish["rarity"], value])
		
		populate_shop()
		update_displays()

func on_close_shop() -> void:
	print("🏪 Closing shop, returning to game...")
	# *** FIX: Restore hidden cursor when leaving shop ***
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	print("🖱️ Cursor hidden for game world")
	SceneTransition.fade_to_scene("res://scenes/game.tscn")

func update_rod_in_saved_items(new_rod: Dictionary) -> void:
	"""Update the fishing rod in both saved_inventory_items and saved_hotbar_items"""
	print("\n🔧 === UPDATING ROD IN SAVED ITEMS ===")
	print("New rod: ", new_rod.get("name"), " (Max durability: ", new_rod.get("max_durability"), ")")
	
	var rod_icon = load(new_rod.get("icon_path", "res://assets/items/rods/basic_rod.png"))
	
	# Create the new rod item
	var new_rod_item = {
		"name": new_rod.get("name"),
		"type": "fishing_rod",
		"icon": rod_icon,
		"power": new_rod.get("power", 10),
		"durability": new_rod.get("max_durability"),
		"max_durability": new_rod.get("max_durability"),
		"rarity_boost": new_rod.get("rarity_boost", 0),
		"level_boost": new_rod.get("level_boost", 0),
		"description": new_rod.get("description", "A fishing rod.")
	}
	
	var found_in_inventory = false
	var found_in_hotbar = false
	
	# Update in inventory
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "fishing_rod":
				print("  Found rod in inventory slot ", i, ": ", item.get("name"))
				GlobalData.saved_inventory_items[i] = new_rod_item.duplicate()
				print("  ✅ Replaced with: ", new_rod_item.get("name"))
				found_in_inventory = true
				break
	
	# Update in hotbar
	for i in range(GlobalData.saved_hotbar_items.size()):
		var item = GlobalData.saved_hotbar_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "fishing_rod":
				print("  Found rod in hotbar slot ", i, ": ", item.get("name"))
				GlobalData.saved_hotbar_items[i] = new_rod_item.duplicate()
				print("  ✅ Replaced with: ", new_rod_item.get("name"))
				found_in_hotbar = true
				break
	
	if not found_in_inventory and not found_in_hotbar:
		print("  ⚠️ No existing rod found, adding to first empty inventory slot...")
		for i in range(GlobalData.saved_inventory_items.size()):
			if GlobalData.saved_inventory_items[i] == null:
				GlobalData.saved_inventory_items[i] = new_rod_item.duplicate()
				print("  ✅ Added to inventory slot ", i)
				found_in_inventory = true
				break
	
	print("=== ROD UPDATE COMPLETE ===\n")

func update_bait_in_saved_items(new_bait: Dictionary) -> void:
	"""Update the bait in both saved_inventory_items and saved_hotbar_items"""
	print("\n🪱 === UPDATING BAIT IN SAVED ITEMS ===")
	print("New bait: ", new_bait.get("name"), " (Uses: ", GlobalData.current_bait.get("uses_remaining"), ")")
	
	var bait_icon = load(new_bait.get("icon_path", "res://assets/items/baits/basic_bait.png"))
	
	# Create the new bait item
	var new_bait_item = {
		"name": new_bait.get("name"),
		"type": "bait",
		"icon": bait_icon,
		"count": GlobalData.current_bait.get("uses_remaining"),
		"stackable": true,
		"max_stack": 99,
		"rarity_boost": new_bait.get("rarity_boost", 0),
		"level_boost": new_bait.get("level_boost", 0),
		"description": new_bait.get("description", "Bait for fishing.")
	}
	
	var found_in_inventory = false
	var found_in_hotbar = false
	
	# Update in inventory
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "bait":
				print("  Found bait in inventory slot ", i, ": ", item.get("name"))
				GlobalData.saved_inventory_items[i] = new_bait_item.duplicate()
				print("  ✅ Replaced with: ", new_bait_item.get("name"))
				found_in_inventory = true
				break
	
	# Update in hotbar
	for i in range(GlobalData.saved_hotbar_items.size()):
		var item = GlobalData.saved_hotbar_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "bait":
				print("  Found bait in hotbar slot ", i, ": ", item.get("name"))
				GlobalData.saved_hotbar_items[i] = new_bait_item.duplicate()
				print("  ✅ Replaced with: ", new_bait_item.get("name"))
				found_in_hotbar = true
				break
	
	if not found_in_inventory and not found_in_hotbar:
		print("  ⚠️ No existing bait found, adding to first empty inventory slot...")
		for i in range(GlobalData.saved_inventory_items.size()):
			if GlobalData.saved_inventory_items[i] == null:
				GlobalData.saved_inventory_items[i] = new_bait_item.duplicate()
				print("  ✅ Added to inventory slot ", i)
				found_in_inventory = true
				break
	
	print("=== BAIT UPDATE COMPLETE ===\n")

func update_rod_durability_in_saved_items(new_durability: int) -> void:
	"""Update rod durability in saved items (used for repairs)"""
	print("\n🔧 === UPDATING ROD DURABILITY IN SAVED ITEMS ===")
	print("New durability: ", new_durability)
	
	# Update in inventory
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "fishing_rod":
				item["durability"] = new_durability
				print("  ✅ Updated rod durability in inventory slot ", i)
	
	# Update in hotbar
	for i in range(GlobalData.saved_hotbar_items.size()):
		var item = GlobalData.saved_hotbar_items[i]
		if item != null and item is Dictionary:
			if item.get("type") == "fishing_rod":
				item["durability"] = new_durability
				print("  ✅ Updated rod durability in hotbar slot ", i)
	
	print("=== DURABILITY UPDATE COMPLETE ===\n")
