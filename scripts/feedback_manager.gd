class_name RopeFeedbackManager
extends Node

const SAMPLE_RATE := 22050

var sound_enabled := true
var vibration_enabled := true
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "FeedbackAudio"
	add_child(_player)


func play_success(combo: int) -> void:
	if sound_enabled:
		var pitch_step := mini(combo, 12) * 18.0
		_play_tone(620.0 + pitch_step, 0.075, 0.28)
	if vibration_enabled:
		Input.vibrate_handheld(18, 0.35)


func play_failure() -> void:
	if sound_enabled:
		_play_tone(145.0, 0.22, 0.38)
	if vibration_enabled:
		Input.vibrate_handheld(110, 0.85)


func play_start() -> void:
	if sound_enabled:
		_play_tone(440.0, 0.065, 0.22)


func _play_tone(frequency: float, duration: float, volume: float) -> void:
	if _player == null:
		return
	var sample_count := maxi(1, int(SAMPLE_RATE * duration))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in range(sample_count):
		var progress := float(i) / float(sample_count)
		var envelope := minf(progress * 12.0, 1.0) * (1.0 - progress)
		var wave := sin(TAU * frequency * float(i) / float(SAMPLE_RATE))
		var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	_player.stream = stream
	_player.play()
