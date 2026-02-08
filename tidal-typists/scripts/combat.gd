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
@onready var result_textbox = $ResultUI/TextBox/Label
@onready var result_textbox_sprite = $ResultUI/TextBox
@onready var continue_button = $ContinueButton
@onready var fish_sprite = $HBoxContainer/Background/FishSprite
@onready var player_sprite = $HBoxContainer/Background/PlayerSprite
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
var player_damage = 0
var fish_damage_taken = 0
var last_wpm = 0
var last_accuracy = 0.0

func _ready() -> void:
	# Set cursor to visible for combat UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Don't modify the label - it already has autowrap_mode=3 in the scene
	# The issue is that the text is already wrapped, it just needs proper room
	
	update_ui()
	load_fish_sprite()
	load_player_sprite()
	
	prep_timer_ui.visible = false
	combat_ui.visible = false
	result_ui.visible = false
	
	fight_button.pressed.connect(on_fight_pressed)
	flee_button.pressed.connect(on_flee_pressed)
	continue_button.pressed.connect(on_continue_pressed)
	
	fight_button.focus_mode = Control.FOCUS_NONE
	flee_button.focus_mode = Control.FOCUS_NONE
	continue_button.focus_mode = Control.FOCUS_NONE
	
	input_box.focus_mode = Control.FOCUS_ALL
	input_box.editable = true
	
	show_intro_message()

func show_intro_message() -> void:
	if _gd == null:
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	var fish_name = str(fish.get("name", "Unknown Fish"))
	var fish_level = int(fish.get("level", 1))
	
	var intro_messages = [
		"The Lv. %d %s tugs at your rod.",
		"You caught a Lv. %d %s! Fight or flee?",
		"A wild Lv. %d %s appears!",
		"The Lv. %d %s struggles on the line!",
		"You've hooked a Lv. %d %s!"
	]
	
	var message = intro_messages[randi() % intro_messages.size()]
	result_textbox.text = message % [fish_level, fish_name]
	result_textbox_sprite.visible = true
	result_ui.visible = true
	choice_buttons.visible = true
	continue_button.visible = false

func load_fish_sprite() -> void:
	if _gd == null:
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	if fish.has("sprite_path"):
		var sprite_path = fish.get("sprite_path", "")
		var texture = load(sprite_path)
		if texture:
			fish_sprite.texture = texture

func load_player_sprite() -> void:
	if _gd == null:
		return
	
	var gender = _gd.get("player_gender")
	var sprite_path = ""
	
	if gender == "Male" or gender == "Male (placeholder)":
		sprite_path = "res://assets/characters/male_sprite.png"
	elif gender == "Female" or gender == "Female (placeholder)":
		sprite_path = "res://assets/characters/female_sprite.png"
	else:
		sprite_path = "res://assets/characters/male_sprite.png"
	
	var full_texture = load(sprite_path)
	if full_texture:
		var atlas = AtlasTexture.new()
		atlas.atlas = full_texture
		atlas.region = Rect2(0, 0, 64, 64)
		
		player_sprite.texture = atlas
		print("✅ Player sprite loaded: ", sprite_path)
	else:
		print("⚠️ Failed to load player sprite: ", sprite_path)
			
func update_ui() -> void:
	if _gd == null:
		return
	
	rod_durability_label.text = "Rod: " + str(_gd.get("rod_durability")) + "%"
	var fish := _gd.get("current_fish") as Dictionary
	
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
	result_ui.visible = false
	prep_timer_ui.visible = true
	is_prep_phase = true
	prep_timer = 0.0

func on_flee_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	SceneTransition.fade_to_scene("res://scenes/game.tscn")

func _input(event: InputEvent) -> void:
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
	
	# Hide continue button when typing challenge starts
	continue_button.visible = false
	result_ui.visible = false
	
	if _gd == null:
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
		input_box.text = ""
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

var is_showing_player_result = false

func end_turn() -> void:
	combat_ui.visible = false
	
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	last_wpm = int((typed_words.size() / time_taken) * 60.0)
	last_accuracy = (float(correct_characters) / float(total_characters_typed)) * 100.0 if total_characters_typed > 0 else 0.0
	
	player_damage = 0
	if last_accuracy >= 70:
		player_damage = int(last_wpm * (last_accuracy / 100.0))
		if _gd != null:
			var fish := _gd.get("current_fish") as Dictionary
			var new_health = int(fish.get("health", 0)) - player_damage
			fish["health"] = max(0, new_health)
			_gd.set("current_fish", fish)
	
	update_ui()
	show_player_result()

