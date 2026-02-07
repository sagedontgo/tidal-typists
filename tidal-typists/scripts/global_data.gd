extends Node

# If true, we skip the start menu overlay when `game.tscn` is loaded again
# (e.g. returning from combat back into the game scene).
var has_started_game: bool = false

# Used to restore player position when coming back to `game.tscn`
# after a scene change into combat.
var has_saved_player_position: bool = false
var saved_player_position: Vector2 = Vector2.ZERO

# Player info
var player_nickname: String = ""
var player_gender: String = ""

var fish_database = {
	"common": [
		{
			"name": "Cod",
			"min_level": 1,
			"max_level": 3,
			"sprite_path": "res://assets/fish/common/cod.png"
		},
		{
			"name": "Sardine",
			"min_level": 2,
			"max_level": 5,
			"sprite_path": "res://assets/fish/common/sardine.png"
		}
	],
	"uncommon": [
		{
			"name": "Bream",
			"min_level": 4,
			"max_level": 7,
			"sprite_path": "res://assets/fish/uncommon/bream.png"
		},
		{
			"name": "Clown Fish",
			"min_level": 5,
			"max_level": 8,
			"sprite_path": "res://assets/fish/uncommon/clown_fish.png"
		}
	],
	"rare": [
		{
			"name": "Atlantic Bass",
			"min_level": 7,
			"max_level": 10,
			"sprite_path": "res://assets/fish/rare/atlantic_bass.png"
		},
		{
			"name": "Banded Butterfly Fish",
			"min_level": 8,
			"max_level": 12,
			"sprite_path": "res://assets/fish/rare/banded_butterflyfish.png"
		}
	],
	"legendary": [
		{
			"name": "Blobfish",
			"min_level": 10,
			"max_level": 15,
			"sprite_path": "res://assets/fish/legendary/blobfish.png"
		}
	]
}

var rarity_weights = {
	"common": 60,
	"uncommon": 30,
	"rare": 9,
	"legendary": 1
}

var current_fish = {}
var rod_durability = 100

func roll_random_fish() -> Dictionary:
	var total_weight = 0
	for weight in rarity_weights.values():
		total_weight += weight
	
	var roll = randi_range(1, total_weight)
	var current_weight = 0
	var selected_rarity = "common"
	
	for rarity in rarity_weights.keys():
		current_weight += rarity_weights[rarity]
		if roll <= current_weight:
			selected_rarity = rarity
			break
	
	var fish_pool = fish_database[selected_rarity]
	var fish_data = fish_pool[randi() % fish_pool.size()]
	
	var fish_level = randi_range(fish_data["min_level"], fish_data["max_level"])
	var fish_health = fish_level * 20
	var fish_max_damage = fish_level * 5
	
	return {
		"name": fish_data["name"],
		"level": fish_level,
		"health": fish_health,
		"max_health": fish_health,
		"max_damage": fish_max_damage,
		"sprite_path": fish_data["sprite_path"],
		"rarity": selected_rarity
	}
