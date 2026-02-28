extends Control
class_name PagePlayer

signal page_changed(page_id: String, act_id: String)

const STORY_PATH := "res://data/story_pages.json"

@onready var background_rect: TextureRect = %BackgroundImage
@onready var story_text_label: RichTextLabel = %StoryText
@onready var choice_container: VBoxContainer = %ChoiceContainer
@onready var health_value: Label = %HealthValue
@onready var discipline_value: Label = %DisciplineValue
@onready var inventory_value: Label = %InventoryValue
@onready var hook_value: Label = %HookValue

var pages: Dictionary = {}

func _ready() -> void:
	load_story_data()
	refresh_hud()

func load_story_data() -> void:
	var file := FileAccess.open(STORY_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open story data file: %s" % STORY_PATH)
		return
	var parse_result = JSON.parse_string(file.get_as_text())
	if typeof(parse_result) != TYPE_DICTIONARY or not parse_result.has("pages"):
		push_error("Story data is not a dictionary with a 'pages' key.")
		return
	pages.clear()
	for page in parse_result["pages"]:
		pages[page.get("page_id", "")] = page

func play_page(page_id: String) -> void:
	if not pages.has(page_id):
		push_error("Missing page_id: %s" % page_id)
		return
	var page: Dictionary = pages[page_id]
	GameState.current_page_id = page_id
	emit_signal("page_changed", page_id, page.get("act_id", ""))
	apply_image(page.get("image_path", ""))
	story_text_label.text = page.get("story_text", "")
	build_choices(page.get("choices", []))
	refresh_hud()

func apply_image(image_path: String) -> void:
	if image_path.is_empty() or not ResourceLoader.exists(image_path):
		background_rect.texture = null
		return
	background_rect.texture = load(image_path)

func build_choices(choices: Array) -> void:
	for child in choice_container.get_children():
		child.queue_free()
	var shown := 0
	for choice in choices:
		if shown >= 4:
			break
		if not requirements_met(choice.get("requirements", {})):
			continue
		var button := Button.new()
		button.text = choice.get("label", "Continue")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(button)
		shown += 1

func requirements_met(requirements: Dictionary) -> bool:
	if requirements.is_empty():
		return true
	if requirements.has("discipline_is") and GameState.discipline != requirements["discipline_is"]:
		return false
	if requirements.has("hook_state_is") and GameState.hook_state != requirements["hook_state_is"]:
		return false
	if requirements.has("health_at_least") and not GameState.health_at_least(requirements["health_at_least"]):
		return false
	if requirements.has("health_at_most") and not GameState.health_at_most(requirements["health_at_most"]):
		return false
	if requirements.has("has_item") and not GameState.has_item(requirements["has_item"]):
		return false
	if requirements.has("flag_true") and not GameState.flags.get(requirements["flag_true"], false):
		return false
	if requirements.has("flag_false") and GameState.flags.get(requirements["flag_false"], false):
		return false
	if requirements.has("starting_items_count") and GameState.starting_items.size() < int(requirements["starting_items_count"]):
		return false
	return true

func _on_choice_selected(choice: Dictionary) -> void:
	apply_effects(choice.get("effects", {}))
	refresh_hud()
	var next_page_id: String = choice.get("next_page_id", "")
	if not next_page_id.is_empty():
		play_page(next_page_id)

func apply_effects(effects: Dictionary) -> void:
	if effects.has("set_discipline"):
		GameState.discipline = effects["set_discipline"]
	if effects.has("add_starting_item"):
		GameState.add_starting_item(effects["add_starting_item"])
	if effects.has("add_starting_items"):
		for item_name in effects["add_starting_items"]:
			GameState.add_starting_item(item_name)
	if effects.has("add_found_item"):
		GameState.add_found_item(effects["add_found_item"])
	if effects.has("change_health"):
		GameState.change_health_tier(int(effects["change_health"]))
	if effects.has("set_health"):
		GameState.set_health_tier(effects["set_health"])
	if effects.has("set_hook_state"):
		GameState.hook_state = effects["set_hook_state"]
	if effects.has("set_flag"):
		var set_flag: Dictionary = effects["set_flag"]
		for key in set_flag.keys():
			GameState.flags[key] = set_flag[key]
	if effects.has("consume_found_item"):
		GameState.found_items.erase(effects["consume_found_item"])
	if effects.has("remove_starting_item"):
		GameState.starting_items.erase(effects["remove_starting_item"])

func refresh_hud() -> void:
	health_value.text = GameState.health_tier
	discipline_value.text = "Unselected" if GameState.discipline.is_empty() else GameState.discipline
	var inventory_text := "Starting: %s\nFound: %s" % [
		", ".join(GameState.starting_items) if not GameState.starting_items.is_empty() else "None",
		", ".join(GameState.found_items) if not GameState.found_items.is_empty() else "None"
	]
	inventory_value.text = inventory_text
	hook_value.text = GameState.hook_state
