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
@onready var event_notice: Label = %EventNotice
@onready var event_notice_overlay: CanvasItem = %EventNoticeOverlay
@onready var event_notice_continue_button: Button = %EventNoticeContinueButton
@onready var use_health_herb_button: Button = %UseHealthHerbButton

var pages: Dictionary = {}
var image_override_map: Dictionary = {}
var pending_next_page_id: String = ""
var pending_notices: Array[String] = []

func _ready() -> void:
	load_story_data()
	build_image_override_map()
	if use_health_herb_button != null and not use_health_herb_button.pressed.is_connected(_on_use_health_herb_pressed):
		use_health_herb_button.pressed.connect(_on_use_health_herb_pressed)
	if event_notice_continue_button != null and not event_notice_continue_button.pressed.is_connected(_on_notice_continue_pressed):
		event_notice_continue_button.pressed.connect(_on_notice_continue_pressed)
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
	_hide_notice_overlay()
	story_text_label.text = resolve_story_text(page)
	build_choices(page.get("choices", []) as Array)
	refresh_hud()

func apply_image(page_id: String, image_path: String) -> void:
	if image_override_map.has(page_id):
		background_rect.texture = image_override_map[page_id]
		return
	var resolved_path: String = _resolve_image_path(page_id, image_path)
	if resolved_path.is_empty():
		background_rect.texture = null
		push_warning("No image found for page_id '%s'. Checked JSON path and fallback filenames in res://assets/images/." % page_id)
		return
	background_rect.texture = load(resolved_path)


func _resolve_image_path(page_id: String, raw_path: String) -> String:
	var normalized_path: String = _normalize_image_path(raw_path)
	if not normalized_path.is_empty() and ResourceLoader.exists(normalized_path):
		return normalized_path
	for candidate in _image_fallback_candidates(page_id):
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _image_fallback_candidates(page_id: String) -> PackedStringArray:
	var candidates: PackedStringArray = PackedStringArray()
	candidates.append("res://assets/images/%s.png" % page_id)
	candidates.append("res://assets/images/%s.webp" % page_id)
	candidates.append("res://assets/images/%s.jpg" % page_id)
	candidates.append("res://assets/images/%s.jpeg" % page_id)

	# Legacy compatibility: act1_p05_vow -> act1_05_vow
	var legacy_id: String = page_id
	if page_id.begins_with("act"):
		var under_index: int = page_id.find("_")
		if under_index != -1:
			var head: String = page_id.substr(0, under_index + 1)
			var tail: String = page_id.substr(under_index + 1)
			if tail.begins_with("p"):
				legacy_id = head + tail.substr(1)
	if legacy_id != page_id:
		candidates.append("res://assets/images/%s.png" % legacy_id)
		candidates.append("res://assets/images/%s.webp" % legacy_id)
		candidates.append("res://assets/images/%s.jpg" % legacy_id)
		candidates.append("res://assets/images/%s.jpeg" % legacy_id)
	return candidates


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


func resolve_story_text(page: Dictionary) -> String:
	var variants: Array = page.get("story_text_variants", []) as Array
	for variant in variants:
		var variant_dict: Dictionary = variant as Dictionary
		if requirements_met(variant_dict.get("requirements", {}) as Dictionary):
			return str(variant_dict.get("text", ""))
	return str(page.get("story_text", ""))

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
		button.custom_minimum_size = Vector2(0, 72)
		button.add_theme_font_size_override("font_size", 30)
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		var normal_style: StyleBoxFlat = StyleBoxFlat.new()
		normal_style.bg_color = Color(0, 0, 0, 0.55)
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_left = 6
		normal_style.corner_radius_bottom_right = 6
		var hover_style: StyleBoxFlat = normal_style.duplicate()
		hover_style.bg_color = Color(0.08, 0.08, 0.08, 0.72)
		var pressed_style: StyleBoxFlat = normal_style.duplicate()
		pressed_style.bg_color = Color(0.13, 0.13, 0.13, 0.78)
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(button)
		shown += 1

func requirements_met(requirements: Dictionary) -> bool:
	if requirements.is_empty():
		return true
	if requirements.has("discipline_is") and GameState.discipline != str(requirements["discipline_is"]):
		return false
	if requirements.has("discipline_not_in"):
		for blocked_discipline_variant in requirements["discipline_not_in"]:
			if GameState.discipline == str(blocked_discipline_variant):
				return false
	if requirements.has("hook_state_is") and GameState.hook_state != str(requirements["hook_state_is"]):
		return false
	if requirements.has("health_at_least") and not GameState.health_at_least(str(requirements["health_at_least"])):
		return false
	if requirements.has("health_at_most") and not GameState.health_at_most(str(requirements["health_at_most"])):
		return false
	if requirements.has("has_item") and not GameState.has_item(str(requirements["has_item"])):
		return false
	if requirements.has("has_any_item"):
		var has_any: bool = false
		for required_item_variant in requirements["has_any_item"]:
			if GameState.has_item(str(required_item_variant)):
				has_any = true
				break
		if not has_any:
			return false
	if requirements.has("lacks_item") and GameState.has_item(str(requirements["lacks_item"])):
		return false
	if requirements.has("flag_true") and not bool(GameState.flags.get(str(requirements["flag_true"]), false)):
		return false
	if requirements.has("flag_false") and bool(GameState.flags.get(str(requirements["flag_false"]), false)):
		return false
	if requirements.has("starting_items_count") and GameState.starting_items.size() < int(requirements["starting_items_count"]):
		return false
	return true

