extends Control

const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"

@onready var start_button: Button = get_node_or_null("CenterContainer/Margin/VBox/Start") as Button

var _start_requested: bool = false

func _ready() -> void:
	if start_button == null:
		push_error("TitleMenu is missing Start button at path CenterContainer/Margin/VBox/Start")
		return
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	if _start_requested:
		return
	_start_requested = true
	if start_button != null:
		start_button.disabled = true
	start_game()

func start_game() -> void:
	var tree: SceneTree = get_tree()
	var error_code: int = tree.change_scene_to_file(MAIN_SCENE_PATH)
	if error_code == OK:
		return
	push_error("Failed to load Main.tscn. Error code: %d" % error_code)
	if start_button != null:
		start_button.disabled = false
	_start_requested = false
