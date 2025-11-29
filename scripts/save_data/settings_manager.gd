# res://scripts/save_data/settings_manager.gd
extends Node

## Singleton for managing game settings
## Settings are saved locally and can be synced with external API

signal settings_changed(setting_name: String, value)
signal settings_loaded()
signal settings_saved()

const SAVE_FILE_PATH := "user://settings.cfg"

# Video Settings
var fullscreen: bool = false
var vsync_enabled: bool = true
var resolution: Vector2i = Vector2i(1920, 1080)
var window_mode: int = Window.MODE_WINDOWED  # 0=Windowed, 3=Fullscreen, 4=Exclusive Fullscreen

# Audio Settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var ui_volume: float = 1.0

# Gameplay Settings
var mouse_sensitivity: float = 0.5
var invert_y_axis: bool = false
var show_fps: bool = false
var camera_shake: bool = true

# Graphics Settings
var shadow_quality: int = 2  # 0=Low, 1=Medium, 2=High, 3=Ultra
var texture_quality: int = 2
var anti_aliasing: bool = true
var bloom_enabled: bool = true
var ambient_occlusion: bool = true

# Available resolutions
var available_resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready() -> void:
	load_settings()
	apply_settings()

## Load settings from file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	
	if err != OK:
		print("No settings file found, using defaults")
		save_settings()
		settings_loaded.emit()
		return
	
	# Video Settings
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	vsync_enabled = config.get_value("video", "vsync_enabled", vsync_enabled)
	resolution = config.get_value("video", "resolution", resolution)
	window_mode = config.get_value("video", "window_mode", window_mode)
	
	# Audio Settings
	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	ui_volume = config.get_value("audio", "ui_volume", ui_volume)
	
	# Gameplay Settings
	mouse_sensitivity = config.get_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
	invert_y_axis = config.get_value("gameplay", "invert_y_axis", invert_y_axis)
	show_fps = config.get_value("gameplay", "show_fps", show_fps)
	camera_shake = config.get_value("gameplay", "camera_shake", camera_shake)
	
	# Graphics Settings
	shadow_quality = config.get_value("graphics", "shadow_quality", shadow_quality)
	texture_quality = config.get_value("graphics", "texture_quality", texture_quality)
	anti_aliasing = config.get_value("graphics", "anti_aliasing", anti_aliasing)
	bloom_enabled = config.get_value("graphics", "bloom_enabled", bloom_enabled)
	ambient_occlusion = config.get_value("graphics", "ambient_occlusion", ambient_occlusion)
	
	settings_loaded.emit()
	print("Settings loaded successfully")

## Save settings to file
func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Video Settings
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync_enabled", vsync_enabled)
	config.set_value("video", "resolution", resolution)
	config.set_value("video", "window_mode", window_mode)
	
	# Audio Settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	
	# Gameplay Settings
	config.set_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "invert_y_axis", invert_y_axis)
	config.set_value("gameplay", "show_fps", show_fps)
	config.set_value("gameplay", "camera_shake", camera_shake)
	
	# Graphics Settings
	config.set_value("graphics", "shadow_quality", shadow_quality)
	config.set_value("graphics", "texture_quality", texture_quality)
	config.set_value("graphics", "anti_aliasing", anti_aliasing)
	config.set_value("graphics", "bloom_enabled", bloom_enabled)
	config.set_value("graphics", "ambient_occlusion", ambient_occlusion)
	
	var err = config.save(SAVE_FILE_PATH)
	if err == OK:
		settings_saved.emit()
		print("Settings saved successfully")
	else:
		push_error("Failed to save settings: " + str(err))

## Apply all settings to the game
func apply_settings() -> void:
	apply_video_settings()
	apply_audio_settings()
	apply_graphics_settings()

## Apply video settings
func apply_video_settings() -> void:
	var window = get_window()
	
	# Window mode
	window.mode = window_mode
	
	# Resolution (only if windowed)
	if window_mode == Window.MODE_WINDOWED:
		window.size = resolution
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		window.position = (screen_size - resolution) / 2
	
	# VSync
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

## Apply audio settings
func apply_audio_settings() -> void:
	# Master volume
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume)
	)
	
	# Music volume
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	
	# SFX volume
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	
	# UI volume
	var ui_bus = AudioServer.get_bus_index("UI")
	if ui_bus != -1:
		AudioServer.set_bus_volume_db(ui_bus, linear_to_db(ui_volume))

## Apply graphics settings
func apply_graphics_settings() -> void:
	# Note: Many graphics settings depend on your specific rendering setup
	# These are examples and may need adjustment based on your project
	
	var viewport = get_viewport()
	
	# Anti-aliasing
	if anti_aliasing:
		viewport.msaa_3d = Viewport.MSAA_4X
	else:
		viewport.msaa_3d = Viewport.MSAA_DISABLED
	
	# Additional graphics settings would be applied here based on your engine configuration

## Reset all settings to defaults
func reset_to_defaults() -> void:
	fullscreen = false
	vsync_enabled = true
	resolution = Vector2i(1920, 1080)
	window_mode = Window.MODE_WINDOWED
	
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 0.8
	ui_volume = 1.0
	
	mouse_sensitivity = 0.5
	invert_y_axis = false
	show_fps = false
	camera_shake = true
	
	shadow_quality = 2
	texture_quality = 2
	anti_aliasing = true
	bloom_enabled = true
	ambient_occlusion = true
	
	apply_settings()
	save_settings()

## Set individual setting and optionally save
func set_setting(setting_name: String, value, save_immediately: bool = false) -> void:
	match setting_name:
		"fullscreen": fullscreen = value
		"vsync_enabled": vsync_enabled = value
		"resolution": resolution = value
		"window_mode": window_mode = value
		"master_volume": master_volume = value
		"music_volume": music_volume = value
		"sfx_volume": sfx_volume = value
		"ui_volume": ui_volume = value
		"mouse_sensitivity": mouse_sensitivity = value
		"invert_y_axis": invert_y_axis = value
		"show_fps": show_fps = value
		"camera_shake": camera_shake = value
		"shadow_quality": shadow_quality = value
		"texture_quality": texture_quality = value
		"anti_aliasing": anti_aliasing = value
		"bloom_enabled": bloom_enabled = value
		"ambient_occlusion": ambient_occlusion = value
		_:
			push_warning("Unknown setting: " + setting_name)
			return
	
	settings_changed.emit(setting_name, value)
	
	if save_immediately:
		save_settings()

## Get setting value by name
func get_setting(setting_name: String):
	match setting_name:
		"fullscreen": return fullscreen
		"vsync_enabled": return vsync_enabled
		"resolution": return resolution
		"window_mode": return window_mode
		"master_volume": return master_volume
		"music_volume": return music_volume
		"sfx_volume": return sfx_volume
		"ui_volume": return ui_volume
		"mouse_sensitivity": return mouse_sensitivity
		"invert_y_axis": return invert_y_axis
		"show_fps": return show_fps
		"camera_shake": return camera_shake
		"shadow_quality": return shadow_quality
		"texture_quality": return texture_quality
		"anti_aliasing": return anti_aliasing
		"bloom_enabled": return bloom_enabled
		"ambient_occlusion": return ambient_occlusion
		_:
			push_warning("Unknown setting: " + setting_name)
			return null
