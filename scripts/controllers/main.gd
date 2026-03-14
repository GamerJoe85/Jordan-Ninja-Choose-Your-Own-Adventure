extends Control

@export var act_scene_paths: Dictionary = {
	"act_1": "res://scenes/acts/Act1.tscn",
	"act_2": "res://scenes/acts/Act2.tscn",
	"act_3": "res://scenes/acts/Act3.tscn",
	"act_4": "res://scenes/acts/Act4.tscn",
	"act_5": "res://scenes/acts/Act5.tscn",
	"act_6": "res://scenes/acts/Act6.tscn"
}

@onready var page_player: PagePlayer = %PagePlayer
@onready var active_act_label: Label = %ActiveActLabel

var active_act: Node = null

func _ready() -> void:
	GameState.reset()
	page_player.page_changed.connect(_on_page_changed)
	start_act("act_1")

func start_act(act_id: String) -> void:
	if not act_scene_paths.has(act_id):
		return
	if active_act != null:
		active_act.queue_free()
	var act_scene: PackedScene = load(str(act_scene_paths[act_id]))
	active_act = act_scene.instantiate()
	add_child(active_act)
	active_act_label.text = "Current Act: %s" % str(active_act.get("act_id"))
	var start_page_id: String = str(active_act.get("start_page_id"))
	page_player.play_page(start_page_id)

func _on_page_changed(_page_id: String, act_id: String) -> void:
	if not act_id.is_empty():
		active_act_label.text = "Current Act: %s" % act_id
