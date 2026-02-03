extends Control

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/nickname.tscn")

func _on_customize_pressed():
	get_tree().change_scene_to_file("res://scenes/customize.tscn")

func _on_button_4_pressed() -> void:
	pass # Replace with function body.


func _on_button_3_pressed() -> void:
	pass # Replace with function body.
