extends Node

# If true, we skip the start menu overlay when `game.tscn` is loaded again
# (e.g. returning from combat back into the game scene).
var has_started_game: bool = false

# Used to restore player position when coming back to `game.tscn`
# after a scene change into combat.
var has_saved_player_position: bool = false
var saved_player_position: Vector2 = Vector2.ZERO

var current_fish = {
	"name": "Test Fish",
	"level": 5,
	"health": 100,
	"max_health": 100,
	"max_damage": 25
}
var rod_durability = 100
