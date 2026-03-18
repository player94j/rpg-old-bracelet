extends Node
## AudioManager - Placeholder audio manager for sound effects and music

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0

func play_sfx(_name: String) -> void:
	pass  # Placeholder - would load and play sound effects

func play_music(_track: String) -> void:
	pass  # Placeholder - would handle background music

func stop_music() -> void:
	pass

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
