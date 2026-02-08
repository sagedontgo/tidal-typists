extends Control

# ---- CONFIGURATION ----
@export var world_size: Vector2 # Size of your game world in pixels
@export var world_origin: Vector2 = Vector2.ZERO # World-space origin that maps to the minimap's top-left
@export var auto_world_bounds: bool = true # If world_size isn't set, try to derive it from a TileMapLayer
@export var tilemap_path: NodePath # Optional: explicitly point to your TileMapLayer (e.g. ../Layer1)
@export var player_path: NodePath # Optional: explicitly point to the Player node
@export var player_node_name: StringName = &"Player" # Fallback name lookup when player_path isn't set
# ------------------------

var _player: Node2D
var _tilemap: Node

func _ready() -> void:
	_resolve_player()
	_resolve_tilemap()
	_try_update_world_bounds()

func _process(_delta: float) -> void:
	# Update player marker every frame (real-time).
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	if auto_world_bounds and (world_size.x <= 0.0 or world_size.y <= 0.0):
		_try_update_world_bounds()
	if _player != null:
		set_player_world_position(_player.global_position) # Use global_position for world coords

func _resolve_player() -> void:
	_player = null

	
	if player_path != NodePath():
		var p := get_node_or_null(player_path)
		if p is Node2D:
			_player = p
			return

	
	var g := get_tree().get_first_node_in_group("player")
	if g is Node2D:
		_player = g
		return

	
	var cs := get_tree().current_scene
	if cs == null:
		return
	var by_name := cs.find_child(String(player_node_name), true, false)
	if by_name is Node2D:
		_player = by_name

func _resolve_tilemap() -> void:
	_tilemap = null

	var cs := get_tree().current_scene
	if cs == null:
		return

	
	if tilemap_path != NodePath():
		var t := get_node_or_null(tilemap_path)
		if t != null:
			_tilemap = t
			return

	
	var layer1 := cs.find_child("Layer1", true, false)
	if layer1 != null:
		_tilemap = layer1
		return
	var layer2 := cs.find_child("Layer2", true, false)
	if layer2 != null:
		_tilemap = layer2
		return

func _try_update_world_bounds() -> void:
	if not auto_world_bounds:
		return
	if _tilemap == null or not is_instance_valid(_tilemap):
		_resolve_tilemap()
	if _tilemap == null:
		return

	
	if not _tilemap.has_method("get_used_rect"):
		return

	var used: Rect2i = _tilemap.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return

	
	var cell_min: Vector2i = used.position
	var cell_max: Vector2i = used.position + used.size

	var local_min := Vector2(cell_min)
	var local_max := Vector2(cell_max)

	if _tilemap.has_method("map_to_local"):
		local_min = _tilemap.map_to_local(cell_min)
		local_max = _tilemap.map_to_local(cell_max)

	
	var tile_size := Vector2(16, 16)
	var tile_set: TileSet = null
	if _tilemap is TileMapLayer:
		tile_set = (_tilemap as TileMapLayer).tile_set
	elif _tilemap is TileMap:
		tile_set = (_tilemap as TileMap).tile_set
	if tile_set != null:
		var ts: Vector2i = tile_set.tile_size
		if ts.x > 0 and ts.y > 0:
			tile_size = Vector2(ts)

	local_min -= tile_size * 0.5
	local_max += tile_size * 0.5

	var global_min := local_min
	var global_max := local_max
	if _tilemap.has_method("to_global"):
		global_min = _tilemap.to_global(local_min)
		global_max = _tilemap.to_global(local_max)

	var o := Vector2(min(global_min.x, global_max.x), min(global_min.y, global_max.y))
	var s := Vector2(abs(global_max.x - global_min.x), abs(global_max.y - global_min.y))

	# Only apply if it gives us a usable size.
	if s.x > 0.0 and s.y > 0.0:
		world_origin = o
		world_size = s

func _get_player_marker() -> Node:
	# Your `hud.tscn` currently nests it under `Background`.
	var marker := get_node_or_null("Background/PlayerMarker")
	if marker != null:
		return marker
	marker = get_node_or_null("PlayerMarker")
	if marker != null:
		return marker
	return find_child("PlayerMarker", true, false)

func set_player_world_position(world_pos: Vector2) -> void:
	var player_marker := _get_player_marker()
	if player_marker == null:
		return

	# Avoid division by zero if world size isn't configured.
	if world_size.x <= 0.0 or world_size.y <= 0.0:
		return

	# Place marker in its PARENT's local coordinate space.
	var container: Control = self
	if player_marker.get_parent() is Control:
		container = player_marker.get_parent() as Control

	var map_size := container.size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return

	# Convert world position into 0..1 normalized space, then scale to local map coords.
	var normalized := (world_pos - world_origin) / world_size
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)

	var map_pos := normalized * map_size

	# Keep the marker fully inside the minimap rect when possible.
	if player_marker is Control:
		var marker_size := (player_marker as Control).size
		if marker_size.x > 0.0 and marker_size.y > 0.0:
			map_pos -= marker_size * 0.5
			map_pos.x = clampf(map_pos.x, 0.0, map_size.x - marker_size.x)
			map_pos.y = clampf(map_pos.y, 0.0, map_size.y - marker_size.y)

	if player_marker.has_method("set_map_position"):
		player_marker.set_map_position(map_pos)
