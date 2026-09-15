extends Node

const SOUND_PATH := "res://game/audio/sfx/%s.wav"
const SOUNDS := [
	&"pop", &"swap", &"invalid", &"special", &"blast", &"color", &"box", &"paw",
	&"sack", &"coin", &"star", &"win", &"lose", &"meow", &"click",
]
const VOICES := 8
const HISTORY := 16

var enabled := true
# Most recent sounds, newest last; lets tests check what a scene asked to play.
var history: Array[StringName] = []

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for sound in SOUNDS:
		var path := SOUND_PATH % sound
		if ResourceLoader.exists(path):
			_streams[sound] = load(path)
	for n in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not enabled or not _streams.has(sound):
		return
	history.append(sound)
	if history.size() > HISTORY:
		history.pop_front()
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = _streams[sound]
	player.pitch_scale = clampf(pitch, 0.25, 4.0)
	player.volume_db = volume_db
	player.play()


# Each cascade step plays a semitone higher, capped at one octave.
static func chain_pitch(chain: int) -> float:
	return pow(2.0, clampi(chain - 1, 0, 12) / 12.0)
