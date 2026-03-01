extends Control
class_name PagePlayer

signal page_changed(page_id: String, act_id: String)

const STORY_PATH: String = "res://data/story_pages.json"

@export var image_overrides: Array[PageImageEntry] = []

@onready var background_rect: TextureRect = %BackgroundImage
@onready var story_text_label: RichTextLabel = %StoryText
@onready var choice_container: VBoxContainer = %ChoiceContainer
@onready var health_value: Label = %HealthValue
@onready var discipline_value: Label = %DisciplineValue
@onready var inventory_value: Label = %InventoryValue
@onready var hook_value: Label = %HookValue

var pages: Dictionary = {}
var image_override_map: Dictionary = {}

func _ready() -> void:
	load_story_data()
	build_image_override_map()
	refresh_hud()

func load_story_data() -> void:
	var file: FileAccess = FileAccess.open(STORY_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open story data file: %s" % STORY_PATH)
		return
	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parse_result) != TYPE_DICTIONARY or not (parse_result as Dictionary).has("pages"):
		push_error("Story data is not a dictionary with a 'pages' key.")
		return
	var parsed_dictionary: Dictionary = parse_result
	pages.clear()
	for page_variant in parsed_dictionary["pages"]:
		var page: Dictionary = page_variant
		var page_id: String = str(page.get("page_id", ""))
		pages[page_id] = page

func build_image_override_map() -> void:
	image_override_map.clear()
	for entry in image_overrides:
		if entry == null:
			continue
		var override_page_id: String = entry.page_id.strip_edges()
		if override_page_id.is_empty() or entry.image == null:
			continue
		image_override_map[override_page_id] = entry.image

func play_page(page_id: String) -> void:
	if not pages.has(page_id):
		push_error("Missing page_id: %s" % page_id)
		return
	var page: Dictionary = pages[page_id]
	GameState.current_page_id = page_id
	emit_signal("page_changed", page_id, str(page.get("act_id", "")))
	apply_image(page_id, str(page.get("image_path", "")))
	story_text_label.text = str(page.get("story_text", ""))
	build_choices(page.get("choices", []) as Array)
	refresh_hud()

func apply_image(page_id: String, image_path: String) -> void:
	if image_override_map.has(page_id):
		background_rect.texture = image_override_map[page_id]
		return
	var normalized_path: String = _normalize_image_path(image_path)
	if normalized_path.is_empty() or not ResourceLoader.exists(normalized_path):
		background_rect.texture = null
		return
	background_rect.texture = load(normalized_path)


func _normalize_image_path(raw_path: String) -> String:
	var cleaned: String = raw_path.strip_edges()
	if cleaned.is_empty():
		return cleaned
	if cleaned.contains("res://"):
		var start_index: int = cleaned.find("res://")
		cleaned = cleaned.substr(start_index)
	var stop_chars: PackedStringArray = PackedStringArray(["`", "|", " "])
	var stop_index: int = cleaned.length()
	for stop_char in stop_chars:
		var found_index: int = cleaned.find(stop_char)
		if found_index != -1 and found_index < stop_index:
			stop_index = found_index
	cleaned = cleaned.substr(0, stop_index).strip_edges()
	return cleaned

func build_choices(choices: Array) -> void:
	for child in choice_container.get_children():
		child.queue_free()
	var shown: int = 0
	for choice_variant in choices:
		if shown >= 4:
			break
		var choice: Dictionary = choice_variant
		if not requirements_met(choice.get("requirements", {}) as Dictionary):
			continue
		var button: Button = Button.new()
		button.text = str(choice.get("label", "Continue"))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 88)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(button)
		shown += 1

func requirements_met(requirements: Dictionary) -> bool:
	if requirements.is_empty():
		return true
	if requirements.has("discipline_is") and GameState.discipline != str(requirements["discipline_is"]):
		return false
	if requirements.has("hook_state_is") and GameState.hook_state != str(requirements["hook_state_is"]):
		return false
	if requirements.has("health_at_least") and not GameState.health_at_least(str(requirements["health_at_least"])):
		return false
	if requirements.has("health_at_most") and not GameState.health_at_most(str(requirements["health_at_most"])):
		return false
	if requirements.has("has_item") and not GameState.has_item(str(requirements["has_item"])):
		return false
	if requirements.has("flag_true") and not bool(GameState.flags.get(str(requirements["flag_true"]), false)):
		return false
	if requirements.has("flag_false") and bool(GameState.flags.get(str(requirements["flag_false"]), false)):
		return false
	if requirements.has("starting_items_count") and GameState.starting_items.size() < int(requirements["starting_items_count"]):
		return false
	return true

func _on_choice_selected(choice: Dictionary) -> void:
	apply_effects(choice.get("effects", {}) as Dictionary)
	refresh_hud()
	var next_page_id: String = str(choice.get("next_page_id", ""))
	if not next_page_id.is_empty():
		play_page(next_page_id)

func apply_effects(effects: Dictionary) -> void:
	if effects.has("set_discipline"):
		GameState.discipline = str(effects["set_discipline"])
	if effects.has("add_starting_item"):
		GameState.add_starting_item(str(effects["add_starting_item"]))
	if effects.has("add_starting_items"):
		for item_name_variant in effects["add_starting_items"]:
			GameState.add_starting_item(str(item_name_variant))
	if effects.has("add_found_item"):
		GameState.add_found_item(str(effects["add_found_item"]))
	if effects.has("change_health"):
		GameState.change_health_tier(int(effects["change_health"]))
	if effects.has("set_health"):
		GameState.set_health_tier(str(effects["set_health"]))
	if effects.has("set_hook_state"):
		GameState.hook_state = str(effects["set_hook_state"])
	if effects.has("set_flag"):
		var set_flag: Dictionary = effects["set_flag"]
		for key_variant in set_flag.keys():
			var key: String = str(key_variant)
			GameState.flags[key] = set_flag[key_variant]
	if effects.has("consume_found_item"):
		GameState.found_items.erase(str(effects["consume_found_item"]))
	if effects.has("remove_starting_item"):
		GameState.starting_items.erase(str(effects["remove_starting_item"]))

func refresh_hud() -> void:
	health_value.text = GameState.health_tier
	discipline_value.text = "Unselected" if GameState.discipline.is_empty() else GameState.discipline
	var inventory_text: String = "Starting: %s\nFound: %s" % [
		", ".join(GameState.starting_items) if not GameState.starting_items.is_empty() else "None",
		", ".join(GameState.found_items) if not GameState.found_items.is_empty() else "None"
	]
	inventory_value.text = inventory_text
	hook_value.text = GameState.hook_state
