extends Node

# Fishing System - Handles fishing rod usage, waiting for fish, and combat transition

signal fishing_started
signal fish_hooked(fish_data: Dictionary)

@onready var player = get_parent()  # Should be attached to Player node
@onready var fishing_ui: CanvasLayer = null

var is_fishing := false
var fishing_timer := 0.0
var time_until_bite := 0.0

# Fishing settings
const MIN_WAIT_TIME = 3.0  # Minimum seconds before fish bites
const MAX_WAIT_TIME = 8.0  # Maximum seconds before fish bites

func _ready():
	# Create fishing UI
	create_fishing_ui()
	print("🎣 Fishing System ready")

func create_fishing_ui():
	"""Create a simple UI to show fishing status"""
	fishing_ui = CanvasLayer.new()
	fishing_ui.name = "FishingUI"
	add_child(fishing_ui)
	
	# Create label
	var label = Label.new()
	label.name = "FishingLabel"
	label.text = "Waiting for fish..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position at top center
	label.anchor_left = 0.5
	label.anchor_top = 0.1
	label.anchor_right = 0.5
	label.anchor_bottom = 0.1
	label.offset_left = -150
	label.offset_right = 150
	label.offset_top = -20
	label.offset_bottom = 20
	
	# Style
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	
	fishing_ui.add_child(label)
	fishing_ui.visible = false

func start_fishing():
	"""Called when player uses fishing rod"""
	if is_fishing:
		print("⚠️ Already fishing!")
		return
	
	# Start fishing animation
	if player.has_method("start_fishing"):
		player.start_fishing()
	
	is_fishing = true
	fishing_timer = 0.0
	
	# Random wait time before fish bites
	time_until_bite = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
	
	# Show UI
	fishing_ui.visible = true
	update_fishing_label("Waiting for fish...")
	
	fishing_started.emit()
	print("🎣 Started fishing! Fish will bite in ", "%.1f" % time_until_bite, " seconds")

func stop_fishing():
	"""Cancel fishing"""
	if not is_fishing:
		return
	
	is_fishing = false
	fishing_timer = 0.0
	fishing_ui.visible = false
	
	# Stop fishing animation
	if player.has_method("stop_fishing"):
		player.stop_fishing()
	
	print("✅ Stopped fishing")

func _process(delta: float):
	if not is_fishing:
		return
	
	fishing_timer += delta
	
	# Update dots animation
	var dots = int(fishing_timer * 2) % 4
	var dot_string = ".".repeat(dots)
	update_fishing_label("Waiting for fish" + dot_string)
	
	# Check if fish bites
	if fishing_timer >= time_until_bite:
		fish_bites()

func fish_bites():
	"""Fish bites! Generate fish and go to combat"""
	is_fishing = false
	
	update_fishing_label("Fish hooked! 🎣")
	
	# Generate random fish
	var gd = get_node_or_null("/root/GlobalData")
	if gd != null:
		var fish = gd.roll_random_fish()
		gd.current_fish = fish
		gd.rod_durability = 100  # Reset rod durability
		
		# Save player position
		gd.has_saved_player_position = true
		gd.saved_player_position = player.global_position
		
		print("🐟 Fish hooked: ", fish.get("name"), " Lv.", fish.get("level"))
		
		fish_hooked.emit(fish)
	
	# Wait a moment to show "Fish hooked!" message
	await get_tree().create_timer(1.0).timeout
	
	fishing_ui.visible = false
	
	# Stop fishing animation
	if player.has_method("stop_fishing"):
		player.stop_fishing()
	
	# Transition to combat
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/combat.tscn")

func update_fishing_label(new_text: String):
	"""Update the fishing status label"""
	if fishing_ui == null:
		return
	
	var label = fishing_ui.get_node_or_null("FishingLabel")
	if label:
		label.text = new_text

func _input(event: InputEvent):
	# Allow player to cancel fishing with Escape
	if is_fishing and event.is_action_pressed("ui_cancel"):
		stop_fishing()
		get_viewport().set_input_as_handled()
