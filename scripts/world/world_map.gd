extends Node2D
## WorldMap - Generates the open world with multiple biomes
## Uses procedural tile placement for a seamless feel with distinct biome visuals

const TILE_SIZE = 32
const REGION_SIZE = 50  # tiles per region side

# Biome data - more vibrant, distinct colors
var biome_colors: Dictionary = {
	"ashen_wastes": Color(0.38, 0.33, 0.28),
	"crimson_mire": Color(0.28, 0.16, 0.12),
	"frozen_peaks": Color(0.72, 0.78, 0.88),
	"shadow_citadel": Color(0.14, 0.09, 0.18),
}

var biome_wall_colors: Dictionary = {
	"ashen_wastes": Color(0.28, 0.24, 0.20),
	"crimson_mire": Color(0.20, 0.10, 0.06),
	"frozen_peaks": Color(0.55, 0.60, 0.75),
	"shadow_citadel": Color(0.10, 0.05, 0.12),
}

# Accent colors for ground detail
var biome_accent_colors: Dictionary = {
	"ashen_wastes": Color(0.42, 0.36, 0.30),
	"crimson_mire": Color(0.32, 0.12, 0.08),
	"frozen_peaks": Color(0.80, 0.85, 0.92),
	"shadow_citadel": Color(0.18, 0.10, 0.22),
}

# Region positions (in tiles, relative to world origin)
var region_positions: Dictionary = {
	"ashen_wastes": Vector2i(0, 0),
	"crimson_mire": Vector2i(REGION_SIZE + 5, 0),
	"frozen_peaks": Vector2i(0, -(REGION_SIZE + 5)),
	"shadow_citadel": Vector2i(REGION_SIZE + 5, -(REGION_SIZE + 5)),
}

var walls: Array[Rect2i] = []
var secret_areas: Array[Dictionary] = []

func _ready() -> void:
	_generate_world()

func _generate_world() -> void:
	for child in get_children():
		child.queue_free()
	
	for region_id in region_positions:
		var origin = region_positions[region_id] * TILE_SIZE
		_generate_region(region_id, origin)
	
	_generate_paths()

func _generate_region(region_id: String, origin: Vector2) -> void:
	var ground_color = biome_colors[region_id]
	var wall_color = biome_wall_colors[region_id]
	var accent_color = biome_accent_colors[region_id]
	
	# Ground base
	var ground = ColorRect.new()
	ground.color = ground_color
	ground.position = origin
	ground.size = Vector2(REGION_SIZE * TILE_SIZE, REGION_SIZE * TILE_SIZE)
	ground.z_index = -10
	add_child(ground)
	
	# Ground texture detail patches
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(region_id)
	var num_patches = rng.randi_range(20, 40)
	for _i in range(num_patches):
		var px = rng.randf_range(0, REGION_SIZE * TILE_SIZE)
		var py = rng.randf_range(0, REGION_SIZE * TILE_SIZE)
		var ps = rng.randf_range(16, 64)
		var patch = ColorRect.new()
		patch.position = origin + Vector2(px, py)
		patch.size = Vector2(ps, ps)
		patch.color = accent_color.lerp(ground_color, rng.randf_range(0.3, 0.7))
		patch.z_index = -9
		add_child(patch)
	
	# Region border decoration
	var border = _create_border(origin, REGION_SIZE * TILE_SIZE, wall_color)
	add_child(border)
	
	# Region name label at center
	var name_label = Label.new()
	name_label.text = _get_region_display_name(region_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = origin + Vector2(REGION_SIZE * TILE_SIZE * 0.5 - 80, REGION_SIZE * TILE_SIZE * 0.5 - 10)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 0.15))
	name_label.z_index = -8
	add_child(name_label)
	
	# Walls (obstacles)
	var num_walls = rng.randi_range(8, 15)
	for _i in range(num_walls):
		var wx = rng.randi_range(3, REGION_SIZE - 6)
		var wy = rng.randi_range(3, REGION_SIZE - 6)
		var ww = rng.randi_range(1, 4)
		var wh = rng.randi_range(1, 4)
		_create_wall(origin + Vector2(wx * TILE_SIZE, wy * TILE_SIZE), Vector2(ww * TILE_SIZE, wh * TILE_SIZE), wall_color)
	
	# Decorations (trees, rocks, etc)
	var num_decorations = rng.randi_range(20, 40)
	for _i in range(num_decorations):
		var dx = rng.randf_range(2, REGION_SIZE - 2) * TILE_SIZE
		var dy = rng.randf_range(2, REGION_SIZE - 2) * TILE_SIZE
		var dec = _create_decoration(origin + Vector2(dx, dy), region_id, rng)
		add_child(dec)
	
	# Region trigger
	_create_region_trigger(region_id, origin)
	
	# Secret areas
	if rng.randf() < 0.7:
		var sx = rng.randi_range(REGION_SIZE - 10, REGION_SIZE - 3) * TILE_SIZE
		var sy = rng.randi_range(REGION_SIZE - 10, REGION_SIZE - 3) * TILE_SIZE
		_create_secret_area(region_id, origin + Vector2(sx, sy))

