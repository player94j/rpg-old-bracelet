extends Node2D
## AoE Effect - Visual effect for area-of-effect attacks

var radius: float = 60.0
var lifetime: float = 0.8
var color: Color = Color(1, 0.3, 0.1, 0.6)

func setup(r: float, c: Color = Color(1, 0.3, 0.1, 0.6)) -> void:
	radius = r
	color = c

func _ready() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, lifetime)
	tw.tween_callback(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)

func _process(_delta: float) -> void:
	queue_redraw()
