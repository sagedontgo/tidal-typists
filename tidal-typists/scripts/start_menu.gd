extends Control

@export var start_scene_path: String = "res://scenes/game.tscn"
@export var new_game_setup_scene_path: String = "res://scenes/new_game_setup.tscn"

var _paused_by_menu := false
var _new_game_setup: Node = null

func _enter_tree() -> void:
	# Just to make sure this menu keeps working while the game is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if get_parent() != null:
		get_parent().process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _ready() -> void:
	# If we're returning to `game.tscn` from another scene (combat),
	# we don't want the start menu to reopen and pause the game.
	var gd := get_node_or_null("/root/GlobalData")
	if gd != null and bool(gd.get("has_started_game")):
		# Ensure normal gameplay state, then remove the overlay.
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		var root := get_parent()
		if root != null:
			root.queue_free()
		else:
			queue_free()
		return

	_connect_optional_buttons()
	# Open/pause here (not _enter_tree) so it runs after other nodes' _ready().
	# To prevent the in-game Cursor script from immediately hiding the mouse.
	_open_menu()

func _open_menu() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_menu = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_menu_and_resume() -> void:
	# Mark that the game has started this session so the menu doesn't reopen
	# when we come back to `game.tscn` from other scenes (like combat).
	var gd := get_node_or_null("/root/GlobalData")
	if gd != null:
		gd.set("has_started_game", true)

	if _paused_by_menu:
		get_tree().paused = false
		_paused_by_menu = false

	# in-game cursor is hidden ; restores after leaving the menu.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Removes the whole start screen overlay once the player starts.
	var root := get_parent()
	if root != null:
		root.queue_free()
	else:
		queue_free()

func _connect_optional_buttons() -> void:
	# SETTING button
	var settings_btn := get_node_or_null("../HBoxContainer/Sprite2D/Button2")
	if settings_btn is Button:
		var sb := settings_btn as Button
		if not sb.pressed.is_connected(_on_settings_pressed):
			sb.pressed.connect(_on_settings_pressed)

func _try_change_scene(path: String) -> void:
	if path.is_empty():
		push_warning("Scene path is empty.")
		return
	if not ResourceLoader.exists(path):
		push_warning("Scene not found: %s" % path)
		return

	# Unpause before changing scenes to avoid arriving into a paused scene tree.
	get_tree().paused = false
	_paused_by_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(path)

func _open_new_game_setup() -> void:
	if _new_game_setup != null and is_instance_valid(_new_game_setup):
		return
	if new_game_setup_scene_path.is_empty() or not ResourceLoader.exists(new_game_setup_scene_path):
		push_warning("New game setup scene not found: %s" % new_game_setup_scene_path)
		return

	var packed := load(new_game_setup_scene_path)
	if not (packed is PackedScene):
		push_warning("Not a PackedScene: %s" % new_game_setup_scene_path)
		return

	var inst := (packed as PackedScene).instantiate()
	_new_game_setup = inst

	# Hide the main start screen visuals while the setup screen is active.
	var main_ui := get_node_or_null("../HBoxContainer")
	if main_ui is CanvasItem:
		(main_ui as CanvasItem).visible = false

	var root := get_parent()
	if root != null:
		root.add_child(inst)
	else:
		add_child(inst)

	# Optional signals from the setup screen.
	if inst.has_signal("submitted"):
		inst.connect("submitted", Callable(self, "_on_new_game_setup_submitted"))
	if inst.has_signal("cancelled"):
		inst.connect("cancelled", Callable(self, "_on_new_game_setup_cancelled"))

func _on_settings_pressed() -> void:
	# Placeholder until settings menu is implemented.
	push_warning("Settings menu not implemented yet.")

func _on_button_4_pressed() -> void:
	# NEW GAME: open the separate setup screen overlay.
	_open_new_game_setup()

func _on_new_game_setup_cancelled() -> void:
	if _new_game_setup != null and is_instance_valid(_new_game_setup):
		_new_game_setup.queue_free()
	_new_game_setup = null

	var main_ui := get_node_or_null("../HBoxContainer")
	if main_ui is CanvasItem:
		(main_ui as CanvasItem).visible = true

func _on_new_game_setup_submitted(nickname: String, gender: String) -> void:
	# For now: stash it on the running game scene so you can read it later.
	var cs := get_tree().current_scene
	if cs != null:
		cs.set_meta("player_nickname", nickname)
		cs.set_meta("player_gender", gender)

	_close_menu_and_resume()
