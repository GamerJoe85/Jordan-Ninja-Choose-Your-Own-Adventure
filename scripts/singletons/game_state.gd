extends Node

const HEALTH_ORDER := ["Dying", "Critical", "Wounded", "Healthy", "Prime"]

var health_tier: String = "Prime"
var discipline: String = ""
var starting_items: Array[String] = []
var found_items: Array[String] = []
var hook_state: String = "Good"
var flags: Dictionary = {}
var current_page_id: String = ""

func reset() -> void:
	health_tier = "Prime"
	discipline = ""
	starting_items.clear()
	found_items.clear()
	hook_state = "Good"
	flags = {
		"detected": false,
		"cavern_found": false,
		"used_reflex_dodge": false,
		"used_focus_path": false,
		"used_steel_guard": false,
		"used_shadow_avoid": false
	}
	current_page_id = ""

func _ready() -> void:
	reset()

func add_starting_item(item_name: String) -> void:
	if starting_items.size() >= 3:
		return
	if starting_items.has(item_name):
		return
	starting_items.append(item_name)

func add_found_item(item_name: String) -> void:
	if found_items.size() >= 2:
		return
	if found_items.has(item_name):
		return
	found_items.append(item_name)

func has_item(item_name: String) -> bool:
	return starting_items.has(item_name) or found_items.has(item_name)

func set_health_tier(new_tier: String) -> void:
	if HEALTH_ORDER.has(new_tier):
		health_tier = new_tier

func change_health_tier(delta: int) -> void:
	var index := HEALTH_ORDER.find(health_tier)
	if index == -1:
		index = HEALTH_ORDER.size() - 1
	var next_index := clamp(index + delta, 0, HEALTH_ORDER.size() - 1)
	health_tier = HEALTH_ORDER[next_index]

func health_at_least(target_tier: String) -> bool:
	var current_index := HEALTH_ORDER.find(health_tier)
	var target_index := HEALTH_ORDER.find(target_tier)
	if current_index == -1 or target_index == -1:
		return false
	return current_index >= target_index

func health_at_most(target_tier: String) -> bool:
	var current_index := HEALTH_ORDER.find(health_tier)
	var target_index := HEALTH_ORDER.find(target_tier)
	if current_index == -1 or target_index == -1:
		return false
	return current_index <= target_index
