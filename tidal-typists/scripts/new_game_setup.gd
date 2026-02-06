extends Control

signal submitted(nickname: String, gender: String)
signal cancelled

@onready var _nickname_input: LineEdit = get_node_or_null("CenterContainer/Panel/Margin/InnerCenter/VBox/NicknameInput")
@onready var _gender_select: OptionButton = get_node_or_null("CenterContainer/Panel/Margin/InnerCenter/VBox/GenderSelect")
@onready var _back_button: Button = get_node_or_null("CenterContainer/Panel/Margin/InnerCenter/VBox/ButtonsRow/BackButton")
@onready var _continue_button: Button = get_node_or_null("CenterContainer/Panel/Margin/InnerCenter/VBox/ButtonsRow/ContinueButton")

func _enter_tree() -> void:
	# This UI is usually shown while the game is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if _gender_select != null and _gender_select.item_count == 0:
		_gender_select.add_item("Male (placeholder)")
		_gender_select.add_item("Female (placeholder)")

	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)
	if _continue_button != null and not _continue_button.pressed.is_connected(_on_continue_pressed):
		_continue_button.pressed.connect(_on_continue_pressed)

	if _nickname_input != null:
		_nickname_input.grab_focus()

func _on_back_pressed() -> void:
	cancelled.emit()

func _on_continue_pressed() -> void:
	var nickname := ""
	if _nickname_input != null:
		nickname = _nickname_input.text.strip_edges()
	if nickname.is_empty():
		push_warning("Nickname is empty.")
		return

	var gender := "unspecified"
	if _gender_select != null and _gender_select.selected >= 0:
		gender = _gender_select.get_item_text(_gender_select.selected)

	submitted.emit(nickname, gender)

