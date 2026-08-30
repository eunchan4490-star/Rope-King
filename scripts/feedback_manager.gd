class_name RopeFeedbackManager
extends Node

const SAMPLE_RATE := 22050
const BGM_VOLUME_DB := -10.0

var sound_enabled := true:
	set(value):
		sound_enabled = value
		_update_bgm_mute()
var vibration_enabled := true
var _player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
# Tracks whether the tab/app is currently backgrounded, independent of the
# sound_enabled mute toggle — BGM should pause for either reason and only
# resume once neither is true. Without this, switching tabs or minimizing
# (not fully closing) the browser left the BGM playing indefinitely, since
# nothing else in the engine pauses audio just because the tab lost focus.
var _tab_hidden := false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "FeedbackAudio"
	add_child(_player)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmAudio"
	_bgm_player.volume_db = BGM_VOLUME_DB
	add_child(_bgm_player)


func _notification(what: int) -> void:
	# FOCUS_OUT/IN cover browser tab switches on Web; PAUSED/RESUMED cover
	# Android/iOS backgrounding (e.g. the home button) for the APK build.
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_tab_hidden = true
			_update_bgm_mute()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_tab_hidden = false
			_update_bgm_mute()


func play_bgm(path: String) -> void:
	if _bgm_player == null or not ResourceLoader.exists(path):
		return
	var stream := load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_bgm_player.stream = stream
	_update_bgm_mute()
	_bgm_player.play()


func _update_bgm_mute() -> void:
	if _bgm_player != null:
		_bgm_player.stream_paused = not sound_enabled or _tab_hidden


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


func play_countdown_tick() -> void:
	if vibration_enabled:
		Input.vibrate_handheld(25, 0.4)


func play_countdown_go() -> void:
	if vibration_enabled:
		Input.vibrate_handheld(60, 0.7)


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
