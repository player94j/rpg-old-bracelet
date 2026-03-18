extends Node
## AudioManager - Full audio system with procedural sound generation
## Generates sound effects and music using AudioStreamGenerator in Godot 4.x

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0

# Audio bus indices
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer = null
var current_music_track: String = ""
var music_playing: bool = false

# SFX cooldown to prevent sound spam
var sfx_cooldowns: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Create SFX player pool (8 concurrent sounds)
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

func _process(delta: float) -> void:
	# Update cooldowns
	var to_remove: Array[String] = []
	for key in sfx_cooldowns:
		sfx_cooldowns[key] -= delta
		if sfx_cooldowns[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		sfx_cooldowns.erase(key)

func play_sfx(sfx_name: String) -> void:
	# Check cooldown
	if sfx_cooldowns.has(sfx_name):
		return
	sfx_cooldowns[sfx_name] = 0.05  # 50ms cooldown between same sounds
	
	var sample = _generate_sfx(sfx_name)
	if sample == null:
		return
	
	# Find available player
	for player in sfx_players:
		if not player.playing:
			player.stream = sample
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return
	# All busy - steal oldest
	sfx_players[0].stream = sample
	sfx_players[0].volume_db = linear_to_db(sfx_volume * master_volume)
	sfx_players[0].play()

func play_music(track: String) -> void:
	if track == current_music_track and music_playing:
		return
	current_music_track = track
	var sample = _generate_music(track)
	if sample == null:
		return
	music_player.stream = sample
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.play()
	music_playing = true

func stop_music() -> void:
	if music_player:
		music_player.stop()
	music_playing = false
	current_music_track = ""

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_update_volumes()

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func _update_volumes() -> void:
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

# === PROCEDURAL SFX GENERATION ===
func _generate_sfx(sfx_name: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var data: PackedByteArray
	
	match sfx_name:
		"sword_swing":
			data = _gen_swoosh(sample_rate, 0.15, 800, 200)
		"sword_hit":
			data = _gen_impact(sample_rate, 0.12, 300, 120)
		"heavy_swing":
			data = _gen_swoosh(sample_rate, 0.25, 500, 100)
		"heavy_hit":
			data = _gen_impact(sample_rate, 0.2, 200, 80)
		"player_hit":
			data = _gen_hit_flesh(sample_rate, 0.15)
		"player_death":
			data = _gen_death_sound(sample_rate, 0.6)
		"dodge":
			data = _gen_whoosh(sample_rate, 0.2)
		"spell_cast":
			data = _gen_magic_cast(sample_rate, 0.3)
		"spell_hit":
			data = _gen_magic_impact(sample_rate, 0.2)
		"enemy_alert":
			data = _gen_alert(sample_rate, 0.15)
		"enemy_attack":
			data = _gen_swoosh(sample_rate, 0.12, 600, 150)
		"enemy_hit":
			data = _gen_impact(sample_rate, 0.1, 250, 100)
		"enemy_death":
			data = _gen_enemy_death(sample_rate, 0.4)
		"boss_roar":
			data = _gen_boss_roar(sample_rate, 0.8)
		"boss_slam":
			data = _gen_boss_slam(sample_rate, 0.5)
		"boss_phase":
			data = _gen_phase_change(sample_rate, 1.0)
		"boss_death":
			data = _gen_boss_death(sample_rate, 1.2)
		"pickup":
			data = _gen_pickup(sample_rate, 0.2)
		"level_up":
			data = _gen_level_up(sample_rate, 0.8)
		"quest_complete":
			data = _gen_quest_complete(sample_rate, 0.6)
		"menu_select":
			data = _gen_menu_click(sample_rate, 0.08)
		"menu_hover":
			data = _gen_menu_hover(sample_rate, 0.05)
		"open_menu":
			data = _gen_open_menu(sample_rate, 0.15)
		"close_menu":
			data = _gen_close_menu(sample_rate, 0.1)
		"heal":
			data = _gen_heal(sample_rate, 0.4)
		"buy_item":
			data = _gen_coins(sample_rate, 0.3)
		"equip":
			data = _gen_equip(sample_rate, 0.15)
		"npc_talk":
			data = _gen_npc_talk(sample_rate, 0.12)
		"region_enter":
			data = _gen_region_enter(sample_rate, 0.6)
		"save_game":
			data = _gen_save_sound(sample_rate, 0.3)
		"combo":
			data = _gen_combo(sample_rate, 0.2)
		"tutorial_popup":
			data = _gen_tutorial_sound(sample_rate, 0.25)
		_:
			return null
	
	if data.is_empty():
		return null
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

# === SOUND GENERATION PRIMITIVES ===

func _gen_swoosh(rate: int, dur: float, freq_start: float, freq_end: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(freq_start, freq_end, p)
		var envelope = sin(p * PI) * (1.0 - p * 0.5)
		var noise = (randf() - 0.5) * 0.6
		var tone = sin(t * freq * TAU) * 0.3
		var val = (noise + tone) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_impact(rate: int, dur: float, freq: float, decay_freq: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 8.0)
		var f = lerpf(freq, decay_freq, p)
		var tone = sin(t * f * TAU) * 0.5
		var noise = (randf() - 0.5) * 0.4 * envelope
		var val = (tone + noise) * envelope * 0.6
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_hit_flesh(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 12.0)
		var tone = sin(t * 180 * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.8 * exp(-p * 6.0)
		var low = sin(t * 80 * TAU) * 0.4
		var val = (tone + noise + low) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_death_sound(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(300, 80, p)
		var envelope = (1.0 - p) * sin(p * PI * 0.5)
		var tone = sin(t * freq * TAU) * 0.4
		var noise = (randf() - 0.5) * 0.3
		var val = (tone + noise) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_whoosh(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var noise = (randf() - 0.5) * envelope * 0.7
		data[i] = int(clampf(noise * 127 + 128, 0, 255))
	return data

func _gen_magic_cast(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI) * (1.0 - p * 0.3)
		var freq = lerpf(400, 1200, p * p)
		var tone1 = sin(t * freq * TAU) * 0.3
		var tone2 = sin(t * freq * 1.5 * TAU) * 0.15
		var shimmer = sin(t * 3000 * TAU) * 0.1 * sin(p * PI)
		var val = (tone1 + tone2 + shimmer) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_magic_impact(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 6.0)
		var tone = sin(t * 600 * TAU) * 0.3
		var tone2 = sin(t * 900 * TAU) * 0.2
		var noise = (randf() - 0.5) * 0.3
		var val = (tone + tone2 + noise) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_alert(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var freq = lerpf(200, 500, p)
		var val = sin(t * freq * TAU) * envelope * 0.25
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_enemy_death(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(400, 60, p)
		var envelope = (1.0 - p)
		var tone = sin(t * freq * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.4 * (1.0 - p)
		var val = (tone + noise) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_boss_roar(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI * 0.7) * (1.0 - p * 0.3)
		var freq = lerpf(100, 60, p) + sin(t * 5) * 20
		var tone = sin(t * freq * TAU) * 0.4
		var harmonic = sin(t * freq * 2 * TAU) * 0.2
		var noise = (randf() - 0.5) * 0.5 * envelope
		var val = (tone + harmonic + noise) * envelope * 0.6
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_boss_slam(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 4.0)
		var freq = lerpf(200, 40, p)
		var tone = sin(t * freq * TAU) * 0.5
		var noise = (randf() - 0.5) * 0.6 * exp(-p * 3.0)
		var sub = sin(t * 30 * TAU) * 0.3
		var val = (tone + noise + sub) * envelope * 0.6
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_phase_change(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var freq = lerpf(200, 800, p)
		var tone = sin(t * freq * TAU) * 0.3
		var tone2 = sin(t * freq * 1.5 * TAU) * 0.15
		var pulse = sin(t * 8 * TAU) * 0.2
		var val = (tone + tone2 + pulse) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_boss_death(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = (1.0 - p * 0.7) * sin(minf(p * 3, 1) * PI * 0.5)
		var freq = lerpf(300, 40, p * p)
		var tone = sin(t * freq * TAU) * 0.3
		var harmonic = sin(t * freq * 3 * TAU) * 0.1 * (1.0 - p)
		var noise = (randf() - 0.5) * 0.3 * (1.0 - p)
		var shimmer = sin(t * 2000 * TAU) * 0.05 * p
		var val = (tone + harmonic + noise + shimmer) * envelope * 0.5
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_pickup(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = (1.0 - p)
		var freq = 800 if p < 0.5 else 1000
		var val = sin(t * freq * TAU) * envelope * 0.3
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_level_up(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	var notes = [523.0, 659.0, 784.0, 1047.0]  # C5, E5, G5, C6
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var note_idx = mini(int(p * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var envelope = sin(p * PI) * 0.7 + 0.3
		var tone = sin(t * freq * TAU) * 0.3
		var tone2 = sin(t * freq * 2 * TAU) * 0.1
		var val = (tone + tone2) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_quest_complete(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	var notes = [440.0, 554.0, 659.0, 880.0]
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var note_idx = mini(int(p * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var envelope = sin(p * PI)
		var val = sin(t * freq * TAU) * envelope * 0.3
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_menu_click(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 20.0)
		var val = sin(t * 1000 * TAU) * envelope * 0.3
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_menu_hover(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 30.0)
		var val = sin(t * 1500 * TAU) * envelope * 0.15
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_open_menu(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(400, 800, p)
		var envelope = sin(p * PI)
		var val = sin(t * freq * TAU) * envelope * 0.2
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_close_menu(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(800, 300, p)
		var envelope = (1.0 - p)
		var val = sin(t * freq * TAU) * envelope * 0.2
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_heal(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = lerpf(600, 900, p)
		var envelope = sin(p * PI)
		var tone = sin(t * freq * TAU) * 0.25
		var shimmer = sin(t * freq * 3 * TAU) * 0.08
		var val = (tone + shimmer) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_coins(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 5.0)
		var freq = 2000 + sin(t * 20) * 500
		var val = sin(t * freq * TAU) * envelope * 0.2
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_equip(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = exp(-p * 10.0)
		var tone = sin(t * 500 * TAU) * 0.2
		var noise = (randf() - 0.5) * 0.3 * envelope
		var val = (tone + noise) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_npc_talk(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var freq = 300 + sin(t * 8) * 50
		var val = sin(t * freq * TAU) * envelope * 0.15
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_region_enter(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var freq = lerpf(300, 500, p)
		var tone = sin(t * freq * TAU) * 0.2
		var tone2 = sin(t * freq * 1.5 * TAU) * 0.1
		var val = (tone + tone2) * envelope * 0.4
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_save_sound(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	var notes = [523.0, 659.0, 784.0]
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var note_idx = mini(int(p * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var envelope = sin(p * PI)
		var val = sin(t * freq * TAU) * envelope * 0.25
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_combo(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var freq = 600 + p * 400
		var envelope = sin(p * PI)
		var val = sin(t * freq * TAU) * envelope * 0.3
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

func _gen_tutorial_sound(rate: int, dur: float) -> PackedByteArray:
	var samples = int(rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / rate
		var p = float(i) / samples
		var envelope = sin(p * PI)
		var freq = 700
		var tone = sin(t * freq * TAU) * 0.2
		var tone2 = sin(t * freq * 1.25 * TAU) * 0.1
		var val = (tone + tone2) * envelope * 0.3
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	return data

# === PROCEDURAL MUSIC GENERATION ===
func _generate_music(track: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var dur: float = 16.0  # 16 second loop
	var samples = int(sample_rate * dur)
	var data = PackedByteArray()
	data.resize(samples)
	
	var notes: Array[float]
	var bass_notes: Array[float]
	var tempo: float  # beats per second
	
	match track:
		"main_menu":
			notes = [220.0, 261.0, 330.0, 261.0, 220.0, 196.0, 220.0, 261.0]
			bass_notes = [110.0, 130.0, 110.0, 98.0]
			tempo = 1.5
		"ashen_wastes":
			notes = [196.0, 220.0, 261.0, 247.0, 220.0, 196.0, 175.0, 196.0]
			bass_notes = [98.0, 110.0, 130.0, 98.0]
			tempo = 1.2
		"crimson_mire":
			notes = [185.0, 220.0, 207.0, 247.0, 220.0, 185.0, 175.0, 185.0]
			bass_notes = [92.0, 110.0, 92.0, 87.0]
			tempo = 1.0
		"frozen_peaks":
			notes = [330.0, 392.0, 440.0, 392.0, 330.0, 294.0, 330.0, 392.0]
			bass_notes = [165.0, 196.0, 220.0, 165.0]
			tempo = 0.8
		"shadow_citadel":
			notes = [147.0, 175.0, 165.0, 196.0, 175.0, 147.0, 131.0, 147.0]
			bass_notes = [73.0, 87.0, 73.0, 65.0]
			tempo = 0.9
		"boss_fight":
			notes = [220.0, 262.0, 294.0, 330.0, 294.0, 262.0, 220.0, 196.0]
			bass_notes = [110.0, 131.0, 147.0, 110.0]
			tempo = 2.0
		_:
			notes = [220.0, 261.0, 330.0, 261.0]
			bass_notes = [110.0, 130.0]
			tempo = 1.0
	
	var beat_samples = int(sample_rate / tempo)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var beat = int(i / beat_samples)
		var beat_progress = fmod(float(i), beat_samples) / beat_samples
		
		# Melody
		var note_idx = beat % notes.size()
		var freq = notes[note_idx]
		var melody_env = sin(beat_progress * PI) * 0.5 + 0.5
		melody_env *= (1.0 - beat_progress * 0.3)
		var melody = sin(t * freq * TAU) * 0.12 * melody_env
		
		# Bass drone
		var bass_idx = (beat / 2) % bass_notes.size()
		var bass_freq = bass_notes[bass_idx]
		var bass = sin(t * bass_freq * TAU) * 0.1
		
		# Pad / atmosphere
		var pad_freq = freq * 0.5
		var pad = sin(t * pad_freq * TAU) * 0.04
		pad += sin(t * pad_freq * 1.5 * TAU) * 0.02
		
		# Subtle percussion on every beat
		var perc = 0.0
		if beat_progress < 0.05:
			perc = (randf() - 0.5) * 0.08 * (1.0 - beat_progress * 20)
		
		# Global envelope for smooth looping
		var global_p = float(i) / samples
		var loop_env = 1.0
		if global_p < 0.02:
			loop_env = global_p / 0.02
		elif global_p > 0.98:
			loop_env = (1.0 - global_p) / 0.02
		
		var val = (melody + bass + pad + perc) * loop_env
		data[i] = int(clampf(val * 127 + 128, 0, 255))
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	stream.data = data
	return stream