func _get_region_display_name(region_id: String) -> String:
	match region_id:
		"ashen_wastes": return "THE ASHEN WASTES"
		"crimson_mire": return "THE CRIMSON MIRE"
		"frozen_peaks": return "THE FROZEN PEAKS"
		"shadow_citadel": return "THE SHADOW CITADEL"
		_: return region_id.to_upper()

func _create_wall(pos: Vector2, size: Vector2, color: Color) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 4
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	wall.add_child(shape)
	
	var visual = ColorRect.new()
	visual.color = color
	visual.size = size
	visual.z_index = -5
	wall.add_child(visual)
	
	# Wall highlight edge
	var edge = ColorRect.new()
	edge.color = color.lightened(0.15)
	edge.size = Vector2(size.x, 2)
	edge.z_index = -4
	wall.add_child(edge)
	
	add_child(wall)

func _create_border(origin: Vector2, size: float, color: Color) -> Node2D:
	var container = Node2D.new()
	var thickness = TILE_SIZE
	
	_add_wall_rect(container, origin + Vector2(0, -thickness), Vector2(size, thickness), color)
	_add_wall_rect(container, origin + Vector2(0, size), Vector2(size, thickness), color)
	_add_wall_rect(container, origin + Vector2(-thickness, 0), Vector2(thickness, size), color)
	_add_wall_rect(container, origin + Vector2(size, 0), Vector2(thickness, size), color)
	
	return container

func _add_wall_rect(parent: Node2D, pos: Vector2, size: Vector2, color: Color) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 4
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	wall.add_child(shape)
	
	var visual = ColorRect.new()
	visual.color = color.darkened(0.3)
	visual.size = size
	visual.z_index = -3
	wall.add_child(visual)
	
	parent.add_child(wall)

func _create_decoration(pos: Vector2, region_id: String, rng: RandomNumberGenerator) -> Node2D:
	var dec = Polygon2D.new()
	dec.position = pos
	dec.z_index = -2
	
	var size = rng.randf_range(4, 14)
	match region_id:
		"ashen_wastes":
			if rng.randf() < 0.4:
				# Dead trees - tall thin triangles
				dec.polygon = PackedVector2Array([
					Vector2(-2, 0), Vector2(-1, -size*2), Vector2(0, -size*3.5),
					Vector2(1, -size*2), Vector2(2, 0)
				])
				dec.color = Color(0.3, 0.25, 0.2)
			elif rng.randf() < 0.6:
				# Rocks - irregular hexagons
				dec.polygon = _make_circle_poly(size, 6)
				dec.color = Color(0.4, 0.35, 0.3)
			else:
				# Rubble - small squares
				dec.polygon = PackedVector2Array([
					Vector2(-size*0.5, -size*0.3), Vector2(size*0.5, -size*0.4),
					Vector2(size*0.6, size*0.3), Vector2(-size*0.4, size*0.5)
				])
				dec.color = Color(0.35, 0.3, 0.25)
		"crimson_mire":
			if rng.randf() < 0.4:
				# Mushrooms - dome cap on stem
				dec.polygon = PackedVector2Array([
					Vector2(-1, 0), Vector2(-1, -size), Vector2(-size, -size),
					Vector2(-size*0.7, -size*1.5), Vector2(0, -size*1.8),
					Vector2(size*0.7, -size*1.5), Vector2(size, -size),
					Vector2(1, -size), Vector2(1, 0)
				])
				dec.color = Color(0.5, 0.1, 0.1).lerp(Color(0.6, 0.3, 0.1), rng.randf())
			else:
				# Bog pools - elongated shapes
				dec.polygon = _make_circle_poly(size * 1.2, 8)
				dec.color = Color(0.15, 0.2, 0.08, 0.7)
		"frozen_peaks":
			if rng.randf() < 0.5:
				# Ice crystals - diamond shapes
				dec.polygon = PackedVector2Array([
					Vector2(0, -size*2.5), Vector2(size*0.6, -size),
					Vector2(size, 0), Vector2(size*0.3, size*0.5),
					Vector2(-size*0.3, size*0.5), Vector2(-size, 0),
					Vector2(-size*0.6, -size)
				])
				dec.color = Color(0.75, 0.88, 0.98, 0.8)
			else:
				# Snow mounds - smooth bumps
				dec.polygon = _make_circle_poly(size, 8)
				dec.color = Color(0.85, 0.88, 0.95)
		"shadow_citadel":
			if rng.randf() < 0.5:
				# Dark pillars - tall rectangles
				dec.polygon = PackedVector2Array([
					Vector2(-3, 0), Vector2(-4, -size*2), Vector2(-2, -size*3.5),
					Vector2(2, -size*3.5), Vector2(4, -size*2), Vector2(3, 0)
				])
				dec.color = Color(0.15, 0.05, 0.2)
			else:
				# Arcane circles on ground
				dec.polygon = _make_circle_poly(size, 12)
				dec.color = Color(0.2, 0.08, 0.3, 0.4)
	
	return dec

