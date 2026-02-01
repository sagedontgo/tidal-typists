extends Button

var slot_index := -1
var _inventory: Node = null
var _item = null

func setup(inventory: Node, index: int) -> void:
	_inventory = inventory
	slot_index = index
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	_refresh()

func set_item(item) -> void:
	_item = item
	_refresh()

func get_item():
	return _item

func _on_pressed() -> void:
	if _inventory == null:
		return
	
	if _inventory.has_method("_on_slot_pressed"):
		_inventory._on_slot_pressed(slot_index)

func _refresh() -> void:
	if _item == null:
		text = ""
		return
	
	if _item is String:
		text = _item
		return
	
	if _item is Dictionary and _item.has("name"):
		text = str(_item["name"])
		return
	
	text = str(_item)
