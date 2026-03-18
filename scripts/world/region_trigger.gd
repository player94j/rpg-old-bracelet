extends Area2D
## Region Trigger - Transitions between biomes/regions with audio feedback

@export var target_region: String = ""
@export var region_display_name: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not target_region.is_empty():
		if GameManager.current_region != target_region:
			GameManager.current_region = target_region
			if target_region not in GameManager.discovered_regions:
				GameManager.discovered_regions.append(target_region)
			GameManager.region_entered.emit(target_region)
			QuestManager.notify_region_entered(target_region)
			# Show region name
			var ui = get_tree().get_first_node_in_group("game_ui")
			if ui and ui.has_method("show_region_name"):
				ui.show_region_name(region_display_name)