func _on_choice_selected(choice: Dictionary) -> void:
	var previous_health: String = GameState.health_tier
	var previous_hook_state: String = GameState.hook_state
	var effects: Dictionary = choice.get("effects", {}) as Dictionary
	apply_effects(effects)
	var custom_notice: String = str(effects.get("notice_message", "")).strip_edges()
	if not custom_notice.is_empty():
		queue_notice(custom_notice)
	var auto_used_herb: bool = false
	if GameState.health_tier == "Dying" and GameState.has_item("Health Herb"):
		GameState.starting_items.erase("Health Herb")
		GameState.found_items.erase("Health Herb")
		GameState.change_health_tier(1)
		auto_used_herb = true
		queue_notice("Auto-used Health Herb to keep Jordan alive.")
	var took_damage_at_dying: bool = (
		previous_health == "Dying"
		and int(effects.get("change_health", 0)) < 0
		and not auto_used_herb
	)
	if previous_health != GameState.health_tier or auto_used_herb:
		if not custom_notice.is_empty():
			pass
		elif GameState.health_at_least(previous_health):
			queue_notice("Health restored: %s" % GameState.health_tier)
		else:
			queue_notice("Health dropped to %s" % GameState.health_tier)
	if previous_hook_state != GameState.hook_state and GameState.hook_state == "Damaged" and custom_notice.is_empty():
		queue_notice("Your rope was damaged.")
	refresh_hud()
	var next_page_id: String = str(choice.get("next_page_id", ""))
	if took_damage_at_dying:
		next_page_id = "act_end_universal_death"
	navigate_to_next_page(next_page_id)

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
	if effects.has("add_found_items"):
		for found_item_variant in effects["add_found_items"]:
			GameState.add_found_item(str(found_item_variant))
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
		var item_to_remove: String = str(effects["remove_starting_item"])
		GameState.starting_items.erase(item_to_remove)
		GameState.found_items.erase(item_to_remove)

func refresh_hud() -> void:
	health_value.text = GameState.health_tier
	discipline_value.text = "Unselected" if GameState.discipline.is_empty() else GameState.discipline
	var start_items_text: String = ", ".join(GameState.starting_items) if not GameState.starting_items.is_empty() else "None"
	var found_items_text: String = ", ".join(GameState.found_items) if not GameState.found_items.is_empty() else "None"
	inventory_value.text = "Start: %s\nFound: %s" % [start_items_text, found_items_text]
	hook_value.text = GameState.hook_state
	if use_health_herb_button != null:
		use_health_herb_button.visible = GameState.has_item("Health Herb")
		use_health_herb_button.disabled = GameState.health_tier == "Prime"

func _on_use_health_herb_pressed() -> void:
	if not GameState.has_item("Health Herb"):
		queue_notice("No Health Herb available.")
		show_next_notice()
		return
	if GameState.health_tier == "Prime":
		queue_notice("Health is already at maximum.")
		show_next_notice()
		return
	GameState.starting_items.erase("Health Herb")
	GameState.found_items.erase("Health Herb")
	GameState.change_health_tier(1)
	queue_notice("Used Health Herb. Health restored to %s" % GameState.health_tier)
	show_next_notice()
	refresh_hud()


func queue_notice(message: String) -> void:
	var cleaned_message: String = message.strip_edges()
	if cleaned_message.is_empty():
		return
	pending_notices.append(cleaned_message)


func show_next_notice() -> void:
	if pending_notices.is_empty():
		_hide_notice_overlay()
		return
	if event_notice == null:
		return
	event_notice.text = pending_notices[0]
	event_notice.visible = true
	if event_notice_overlay != null:
		event_notice_overlay.visible = true


func navigate_to_next_page(next_page_id: String) -> void:
	if next_page_id.is_empty():
		show_next_notice()
		return
	if pending_notices.is_empty():
		go_to_page(next_page_id)
		return
	pending_next_page_id = next_page_id
	show_next_notice()


func go_to_page(next_page_id: String) -> void:
	if next_page_id == "act1_start" and GameState.current_page_id != "":
		GameState.reset()
	play_page(next_page_id)


func _on_notice_continue_pressed() -> void:
	if not pending_notices.is_empty():
		pending_notices.remove_at(0)
	if not pending_notices.is_empty():
		show_next_notice()
		return
	_hide_notice_overlay()
	if not pending_next_page_id.is_empty():
		var target_page: String = pending_next_page_id
		pending_next_page_id = ""
		go_to_page(target_page)


func _hide_notice_overlay() -> void:
	if event_notice != null:
		event_notice.text = ""
		event_notice.visible = false
	if event_notice_overlay != null:
		event_notice_overlay.visible = false
