extends Control

@onready var player_label = $PlayerInfo/PlayerLabel
@onready var rod_durability_label = $PlayerInfo/RodDurabilityLabel
@onready var fish_name_label = $FishInfo/FishNameLabel
@onready var fish_level_label = $FishInfo/FishLevelLabel
@onready var fish_health_label = $FishInfo/FishHealthLabel
@onready var choice_buttons = $ChoiceButtons
@onready var fight_button = $ChoiceButtons/FightButton
@onready var flee_button = $ChoiceButtons/FleeButton
@onready var prep_timer_ui = $PrepTimer
@onready var prep_label = $PrepTimer/PrepLabel
@onready var prep_timer_label = $PrepTimer/PrepTimerLabel
@onready var combat_ui = $CombatUI
@onready var word_label = $CombatUI/WordLabel
@onready var input_box = $CombatUI/InputBox
@onready var timer_label = $CombatUI/TimerLabel
@onready var result_ui = $ResultUI
@onready var result_label = $ResultUI/ResultLabel
@onready var damage_label = $ResultUI/DamageLabel
@onready var continue_button = $ResultUI/ContinueButton
@onready var fish_sprite = $HBoxContainer/Background/FishSprite
@onready var _gd: Node = get_node_or_null("/root/GlobalData")

@export var easy_words: Array[String] = [
	"the", "and", "cat", "dog", "sun", "boy", "run", "sit", "big", "hot"
]
@export var medium_words: Array[String] = [
	"bright", "garden", "window", "planet", "forest", "silver", "simple"
]
@export var hard_words: Array[String] = [
	"atmosphere", "background", "celebration", "dictionary", "everything"
]

var word_dict = {
	"easy": easy_words,
	"medium": medium_words,
	"hard": hard_words
}

var current_word_index = 0
var words_to_type: Array[String] = []
var typed_words: Array[String] = []
var total_characters_typed = 0
var correct_characters = 0
var start_time = 0.0
var time_limit = 0.0
var prep_time = 3.0
var prep_timer = 0.0
var is_prep_phase = false
var _in_fish_attack := false

func _ready() -> void:
	update_ui()
	load_fish_sprite()
	choice_buttons.visible = true
	prep_timer_ui.visible = false
	combat_ui.visible = false
	result_ui.visible = false
	
	fight_button.pressed.connect(on_fight_pressed)
	flee_button.pressed.connect(on_flee_pressed)
	continue_button.pressed.connect(on_continue_pressed)
	
	fight_button.focus_mode = Control.FOCUS_NONE
	flee_button.focus_mode = Control.FOCUS_NONE
	continue_button.focus_mode = Control.FOCUS_NONE
	
	# Ensure input box can receive focus
	input_box.focus_mode = Control.FOCUS_ALL
	input_box.editable = true

func load_fish_sprite() -> void:
	if _gd == null:
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	if fish.has("sprite_path"):
		var sprite_path = fish.get("sprite_path", "")
		print("Loading fish sprite from: ", sprite_path)
		var texture = load(sprite_path)
		if texture:
			fish_sprite.texture = texture
			print("✅ Fish sprite loaded successfully")
		else:
			print("⚠️ Failed to load fish texture from: ", sprite_path)
	else:
		print("⚠️ No sprite_path found in current_fish")

func update_ui() -> void:
	if _gd == null:
		push_error("GlobalData autoload missing. Check Project Settings > Autoload.")
		return
	
	rod_durability_label.text = "Rod: " + str(_gd.get("rod_durability")) + "%"
	var fish := _gd.get("current_fish") as Dictionary
	
	# Color-code fish name by rarity
	var rarity_color = ""
	if fish.has("rarity"):
		match fish.get("rarity"):
			"common":
				rarity_color = "[color=gray]"
			"uncommon":
				rarity_color = "[color=green]"
			"rare":
				rarity_color = "[color=blue]"
			"legendary":
				rarity_color = "[color=gold]"
	
	fish_name_label.text = rarity_color + str(fish.get("name", "Unknown Fish")) + "[/color]"
	fish_name_label.bbcode_enabled = true
	fish_level_label.text = "Lv: " + str(fish.get("level", 1))
	fish_health_label.text = "HP: %s/%s" % [str(fish.get("health", 0)), str(fish.get("max_health", 0))]

func on_fight_pressed() -> void:
	choice_buttons.visible = false
	prep_timer_ui.visible = true
	is_prep_phase = true
	prep_timer = 0.0

func on_flee_pressed() -> void:
	# Restore custom cursor when returning to game
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _input(event: InputEvent) -> void:
	# Handle Enter key manually during combat
	if combat_ui.visible and event.is_action_pressed("ui_accept"):
		if input_box and input_box.has_focus():
			var text = input_box.text.strip_edges()
			if text.length() > 0:
				on_text_submitted(text)
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_prep_phase:
		prep_timer += delta
		prep_timer_label.text = str(int(prep_time - prep_timer + 1))
		if prep_timer >= prep_time:
			is_prep_phase = false
			prep_timer_ui.visible = false
			start_combat()
	
	if combat_ui.visible and time_limit > 0:
		var time_remaining = time_limit - (Time.get_ticks_msec() / 1000.0 - start_time)
		if time_remaining > 0:
			timer_label.text = "Time: " + str(int(time_remaining)) + "s"
		else:
			timer_label.text = "Time: 0s"
			end_turn()

