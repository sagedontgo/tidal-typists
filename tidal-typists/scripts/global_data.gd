extends Node

# Game state
var has_started_game: bool = false
var has_saved_player_position: bool = false
var saved_player_position: Vector2 = Vector2.ZERO

# Player info
var player_nickname: String = ""
var player_gender: String = ""

# Inventory/Hotbar persistence
var saved_inventory_items: Array = []
var saved_hotbar_items: Array = []
var has_initialized_inventory: bool = false
var has_initialized_hotbar: bool = false

# Fish database (existing - keep as is)
var fish_database = {
	"common": [
		{"name": "Cod", "min_level": 1, "max_level": 3, "sprite_path": "res://assets/fish/common/cod.png"},
		{"name": "Dab", "min_level": 1, "max_level": 3, "sprite_path": "res://assets/fish/common/dab.png"},
		{"name": "Herring", "min_level": 1, "max_level": 4, "sprite_path": "res://assets/fish/common/herring.png"},
		{"name": "Mackerel", "min_level": 2, "max_level": 4, "sprite_path": "res://assets/fish/common/mackerel.png"},
		{"name": "Plaice", "min_level": 1, "max_level": 3, "sprite_path": "res://assets/fish/common/plaice.png"},
		{"name": "Pollock", "min_level": 2, "max_level": 4, "sprite_path": "res://assets/fish/common/pollock.png"},
		{"name": "Sardine", "min_level": 1, "max_level": 3, "sprite_path": "res://assets/fish/common/sardine.png"},
		{"name": "Whiting", "min_level": 2, "max_level": 5, "sprite_path": "res://assets/fish/common/whiting.png"}
	],
	"uncommon": [
		{"name": "Blue Tang", "min_level": 4, "max_level": 7, "sprite_path": "res://assets/fish/uncommon/blue_tang.png"},
		{"name": "Bream", "min_level": 4, "max_level": 7, "sprite_path": "res://assets/fish/uncommon/bream.png"},
		{"name": "Clown Fish", "min_level": 5, "max_level": 8, "sprite_path": "res://assets/fish/uncommon/clown_fish.png"},
		{"name": "Cowfish", "min_level": 4, "max_level": 7, "sprite_path": "res://assets/fish/uncommon/cowfish.png"},
		{"name": "Flounder", "min_level": 5, "max_level": 8, "sprite_path": "res://assets/fish/uncommon/flounder.png"},
		{"name": "Parrot Fish", "min_level": 5, "max_level": 8, "sprite_path": "res://assets/fish/uncommon/parrot_fish.png"},
		{"name": "Pufferfish", "min_level": 4, "max_level": 8, "sprite_path": "res://assets/fish/uncommon/pufferfish.png"},
		{"name": "Weaver Fish", "min_level": 5, "max_level": 9, "sprite_path": "res://assets/fish/uncommon/weaver_fish.png"}
	],
	"rare": [
		{"name": "Atlantic Bass", "min_level": 7, "max_level": 10, "sprite_path": "res://assets/fish/rare/atlantic_bass.png"},
		{"name": "Ballan Wrasse", "min_level": 8, "max_level": 11, "sprite_path": "res://assets/fish/rare/ballan_wrasse.png"},
		{"name": "Banded Butterfly Fish", "min_level": 8, "max_level": 12, "sprite_path": "res://assets/fish/rare/banded_butterflyfish.png"},
		{"name": "Black Drum", "min_level": 7, "max_level": 11, "sprite_path": "res://assets/fish/rare/black_drum.png"},
		{"name": "Bonefish", "min_level": 9, "max_level": 12, "sprite_path": "res://assets/fish/rare/bonefish.png"},
		{"name": "Cobia", "min_level": 8, "max_level": 12, "sprite_path": "res://assets/fish/rare/cobia.png"},
		{"name": "Pompano", "min_level": 7, "max_level": 11, "sprite_path": "res://assets/fish/rare/pompano.png"},
		{"name": "Red Snapper", "min_level": 8, "max_level": 13, "sprite_path": "res://assets/fish/rare/red_snapper.png"},
		{"name": "Salmon", "min_level": 9, "max_level": 13, "sprite_path": "res://assets/fish/rare/salmon.png"}
	],
	"legendary": [
		{"name": "Angelfish", "min_level": 12, "max_level": 18, "sprite_path": "res://assets/fish/legendary/angelfish.png"},
		{"name": "Anglerfish", "min_level": 13, "max_level": 19, "sprite_path": "res://assets/fish/legendary/anglerfish.png"},
		{"name": "Blobfish", "min_level": 10, "max_level": 15, "sprite_path": "res://assets/fish/legendary/blobfish.png"},
		{"name": "Halibut", "min_level": 14, "max_level": 20, "sprite_path": "res://assets/fish/legendary/halibut.png"},
		{"name": "Lionfish", "min_level": 13, "max_level": 19, "sprite_path": "res://assets/fish/legendary/lionfish.png"},
		{"name": "Sea Horse", "min_level": 11, "max_level": 16, "sprite_path": "res://assets/fish/legendary/sea_horse.png"},
		{"name": "Silver Eel", "min_level": 12, "max_level": 17, "sprite_path": "res://assets/fish/legendary/silver_eel.png"},
		{"name": "Stingray", "min_level": 14, "max_level": 20, "sprite_path": "res://assets/fish/legendary/stingray.png"},
		{"name": "Tuna", "min_level": 15, "max_level": 22, "sprite_path": "res://assets/fish/legendary/tuna.png"},
		{"name": "Wolfish", "min_level": 13, "max_level": 19, "sprite_path": "res://assets/fish/legendary/wolfish.png"}
	]
}

