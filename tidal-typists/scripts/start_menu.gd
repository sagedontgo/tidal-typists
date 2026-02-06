extends Control

@export var start_scene_path: String = "res://scenes/game.tscn"
@export var nickname_scene_path: String = "res://scenes/nickname.tscn"
@export var customize_scene_path: String = "res://scenes/customize.tscn"

var _paused_by_menu := false

func _enter_tree() -> void:
	# Just to make sure this menu keeps working while the game is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if get_parent() != null:
		get_parent().process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _ready() -> void:
	# Buttons in `startscreen.tscn` are not all wired via signals yet, 
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
	# START button
	var start_btn := get_node_or_null("../HBoxContainer/Sprite2D/Button")
	if start_btn is Button:
		var b := start_btn as Button
		if not b.pressed.is_connected(_on_start_pressed):
			b.pressed.connect(_on_start_pressed)

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

func _on_customize_pressed():
	_try_change_scene(customize_scene_path)

func _on_button_4_pressed() -> void:
	# NEW GAME (for now): start gameplay by closing the overlay.
	# swap this to `_try_change_scene(nickname_scene_path)` when ready.
	_close_menu_and_resume()

func _on_button_3_pressed() -> void:
	# CUSTOMIZE (placeholder until the scene exists).
	_try_change_scene(customize_scene_path)

func _on_start_pressed() -> void:
	_close_menu_and_resume()

func _on_settings_pressed() -> void:
	# Placeholder until settings menu is implemented.
	push_warning("Settings menu not implemented yet.")
