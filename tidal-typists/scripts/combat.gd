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
@onready var fish_sprite = $HBoxContainer/Right/FishSprite

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
	input_box.text_submitted.connect(on_text_submitted)

func load_fish_sprite() -> void:
	if GlobalData.current_fish.has("sprite_path"):
		print("Loading sprite from: ", GlobalData.current_fish["sprite_path"])
		var texture = load(GlobalData.current_fish["sprite_path"])
		if texture:
			print("Texture loaded successfully")
			fish_sprite.texture = texture
		else:
			print("Failed to load texture")
	else:
		print("No sprite_path in current_fish")

func update_ui() -> void:
	if GlobalData.current_fish.is_empty():
		GlobalData.current_fish = GlobalData.roll_random_fish()
		GlobalData.rod_durability = 100
	
	rod_durability_label.text = "Rod: " + str(GlobalData.rod_durability) + "%"
	var rarity_color = ""
	if GlobalData.current_fish.has("rarity"):
		match GlobalData.current_fish["rarity"]:
			"common":
				rarity_color = "[color=gray]"
			"uncommon":
				rarity_color = "[color=green]"
			"rare":
				rarity_color = "[color=blue]"
			"legendary":
				rarity_color = "[color=gold]"
	
	fish_name_label.text = rarity_color + GlobalData.current_fish["name"] + "[/color]"
	fish_name_label.bbcode_enabled = true
	fish_level_label.text = "Lv: " + str(GlobalData.current_fish["level"])
	fish_health_label.text = "HP: " + str(GlobalData.current_fish["health"]) + "/" + str(GlobalData.current_fish["max_health"])

func on_fight_pressed() -> void:
	choice_buttons.visible = false
	prep_timer_ui.visible = true
	is_prep_phase = true
	prep_timer = 0.0	

func on_flee_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

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
	input_box.grab_focus()
	
	var fish_level = GlobalData.current_fish["level"]
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

func on_text_submitted(text: String) -> void:
	if current_word_index >= words_to_type.size():
		return
	
	typed_words.append(text)
	calculate_accuracy(text, words_to_type[current_word_index])
	
	current_word_index += 1
	input_box.clear()
	input_box.grab_focus()
	
	if current_word_index < words_to_type.size():
		word_label.text = words_to_type[current_word_index]
	else:
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
	
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	var wpm = (typed_words.size() / time_taken) * 60.0
	var accuracy = (float(correct_characters) / float(total_characters_typed)) * 100.0 if total_characters_typed > 0 else 0.0
	
	var damage = 0
	if accuracy >= 70:
		damage = int(wpm * (accuracy / 100.0))
		GlobalData.current_fish["health"] -= damage
		result_label.text = "Hit!"
		damage_label.text = "Damage: " + str(damage) + "\nWPM: " + str(int(wpm)) + " | Accuracy: " + str(int(accuracy)) + "%"
	else:
		result_label.text = "Miss!"
		damage_label.text = "Accuracy too low!\nWPM: " + str(int(wpm)) + " | Accuracy: " + str(int(accuracy)) + "%"
	
	update_ui()

func on_continue_pressed() -> void:
	result_ui.visible = false
	
	if GlobalData.current_fish["health"] <= 0:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	
	fish_turn()

func fish_turn() -> void:
	var fish_damage = randi_range(1, GlobalData.current_fish["max_damage"])
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	var wpm = (typed_words.size() / time_taken) * 60.0
	var wpm_reduction = int(wpm * 0.1)
	fish_damage = max(1, fish_damage - wpm_reduction)
	
	GlobalData.rod_durability -= fish_damage
	update_ui()
	
	result_ui.visible = true
	result_label.text = "Fish attacks!"
	damage_label.text = "Rod damage: " + str(fish_damage)
	
	await get_tree().create_timer(1.5).timeout
	result_ui.visible = false
	
	if GlobalData.rod_durability <= 0:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		start_combat()