var rarity_weights = {
	"common": 60,
	"uncommon": 30,
	"rare": 9,
	"legendary": 1
}

# Economy
var current_fish = {}
var rod_durability = 100
var player_money: int = 100

# UPDATED: Custom Rod System (matching your friend's assets)
var current_rod: Dictionary = {
	"name": "Basic Rod",
	"tier": 1,
	"max_durability": 100,
	"current_durability": 100,
	"rarity_boost": 0,
	"level_boost": 0,
	"price": 0,
	"icon_path": "res://assets/items/rods/basic_rod.png"
}

# UPDATED: Custom Bait System (matching your friend's assets)
var current_bait: Dictionary = {
	"name": "Basic Bait",
	"tier": 1,
	"rarity_boost": 0,
	"level_boost": 0,
	"price": 0,
	"uses_remaining": 10,
	"max_uses": 10,
	"icon_path": "res://assets/items/baits/basic_bait.png"
}

# UPDATED: Custom Rod Shop Inventory
var rod_shop_inventory = [
	{
		"name": "Basic Rod",
		"tier": 1,
		"max_durability": 100,
		"rarity_boost": 0,
		"level_boost": 0,
		"price": 0,
		"icon_path": "res://assets/items/rods/basic_rod.png",
		"description": "A simple wooden rod. Free for beginners!"
	},
	{
		"name": "Iron Rod",
		"tier": 2,
		"max_durability": 150,
		"rarity_boost": 10,
		"level_boost": 2,
		"price": 500,
		"icon_path": "res://assets/items/rods/iron_rod.png",
		"description": "Sturdy iron construction. Better fish await!"
	},
	{
		"name": "Golden Rod",
		"tier": 3,
		"max_durability": 200,
		"rarity_boost": 25,
		"level_boost": 5,
		"price": 2000,
		"icon_path": "res://assets/items/rods/golden_rod.png",
		"description": "Gleaming gold attracts rare fish!"
	},
	{
		"name": "Platinum Rod",
		"tier": 4,
		"max_durability": 250,
		"rarity_boost": 40,
		"level_boost": 8,
		"price": 5000,
		"icon_path": "res://assets/items/rods/platinum_rod.png",
		"description": "Premium platinum for serious anglers."
	},
	{
		"name": "Reinforced Rod",
		"tier": 5,
		"max_durability": 350,
		"rarity_boost": 60,
		"level_boost": 12,
		"price": 15000,
		"icon_path": "res://assets/items/rods/reinforced_rod.png",
		"description": "The ultimate fishing rod! Legendary fish beware!"
	}
]

# UPDATED: Custom Bait Shop Inventory
var bait_shop_inventory = [
	{
		"name": "Basic Bait",
		"tier": 1,
		"rarity_boost": 0,
		"level_boost": 0,
		"max_uses": 10,
		"price": 10,
		"icon_path": "res://assets/items/baits/basic_bait.png",
		"description": "Simple worms. Good for common fish."
	},
	{
		"name": "Small Fish Bait",
		"tier": 2,
		"rarity_boost": 15,
		"level_boost": 3,
		"max_uses": 15,
		"price": 150,
		"icon_path": "res://assets/items/baits/small_fish_bait.png",
		"description": "Small fish attract bigger predators!"
	},
	{
		"name": "Goldfish Bait",
		"tier": 3,
		"rarity_boost": 35,
		"level_boost": 7,
		"max_uses": 20,
		"price": 800,
		"icon_path": "res://assets/items/baits/goldfish_bait.png",
		"description": "Shiny goldfish lure rare catches!"
	}
]

func roll_random_fish() -> Dictionary:
	"""Generate a random fish based on current rod and bait"""
	var rod_boost = current_rod.get("rarity_boost", 0)
	var bait_boost = current_bait.get("rarity_boost", 0)
	var total_rarity_boost = rod_boost + bait_boost
	
	var adjusted_weights = {
		"common": max(10, rarity_weights["common"] - total_rarity_boost),
		"uncommon": rarity_weights["uncommon"] + (total_rarity_boost * 0.4),
		"rare": rarity_weights["rare"] + (total_rarity_boost * 0.4),
		"legendary": rarity_weights["legendary"] + (total_rarity_boost * 0.2)
	}
	
	var total_weight = 0
	for weight in adjusted_weights.values():
		total_weight += weight
	
	var roll = randf() * total_weight
	var current_weight = 0.0
	var selected_rarity = "common"
	
	for rarity in adjusted_weights.keys():
		current_weight += adjusted_weights[rarity]
		if roll <= current_weight:
			selected_rarity = rarity
			break
	
	var fish_pool = fish_database[selected_rarity]
	var fish_data = fish_pool[randi() % fish_pool.size()]
	
	var level_boost = current_rod.get("level_boost", 0) + current_bait.get("level_boost", 0)
	var min_level = fish_data["min_level"] + level_boost
	var max_level = fish_data["max_level"] + level_boost
	
	var fish_level = randi_range(min_level, max_level)
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

func calculate_fish_value(fish: Dictionary) -> int:
	"""Calculate sell value based on level and rarity"""
	var base_value = 10
	var level = fish.get("level", 1)
	var rarity = fish.get("rarity", "common")
	
	var rarity_multiplier = 1.0
	match rarity:
		"common":
			rarity_multiplier = 1.0
		"uncommon":
			rarity_multiplier = 3.0
		"rare":
			rarity_multiplier = 8.0
		"legendary":
			rarity_multiplier = 25.0
	
	return int(base_value * level * rarity_multiplier)