func show_player_result() -> void:
	if _gd == null:
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	var fish_name = str(fish.get("name", "Unknown Fish"))
	
	var message = ""
	if last_accuracy >= 70:
		var hit_messages = [
			"You hit %s for %d damage! (%d WPM, %d%% Acc)",
			"Fish takes %d damage! (%d WPM, %d%%)",
			"%d damage to %s! (%d WPM, %d%%)",
			"%s takes %d damage! (%d WPM, %d%%)"
		]
		var selected = hit_messages[randi() % hit_messages.size()]
		
		# Simplified formatting - less text means less overflow
		if selected.begins_with("You") or selected.begins_with("%d damage to"):
			message = selected % [fish_name, player_damage, last_wpm, int(last_accuracy)]
		elif selected.begins_with("Fish"):
			message = selected % [player_damage, last_wpm, int(last_accuracy)]
		else:
			message = selected % [fish_name, player_damage, last_wpm, int(last_accuracy)]
	else:
		var miss_messages = [
			"Miss! (%d WPM, %d%% Acc)",
			"Fish dodges! (%d WPM, %d%%)",
			"Too slow! (%d WPM, %d%%)"
		]
		var selected = miss_messages[randi() % miss_messages.size()]
		message = selected % [last_wpm, int(last_accuracy)]
	
	result_textbox.text = message
	result_textbox_sprite.visible = true
	result_ui.visible = true
	continue_button.visible = true
	is_showing_player_result = true

func on_continue_pressed() -> void:
	if is_showing_player_result:
		is_showing_player_result = false
		result_ui.visible = false
		continue_button.visible = false
		fish_turn()
		return
	
	result_ui.visible = false
	continue_button.visible = false
	
	if _gd == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		SceneTransition.fade_to_scene("res://scenes/game.tscn")
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	if int(fish.get("health", 0)) <= 0:
		add_fish_to_inventory(fish)
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		SceneTransition.fade_to_scene("res://scenes/game.tscn")
		return
	
	if int(_gd.get("rod_durability")) <= 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		SceneTransition.fade_to_scene("res://scenes/game.tscn")
		return
	
	start_combat()

func add_fish_to_inventory(fish: Dictionary) -> void:
	if _gd == null:
		return
	
	print("\n🐟 === ADDING FISH TO INVENTORY ===")
	
	var fish_item = {
		"name": fish.get("name", "Unknown Fish"),
		"type": "fish",
		"rarity": fish.get("rarity", "common"),
		"level": fish.get("level", 1),
		"icon": load(fish.get("sprite_path", "")),
		"sprite_path": fish.get("sprite_path", ""),
		"description": "A %s fish caught at level %d." % [fish.get("rarity", "common"), fish.get("level", 1)]
	}
	
	print("📦 Current inventory size: ", _gd.saved_inventory_items.size())
	print("📊 Has initialized: ", _gd.has_initialized_inventory)
	
	# Safety: Ensure array exists
	if _gd.saved_inventory_items.size() == 0:
		print("⚠️ Creating emergency inventory - this means inventory wasn't saved!")
		_gd.saved_inventory_items.resize(9)
		for i in range(9):
			_gd.saved_inventory_items[i] = null
	
	# Find empty slot
	var added = false
	for i in range(_gd.saved_inventory_items.size()):
		if _gd.saved_inventory_items[i] == null:
			_gd.saved_inventory_items[i] = fish_item
			added = true
			print("✅ Added fish to slot %d" % i)
			break
	
	if not added:
		print("⚠️ Inventory full!")
	
	print("=== FISH ADDITION COMPLETE ===\n")

func fish_turn() -> void:
	if _gd == null:
		return
	
	var fish := _gd.get("current_fish") as Dictionary
	var fish_name = str(fish.get("name", "Unknown Fish"))
	fish_damage_taken = randi_range(1, int(fish.get("max_damage", 1)))
	var wpm_reduction = int(last_wpm * 0.1)
	fish_damage_taken = max(1, fish_damage_taken - wpm_reduction)
	
	var new_rod_durability = int(_gd.get("rod_durability")) - fish_damage_taken
	_gd.set("rod_durability", max(0, new_rod_durability))
	update_ui()
	
	# Shorter fish messages
	var fish_messages = [
		"Fish strikes! Rod -%d",
		"%s attacks! -%d durability",
		"Rod takes %d damage!"
	]
	
	var selected = fish_messages[randi() % fish_messages.size()]
	var message = ""
	
	if selected.count("%s") == 1:
		message = selected % [fish_name, fish_damage_taken]
	else:
		message = selected % [fish_damage_taken]
	
	result_textbox.text = message
	result_textbox_sprite.visible = true
	result_ui.visible = true
	continue_button.visible = true
