extends Control

func _on_play_button_pressed() -> void:
	# Load the main game scene
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")
