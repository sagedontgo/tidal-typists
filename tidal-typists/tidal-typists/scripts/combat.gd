extends Control
@onready var choice_buttons = $ChoiceButtons
@onready var combat_ui = $CombatUI
@onready var combat_ui_label = $CombatUI/Label
@onready var combat_ui_timer = $CombatUI/TimerLabel
@onready var combat_ui_lineEdit = $CombatUI/LineEdit
@onready var fight_button = $ChoiceButtons/FightButton
@onready var flee_button = $ChoiceButtons/FleeButton
@export var easy_words: Array[String] = [
	"the", "and", "cat", "dog", "sun", "boy", "run", "sit", "big", "hot", 
	"ice", "map", "ten", "fly", "box", "home", "play", "time", "blue", "kind", 
	"fast", "slow", "tree", "fire", "book", "good", "love", "gold", "ship", "milk", 
	"wind", "star", "duck", "lake", "road", "apple", "bread", "cloud", "dance", "green", 
	"light", "music", "paper", "plant", "smile", "space", "water", "world", "table", "house"
]
@export var medium_words: Array[String] = [
	"bright", "garden", "window", "planet", "forest", "silver", "simple", "winter", "market", "player",
	"orange", "island", "bridge", "button", "coffee", "dragon", "energy", "future", "guitar", "hammer",
	"journey", "knight", "lesson", "memory", "nature", "palace", "quartz", "rabbit", "school", "ticket",
	"valley", "wizard", "yellow", "action", "beauty", "camera", "danger", "enough", "flower", "ground",
	"happen", "inside", "jungle", "kitchen", "laptop", "moment", "number", "ocean", "pencil", "quiet"
]
@export var hard_words: Array[String] = [
	"atmosphere", "background", "celebration", "dictionary", "everything", "friendship", "generation", "hypothesis", "impossible", "journalism",
	"knowledge", "labyrinth", "management", "navigation", "occurrence", "philosophy", "questionable", "reflection", "strategies", "television",
	"university", "vocabulary", "wilderness", "xylophone", "yesterday", "zookeeper", "achievement", "bankruptcy", "collection", "definition",
	"experience", "frequently", "government", "horizontal", "individual", "judgmental", "leadership", "mysterious", "neighborhood", "opportunity",
	"particular", "qualitative", "reasonable", "successful", "technology", "understand", "vulnerable", "wavelength", "xenophobia", "youthfully"
]
var word_dict = {
	"easy": easy_words,
	"medium": medium_words,
	"hard": hard_words
}

var current_difficulty: int
var current_word_count: int
var current_word_index: int = 0
var words_to_type: Array[String] = []
var typed_words: Array[String] = []
var total_characters_typed: int = 0
var correct_characters: int = 0
var start_time: float = 0.0
var time_limit: float = 0.0

func _ready() -> void:
	current_word_count = randi_range(5,10)
	current_difficulty = randi_range(1,3)
	combat_ui.visible = false
	fight_button.pressed.connect(on_fight_pressed)
	flee_button.pressed.connect(on_flee_pressed)
	

func on_enter_pressed() -> void:
	if current_word_index >= words_to_type.size():
		return
	
	var text = combat_ui_lineEdit.text
	typed_words.append(text)
	calculate_accuracy(text, words_to_type[current_word_index])
	
	current_word_index += 1
	
	if current_word_index < words_to_type.size():
		combat_ui_label.text = words_to_type[current_word_index]
	else:
		end_combat()
		return
	
	combat_ui_lineEdit.text = ""
	combat_ui_lineEdit.grab_focus()

func _process(delta: float) -> void:
	if combat_ui.visible and time_limit > 0:
		var time_remaining = time_limit - (Time.get_ticks_msec() / 1000.0 - start_time)
		if time_remaining > 0:
			combat_ui_timer.text = "Time: " + str(int(time_remaining)) + "s"
		else:
			combat_ui_timer.text = "Time: 0s"
			end_combat()
			
func on_fight_pressed():
	choice_buttons.visible = false
	combat_ui.visible = true
	combat_init(current_difficulty, current_word_count)
	combat_ui_lineEdit.selecting_enabled = false
	combat_ui_lineEdit.caret_blink = true
	combat_ui_lineEdit.grab_focus()

func combat_init(difficulty: int, wordCount: int):
	var difficulty_string = ""
	if difficulty == 1:
		difficulty_string = "easy"
		time_limit = wordCount * 3.0
	elif difficulty == 2:
		difficulty_string = "medium"
		time_limit = wordCount * 4.0
	else:
		difficulty_string = "hard"
		time_limit = wordCount * 5.0
	
	words_to_type.clear()
	typed_words.clear()
	current_word_index = 0
	total_characters_typed = 0
	correct_characters = 0
	start_time = Time.get_ticks_msec() / 1000.0
	
	for i in wordCount:
		var word = get_random_word(difficulty_string)
		words_to_type.append(word)
	
	combat_ui_label.text = words_to_type[current_word_index]
	
func get_random_word(difficulty: String) -> String:
	return word_dict[difficulty].pick_random()



func refocus_input() -> void:
	combat_ui_lineEdit.grab_focus()

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

func end_combat() -> void:
	var time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	var wpm = (typed_words.size() / time_taken) * 60.0
	var accuracy = (float(correct_characters) / float(total_characters_typed)) * 100.0
	
	print("WPM: ", wpm)
	print("Accuracy: ", accuracy, "%")
	print("Words typed: ", typed_words.size())

func on_flee_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_flee_pressed()
		return
	
	if combat_ui.visible and event.is_action_pressed("ui_accept"):
		if combat_ui_lineEdit.has_focus():
			on_enter_pressed()
			get_viewport().set_input_as_handled()
