extends Node2D
## WorldMap - Generates the open world with multiple biomes
## Uses procedural tile placement for a seamless feel

const TILE_SIZE = 32
const REGION_SIZE = 50  # tiles per region side

# Biome data
var biome_colors: Dictionary = {
	"ashen_wastes": Color(0.35, 0.30, 0.25),
	"crimson_mire": Color(0.25, 0.15, 0.10),
	"frozen_peaks": Color(0.7, 0.75, 0.85),
	"shadow_citadel": Color(0.12, 0.08, 0.15),
}

var biome_wall_colors: Dictionary = {
	"ashen_wastes": Color(0.25, 0.22, 0.18),
	"crimson_mire": Color(0.18, 0.08, 0.05),
	"frozen_peaks": Color(0.5, 0.55, 0.7),
	"shadow_citadel": Color(0.08, 0.04, 0.1),
}

# Region positions (in tiles, relative to world origin)
var region_positions: Dictionary = {
	"ashen_wastes": Vector2i(0, 0),
	"crimson_mire": Vector2i(REGION_SIZE + 5, 0),
	"frozen_peaks": Vector2i(0, -(REGION_SIZE + 5)),
	"shadow_citadel": Vector2i(REGION_SIZE + 5, -(REGION_SIZE + 5)),
}

# Wall positions (obstacles within regions) - stored as tile coords
var walls: Array[Rect2i] = []
var secret_areas: Array[Dictionary] = []

func _ready() -> void:
	_generate_world()

func _generate_world() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Generate each region
	for region_id in region_positions:
		var origin = region_positions[region_id] * TILE_SIZE
		_generate_region(region_id, origin)
	
	# Generate paths between regions
	_generate_paths()

func _generate_region(region_id: String, origin: Vector2) -> void:
	var ground_color = biome_colors[region_id]
	var wall_color = biome_wall_colors[region_id]
	
	# Ground
	var ground = ColorRect.new()
	ground.color = ground_color
	ground.position = origin
	ground.size = Vector2(REGION_SIZE * TILE_SIZE, REGION_SIZE * TILE_SIZE)
	ground.z_index = -10
	add_child(ground)
	
	# Region border decoration
	var border = _create_border(origin, REGION_SIZE * TILE_SIZE, wall_color)
	add_child(border)
	
	# Walls (obstacles)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(region_id)
	var num_walls = rng.randi_range(8, 15)
	for _i in range(num_walls):
		var wx = rng.randi_range(3, REGION_SIZE - 6)
		var wy = rng.randi_range(3, REGION_SIZE - 6)
		var ww = rng.randi_range(1, 4)
		var wh = rng.randi_range(1, 4)
		_create_wall(origin + Vector2(wx * TILE_SIZE, wy * TILE_SIZE), Vector2(ww * TILE_SIZE, wh * TILE_SIZE), wall_color)
	
	# Decorations (trees, rocks, etc)
	var num_decorations = rng.randi_range(15, 30)
	for _i in range(num_decorations):
		var dx = rng.randf_range(2, REGION_SIZE - 2) * TILE_SIZE
		var dy = rng.randf_range(2, REGION_SIZE - 2) * TILE_SIZE
		var dec = _create_decoration(origin + Vector2(dx, dy), region_id, rng)
		add_child(dec)
	
	# Region trigger (transition area)
	_create_region_trigger(region_id, origin)
	
	# Secret areas
	if rng.randf() < 0.7:
		var sx = rng.randi_range(REGION_SIZE - 10, REGION_SIZE - 3) * TILE_SIZE
		var sy = rng.randi_range(REGION_SIZE - 10, REGION_SIZE - 3) * TILE_SIZE
		_create_secret_area(region_id, origin + Vector2(sx, sy))

func _create_wall(pos: Vector2, size: Vector2, color: Color) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 4  # Walls layer
	
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
	
	add_child(wall)

func _create_border(origin: Vector2, size: float, color: Color) -> Node2D:
	var container = Node2D.new()
	var thickness = TILE_SIZE
	
	# Top
	_add_wall_rect(container, origin + Vector2(0, -thickness), Vector2(size, thickness), color)
	# Bottom
	_add_wall_rect(container, origin + Vector2(0, size), Vector2(size, thickness), color)
	# Left
	_add_wall_rect(container, origin + Vector2(-thickness, 0), Vector2(thickness, size), color)
	# Right
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
	
	var size = rng.randf_range(4, 12)
	match region_id:
		"ashen_wastes":
			# Dead trees and rocks
			if rng.randf() < 0.5:
				dec.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -size*3), Vector2(2, 0)])
				dec.color = Color(0.3, 0.25, 0.2)
			else:
				dec.polygon = _make_circle_poly(size, 6)
				dec.color = Color(0.4, 0.35, 0.3)
		"crimson_mire":
			# Mushrooms and bog plants
			dec.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(-size*0.5, -size), Vector2(size*0.5, -size), Vector2(size, 0)])
			dec.color = Color(0.5, 0.1, 0.1).lerp(Color(0.2, 0.5, 0.1), rng.randf())
		"frozen_peaks":
			# Ice crystals and snow mounds
			dec.polygon = PackedVector2Array([Vector2(0, -size*2), Vector2(size, 0), Vector2(0, size*0.5), Vector2(-size, 0)])
			dec.color = Color(0.75, 0.85, 0.95)
		"shadow_citadel":
			# Dark pillars
			dec.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(-3, -size*3), Vector2(3, -size*3), Vector2(3, 0)])
			dec.color = Color(0.15, 0.05, 0.2)
	
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
	trigger.collision_mask = 1  # Player layer
	
	add_child(trigger)

func _generate_paths() -> void:
	# Create walkable paths between regions (gaps in borders)
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
	
	# Visual indicator (subtle)
	var marker = Polygon2D.new()
	marker.position = pos
	marker.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	marker.color = Color(0.8, 0.7, 0.2, 0.3)
	marker.z_index = -1
	add_child(marker)
	
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
