class_name AudioPlayer
extends Node2D

@onready var move: AudioStreamPlayer = $move
@onready var castle: AudioStreamPlayer = $castle
@onready var capture: AudioStreamPlayer = $capture
@onready var move_dot: AudioStreamPlayer = $move_dot
@onready var notify: AudioStreamPlayer = $notify
@onready var promote: AudioStreamPlayer = $promote
@onready var bg: AudioStreamPlayer = $bg

enum PLAYS {MOVE, CASTLE, CAPTURE, DOT, NOTIFY, PROMOTE, BG}

# Declare the dictionary without values yet
var playes : Dictionary = {}

func _ready() -> void:
	# Populate dictionary AFTER @onready nodes have loaded!
	playes = {
		PLAYS.MOVE: move,
		PLAYS.CASTLE: castle,
		PLAYS.CAPTURE: capture,
		PLAYS.DOT: move_dot,
		PLAYS.NOTIFY: notify,
		PLAYS.PROMOTE: promote,
		PLAYS.BG: bg,
	}

	#if bg:
		#bg.play()

	GameEvents.audio_player_play.connect(play)

func play(target: PLAYS) -> void:
	assert(playes.has(target), "no target found")
	var stream_player = playes.get(target) as AudioStreamPlayer
	if stream_player != null:
		stream_player.play()
	else:
		push_error("AudioStreamPlayer for " + str(target) + " is null! Check node path in scene tree.")

#func _on_bg_finished() -> void:
	#if bg:
		#bg.play()
