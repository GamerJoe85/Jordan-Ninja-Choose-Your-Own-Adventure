extends Control

@onready var start_button: Button = %Start

func _ready() -> void:
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	var error_code: int = get_tree().change_scene_to_file("res://scenes/Main.tscn")
	if error_code != OK:
		push_error("Failed to load Main.tscn. Error code: %d" % error_code)
