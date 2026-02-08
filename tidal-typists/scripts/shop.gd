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
	# CRITICAL FIX: Make sure CurrentEquipment label exists
	if current_equipment_label == null:
		print("⚠️ CurrentEquipment label not found! Creating it...")
		create_equipment_label()
	
	create_feedback_label()
	populate_shop()
	update_displays()  # This will now show equipment!
	
	buy_rod_button.pressed.connect(on_buy_rod)
	repair_rod_button.pressed.connect(on_repair_rod)
	buy_bait_button.pressed.connect(on_buy_bait)
	sell_fish_button.pressed.connect(on_sell_fish)
	close_button.pressed.connect(on_close_shop)
	
	print("🏪 Shop ready! Equipment should be visible now.")

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
	# Rod shop
	rod_list.clear()
	for rod in GlobalData.rod_shop_inventory:
		var is_current = rod["name"] == GlobalData.current_rod.get("name", "")
		var prefix = "[EQUIPPED] " if is_current else ""
		var boosts = ""
		if rod.get("rarity_boost", 0) > 0 or rod.get("level_boost", 0) > 0:
			boosts = " (+%d%% rare, +%d lvl)" % [rod.get("rarity_boost", 0), rod.get("level_boost", 0)]
		var text = "%s%s - %d coins (Max HP: %d%s)" % [prefix, rod["name"], rod["price"], rod["max_durability"], boosts]
		rod_list.add_item(text)
	
	# Bait shop
	bait_list.clear()
	for bait in GlobalData.bait_shop_inventory:
		var is_current = bait["name"] == GlobalData.current_bait.get("name", "")
		var prefix = "[EQUIPPED] " if is_current else ""
		var boosts = ""
		if bait.get("rarity_boost", 0) > 0 or bait.get("level_boost", 0) > 0:
			boosts = " (+%d%% rare, +%d lvl)" % [bait.get("rarity_boost", 0), bait.get("level_boost", 0)]
		var text = "%s%s - %d coins (Uses: %d%s)" % [prefix, bait["name"], bait["price"], bait["max_uses"], boosts]
		bait_list.add_item(text)
	
	# Fish sell list
	fish_list.clear()
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item.get("type") == "fish":
			var value = GlobalData.calculate_fish_value(item)
			var text = "%s Lv.%d [%s] - %d coins" % [item["name"], item["level"], item["rarity"].to_upper(), value]
			fish_list.add_item(text)
			fish_list.set_item_metadata(fish_list.get_item_count() - 1, i)

func update_displays():
	"""Update money and equipment displays"""
	update_money_display()
	update_equipment_display()

func update_money_display() -> void:
	if money_label:
		money_label.text = "💰 Money: %d coins" % GlobalData.player_money

func update_equipment_display():
	"""Show current rod and bait info - FIXED VERSION"""
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
		print("✅ Equipment display updated: ", current_equipment_label.text)
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
			# EXPLOIT FIX: Don't reset max_uses
			show_feedback("✅ Refilled %s (+%d uses)!" % [bait["name"], bait["max_uses"]], false)
			print("✅ Refilled %s with %d more uses (total: %d)" % [bait["name"], bait["max_uses"], GlobalData.current_bait["uses_remaining"]])
		else:
			GlobalData.current_bait = bait.duplicate()
			GlobalData.current_bait["uses_remaining"] = bait["max_uses"]
			show_feedback("✅ Purchased %s!" % bait["name"], false)
			print("✅ Purchased %s for %d coins" % [bait["name"], bait["price"]])
		
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
	SceneTransition.fade_to_scene("res://scenes/game.tscn")