func _make_circle_poly(radius: float, sides: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = (float(i) / sides) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points

func _create_region_trigger(region_id: String, origin: Vector2) -> void:
	var trigger = Area2D.new()
	trigger.set_script(preload("res://scripts/world/region_trigger.gd"))
	trigger.target_region = region_id
	
	var display_names = {
		"ashen_wastes": "~ The Ashen Wastes ~",
		"crimson_mire": "~ The Crimson Mire ~",
		"frozen_peaks": "~ The Frozen Peaks ~",
		"shadow_citadel": "~ The Shadow Citadel ~",
	}
	trigger.region_display_name = display_names.get(region_id, region_id)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(REGION_SIZE * TILE_SIZE - TILE_SIZE * 4, REGION_SIZE * TILE_SIZE - TILE_SIZE * 4)
	shape.shape = rect
	trigger.add_child(shape)
	trigger.position = origin + Vector2(REGION_SIZE * TILE_SIZE / 2, REGION_SIZE * TILE_SIZE / 2)
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	
	add_child(trigger)

func _generate_paths() -> void:
	var path_color = Color(0.3, 0.28, 0.22)
	
	# Path: Ashen Wastes -> Crimson Mire (right)
	var aw_origin = Vector2(region_positions["ashen_wastes"]) * TILE_SIZE
	var path1 = ColorRect.new()
	path1.position = aw_origin + Vector2(REGION_SIZE * TILE_SIZE, REGION_SIZE * TILE_SIZE / 2 - TILE_SIZE * 2)
	path1.size = Vector2(5 * TILE_SIZE, TILE_SIZE * 4)
	path1.color = path_color
	path1.z_index = -8
	add_child(path1)
	
	# Path: Ashen Wastes -> Frozen Peaks (up)
	var path2 = ColorRect.new()
	path2.position = aw_origin + Vector2(REGION_SIZE * TILE_SIZE / 2 - TILE_SIZE * 2, -5 * TILE_SIZE)
	path2.size = Vector2(TILE_SIZE * 4, 5 * TILE_SIZE)
	path2.color = Color(0.5, 0.55, 0.6)
	path2.z_index = -8
	add_child(path2)
	
	# Path: Crimson Mire -> Shadow Citadel (up)
	var cm_origin = Vector2(region_positions["crimson_mire"]) * TILE_SIZE
	var path3 = ColorRect.new()
	path3.position = cm_origin + Vector2(REGION_SIZE * TILE_SIZE / 2 - TILE_SIZE * 2, -5 * TILE_SIZE)
	path3.size = Vector2(TILE_SIZE * 4, 5 * TILE_SIZE)
	path3.color = Color(0.15, 0.08, 0.12)
	path3.z_index = -8
	add_child(path3)
	
	# Path: Frozen Peaks -> Shadow Citadel (right)
	var fp_origin = Vector2(region_positions["frozen_peaks"]) * TILE_SIZE
	var path4 = ColorRect.new()
	path4.position = fp_origin + Vector2(REGION_SIZE * TILE_SIZE, REGION_SIZE * TILE_SIZE / 2 - TILE_SIZE * 2)
	path4.size = Vector2(5 * TILE_SIZE, TILE_SIZE * 4)
	path4.color = Color(0.15, 0.1, 0.18)
	path4.z_index = -8
	add_child(path4)

func _create_secret_area(region_id: String, pos: Vector2) -> void:
	var secret_id = region_id + "_secret"
	
	# Visual indicator (subtle glowing marker)
	var marker = Polygon2D.new()
	marker.position = pos
	marker.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	])
	marker.color = Color(0.8, 0.7, 0.2, 0.2)
	marker.z_index = -1
	add_child(marker)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.position = pos
	inner.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)
	])
	inner.color = Color(1, 0.9, 0.4, 0.4)
	inner.z_index = -1
	add_child(inner)
	
	# Pickup with rare loot
	var pickup_scene = preload("res://scenes/world/loot_pickup.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.global_position = pos
	var loot = LootTable.generate_loot("rare", GameManager.player_stats.level)
	if not loot.is_empty():
		for item in loot:
			if item.type != "gold":
				pickup.item_data = item
				break
	add_child(pickup)
	
	secret_areas.append({"id": secret_id, "position": pos, "region": region_id})
