extends Sprite2D

const GRID_SIZE = 16

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	position.x = floor(mouse_pos.x / GRID_SIZE) * GRID_SIZE
	position.y = floor(mouse_pos.y / GRID_SIZE) * GRID_SIZE
