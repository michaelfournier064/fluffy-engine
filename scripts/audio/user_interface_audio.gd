# res://scripts/audio/user_interface_audio.gd
extends Node

const CLICK_STREAM: AudioStream = preload("res://assets/sounds/click_sound.mp3")
const HOVER_STREAM: AudioStream = CLICK_STREAM  # same sound for hover

@export var bus_name := "UI"

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer

func _ready() -> void:
	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = HOVER_STREAM
	_hover_player.bus = bus_name
	add_child(_hover_player)

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = CLICK_STREAM
	_click_player.bus = bus_name
	add_child(_click_player)

func _stop_all() -> void:
	if _hover_player: _hover_player.stop()
	if _click_player: _click_player.stop()

func play_hover() -> void:
	_stop_all()
	_hover_player.play()

func play_click() -> void:
	_stop_all()
	_click_player.play()

func set_volume_db(v: float) -> void:
	if _hover_player: _hover_player.volume_db = v
	if _click_player: _click_player.volume_db = v