func start_combat() -> void:
	combat_ui.visible = true
	
	if _gd == null:
		push_error("GlobalData autoload missing. Check Project Settings > Autoload.")
		return
	var fish := _gd.get("current_fish") as Dictionary
	var fish_level: int = int(fish.get("level", 1))
	var difficulty = "easy"
	var word_count = 3
	
	if fish_level >= 7:
		difficulty = "hard"
		word_count = 5
		time_limit = 25.0
	elif fish_level >= 4:
		difficulty = "medium"
		word_count = 4
		time_limit = 16.0
	else:
		difficulty = "easy"
		word_count = 3
		time_limit = 9.0
	
	words_to_type.clear()
	typed_words.clear()
	current_word_index = 0
	total_characters_typed = 0
	correct_characters = 0
	start_time = Time.get_ticks_msec() / 1000.0
	
	for i in word_count:
		words_to_type.append(word_dict[difficulty].pick_random())
	
	word_label.text = words_to_type[current_word_index]
	input_box.text = ""
	input_box.grab_focus()

func on_text_submitted(text: String) -> void:
	if current_word_index >= words_to_type.size():
		return
	
	typed_words.append(text)
	calculate_accuracy(text, words_to_type[current_word_index])
	
	current_word_index += 1
	
	if current_word_index < words_to_type.size():
		word_label.text = words_to_type[current_word_index]
		input_box.text = ""  # Clear text directly instead of using clear()
		# Focus stays on input_box automatically since we handled the Enter key
	else:
		input_box.clear()
		end_turn()

func calculate_accuracy(typed: String, correct: String) -> void:
	var min_length = min(typed.length(), correct.length())
	
	for i in min_length:
		total_characters_typed += 1
		if typed[i] == correct[i]:
			correct_characters += 1
	
	if typed.length() > correct.length():
		total_characters_typed += typed.length() - correct.length()
	elif correct.length() > typed.length():
		total_characters_typed += correct.length() - typed.length()

func end_turn() -> void:
	combat_ui.visible = false
	result_ui.visible = true
	_in_fish_attack = false
	# Player-result screen: Continue should be usable here.
	continue_button.disabled = false
	continue_button.visible = true
	
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	var wpm = (typed_words.size() / time_taken) * 60.0
	var accuracy = (float(correct_characters) / float(total_characters_typed)) * 100.0 if total_characters_typed > 0 else 0.0
	
	var damage = 0
	if accuracy >= 70:
		damage = int(wpm * (accuracy / 100.0))
		if _gd != null:
			var fish := _gd.get("current_fish") as Dictionary
			var new_health = int(fish.get("health", 0)) - damage
			fish["health"] = max(0, new_health)  # Clamp health to minimum of 0
			_gd.set("current_fish", fish)
		result_label.text = "Hit!"
		damage_label.text = "Damage: " + str(damage) + "\nWPM: " + str(int(wpm)) + " | Accuracy: " + str(int(accuracy)) + "%"
	else:
		result_label.text = "Miss!"
		damage_label.text = "Accuracy too low!\nWPM: " + str(int(wpm)) + " | Accuracy: " + str(int(accuracy)) + "%"
	
	update_ui()

func on_continue_pressed() -> void:
	# During fish attack phase, Continue must do nothing to prevent multi-hit bugs.
	if _in_fish_attack:
		return

	result_ui.visible = false
	
	if _gd == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	var fish := _gd.get("current_fish") as Dictionary
	if int(fish.get("health", 0)) <= 0:
		# Fish defeated! Add to inventory
		add_fish_to_inventory(fish)
		
		# Restore custom cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	
	fish_turn()

func add_fish_to_inventory(fish: Dictionary) -> void:
	"""Add the caught fish to the player's inventory"""
	if _gd == null:
		return
	
	print("🐟 Fish defeated! Adding to inventory...")
	
	# Create fish item for inventory
	var fish_item = {
		"name": fish.get("name", "Unknown Fish"),
		"type": "fish",
		"rarity": fish.get("rarity", "common"),
		"level": fish.get("level", 1),
		"icon": load(fish.get("sprite_path", "")),  # Load the fish sprite as icon
		"sprite_path": fish.get("sprite_path", ""),
		"description": "A %s fish caught at level %d." % [fish.get("rarity", "common"), fish.get("level", 1)]
	}
	
	# Add to saved inventory (GlobalData will persist it)
	if _gd.saved_inventory_items.size() > 0:
		# Find first empty slot
		var added = false
		for i in range(_gd.saved_inventory_items.size()):
			if _gd.saved_inventory_items[i] == null:
				_gd.saved_inventory_items[i] = fish_item
				added = true
				print("✅ Added %s to inventory slot %d" % [fish_item["name"], i])
				break
		
		if not added:
			print("⚠️ Inventory full! Fish not added.")
	else:
		print("⚠️ Inventory not initialized, fish not added.")

func fish_turn() -> void:
	_in_fish_attack = true
	# Fish-attack screen: hide/disable Continue to prevent multiple damage ticks.
	continue_button.disabled = true
	continue_button.visible = false

	if _gd == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	var fish := _gd.get("current_fish") as Dictionary
	var fish_damage = randi_range(1, int(fish.get("max_damage", 1)))
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	var wpm = (typed_words.size() / time_taken) * 60.0
	var wpm_reduction = int(wpm * 0.1)
	fish_damage = max(1, fish_damage - wpm_reduction)
	
	var new_rod_durability = int(_gd.get("rod_durability")) - fish_damage
	_gd.set("rod_durability", max(0, new_rod_durability))  # Clamp rod durability to minimum of 0
	update_ui()
	
	result_ui.visible = true
	result_label.text = "Fish attacks!"
	damage_label.text = "Rod damage: " + str(fish_damage)
	
	await get_tree().create_timer(1.5).timeout
	result_ui.visible = false
	
	if int(_gd.get("rod_durability")) <= 0:
		# Rod broke! Restore custom cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		start_combat()
