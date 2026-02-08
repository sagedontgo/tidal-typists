extends Control

@onready var rod_list = $VBoxContainer/HBoxContainer/RodShop/RodList
@onready var bait_list = $VBoxContainer/HBoxContainer/BaitShop/BaitList
@onready var fish_list = $VBoxContainer/HBoxContainer/SellShop/FishList
@onready var money_label = $VBoxContainer/MoneyLabel
@onready var buy_rod_button = $VBoxContainer/HBoxContainer/RodShop/BuyRodButton
@onready var repair_rod_button = $VBoxContainer/HBoxContainer/RodShop/RepairRodButton
@onready var buy_bait_button = $VBoxContainer/HBoxContainer/BaitShop/BuyBaitButton
@onready var sell_fish_button = $VBoxContainer/HBoxContainer/SellShop/SellFishButton
@onready var close_button = $VBoxContainer/CloseButton

func _ready() -> void:
	populate_shop()
	update_money_display()
	
	buy_rod_button.pressed.connect(on_buy_rod)
	repair_rod_button.pressed.connect(on_repair_rod)
	buy_bait_button.pressed.connect(on_buy_bait)
	sell_fish_button.pressed.connect(on_sell_fish)
	close_button.pressed.connect(on_close_shop)

func populate_shop() -> void:
	rod_list.clear()
	for rod in GlobalData.rod_shop_inventory:
		var text = "%s - %d coins (Durability: %d)" % [rod["name"], rod["price"], rod["max_durability"]]
		rod_list.add_item(text)
	
	bait_list.clear()
	for bait in GlobalData.bait_shop_inventory:
		var text = "%s - %d coins (Uses: %d)" % [bait["name"], bait["price"], bait["max_uses"]]
		bait_list.add_item(text)
	
	fish_list.clear()
	for i in range(GlobalData.saved_inventory_items.size()):
		var item = GlobalData.saved_inventory_items[i]
		if item != null and item.get("type") == "fish":
			var value = GlobalData.calculate_fish_value(item)
			var text = "%s Lv.%d [%s] - %d coins" % [item["name"], item["level"], item["rarity"], value]
			fish_list.add_item(text)
			fish_list.set_item_metadata(fish_list.get_item_count() - 1, i)

func update_money_display() -> void:
	money_label.text = "Money: %d coins" % GlobalData.player_money

func on_buy_rod() -> void:
	var selected = rod_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var rod_index = selected[0]
	var rod = GlobalData.rod_shop_inventory[rod_index]
	
	if GlobalData.player_money >= rod["price"]:
		GlobalData.player_money -= rod["price"]
		GlobalData.current_rod = rod.duplicate()
		GlobalData.current_rod["current_durability"] = rod["max_durability"]
		print("✅ Purchased %s" % rod["name"])
		update_money_display()
	else:
		print("⚠️ Not enough money!")

func on_repair_rod() -> void:
	var repair_cost = 50
	if GlobalData.player_money >= repair_cost:
		GlobalData.player_money -= repair_cost
		GlobalData.current_rod["current_durability"] = GlobalData.current_rod["max_durability"]
		GlobalData.rod_durability = GlobalData.current_rod["max_durability"]
		print("✅ Rod repaired to full durability")
		update_money_display()
	else:
		print("⚠️ Not enough money!")

func on_buy_bait() -> void:
	var selected = bait_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var bait_index = selected[0]
	var bait = GlobalData.bait_shop_inventory[bait_index]
	
	if GlobalData.player_money >= bait["price"]:
		GlobalData.player_money -= bait["price"]
		GlobalData.current_bait = bait.duplicate()
		GlobalData.current_bait["uses_remaining"] = bait["max_uses"]
		print("✅ Purchased %s" % bait["name"])
		update_money_display()
	else:
		print("⚠️ Not enough money!")

func on_sell_fish() -> void:
	var selected = fish_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var list_index = selected[0]
	var inventory_index = fish_list.get_item_metadata(list_index)
	var fish = GlobalData.saved_inventory_items[inventory_index]
	
	if fish != null:
		var value = GlobalData.calculate_fish_value(fish)
		GlobalData.player_money += value
		GlobalData.saved_inventory_items[inventory_index] = null
		print("✅ Sold %s for %d coins" % [fish["name"], value])
		populate_shop()
		update_money_display()

func on_close_shop() -> void:
	SceneTransition.fade_to_scene("res://scenes/game.tscn")
