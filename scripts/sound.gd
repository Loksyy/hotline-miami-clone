extends Node
const S = preload("res://scripts/game_settings.gd")

var sounds: Dictionary = {}
var muted := not S.SOUND_ENABLED
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0

func _ready() -> void:
	for kind in ["shot", "hit", "swing", "pickup", "door", "death"]:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var data := PackedByteArray()
		var duration := 0.24 if kind == "death" else 0.12
		var count := int(22050 * duration)
		data.resize(count * 2)
		for i in count:
			var t := float(i) / 22050
			var envelope := pow(1.0 - float(i) / count, 3)
			var frequency := 120.0
			if kind == "pickup": frequency = 650 + t * 3000
			if kind == "swing": frequency = 230
			if kind == "death": frequency = 80
			var noise := randf_range(-1, 1) * (0.75 if kind in ["shot", "hit", "door"] else 0.15)
			var sample := (sin(TAU * frequency * t) * 0.5 + noise) * envelope * 0.35
			data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
		stream.data = data
		sounds[kind] = stream

func play(kind: String) -> void:
	if muted or not sounds.has(kind): return
	# Reuse a bounded voice pool instead of allocating/freeing nodes per shot.
	if voices.is_empty():
		for i in S.MAX_AUDIO_VOICES:
			var voice := AudioStreamPlayer.new()
			add_child(voice)
			voices.append(voice)
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = sounds[kind]
	voice.volume_db = S.SOUND_VOLUME_DB
	voice.play()
