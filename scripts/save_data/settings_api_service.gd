# res://scripts/save_data/settings_api_service.gd
extends Node

## Service for syncing settings with external API (Go backend)
## This handles communication between the game and your Go microservice

# Configure these based on your Go backend
const API_BASE_URL := "http://localhost:8080/api"  # Change to your actual API URL
const SETTINGS_ENDPOINT := "/settings"
const TIMEOUT := 10.0

signal sync_completed(success: bool)
signal sync_failed(error: String)

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = TIMEOUT
	http_request.request_completed.connect(_on_request_completed)

## Save settings to external API
func save_settings_to_api(user_id: String = "") -> void:
	var settings_data = _get_settings_dict()
	
	var json = JSON.stringify(settings_data)
	var headers = ["Content-Type: application/json"]
	
	var url = API_BASE_URL + SETTINGS_ENDPOINT
	if user_id != "":
		url += "?user_id=" + user_id
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	
	if error != OK:
		push_error("Failed to send settings to API: " + str(error))
		sync_failed.emit("Network request failed")

## Load settings from external API
func load_settings_from_api(user_id: String = "") -> void:
	var headers = ["Content-Type: application/json"]
	
	var url = API_BASE_URL + SETTINGS_ENDPOINT
	if user_id != "":
		url += "?user_id=" + user_id
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("Failed to load settings from API: " + str(error))
		sync_failed.emit("Network request failed")

## Convert current settings to dictionary for API
func _get_settings_dict() -> Dictionary:
	return {
		"video": {
			"fullscreen": SettingsManager.fullscreen,
			"vsync_enabled": SettingsManager.vsync_enabled,
			"resolution": {
				"width": SettingsManager.resolution.x,
				"height": SettingsManager.resolution.y
			},
			"window_mode": SettingsManager.window_mode
		},
		"audio": {
			"master_volume": SettingsManager.master_volume,
			"music_volume": SettingsManager.music_volume,
			"sfx_volume": SettingsManager.sfx_volume,
			"ui_volume": SettingsManager.ui_volume
		},
		"gameplay": {
			"mouse_sensitivity": SettingsManager.mouse_sensitivity,
			"invert_y_axis": SettingsManager.invert_y_axis,
			"show_fps": SettingsManager.show_fps,
			"camera_shake": SettingsManager.camera_shake
		},
		"graphics": {
			"shadow_quality": SettingsManager.shadow_quality,
			"texture_quality": SettingsManager.texture_quality,
			"anti_aliasing": SettingsManager.anti_aliasing,
			"bloom_enabled": SettingsManager.bloom_enabled,
			"ambient_occlusion": SettingsManager.ambient_occlusion
		},
		"timestamp": Time.get_unix_time_from_system()
	}

## Apply settings from API response
func _apply_settings_from_dict(data: Dictionary) -> void:
	if data.has("video"):
		var video = data.video
		SettingsManager.fullscreen = video.get("fullscreen", SettingsManager.fullscreen)
		SettingsManager.vsync_enabled = video.get("vsync_enabled", SettingsManager.vsync_enabled)
		SettingsManager.window_mode = video.get("window_mode", SettingsManager.window_mode)
		
		if video.has("resolution"):
			var res = video.resolution
			SettingsManager.resolution = Vector2i(
				res.get("width", 1920),
				res.get("height", 1080)
			)
	
	if data.has("audio"):
		var audio = data.audio
		SettingsManager.master_volume = audio.get("master_volume", SettingsManager.master_volume)
		SettingsManager.music_volume = audio.get("music_volume", SettingsManager.music_volume)
		SettingsManager.sfx_volume = audio.get("sfx_volume", SettingsManager.sfx_volume)
		SettingsManager.ui_volume = audio.get("ui_volume", SettingsManager.ui_volume)
	
	if data.has("gameplay"):
		var gameplay = data.gameplay
		SettingsManager.mouse_sensitivity = gameplay.get("mouse_sensitivity", SettingsManager.mouse_sensitivity)
		SettingsManager.invert_y_axis = gameplay.get("invert_y_axis", SettingsManager.invert_y_axis)
		SettingsManager.show_fps = gameplay.get("show_fps", SettingsManager.show_fps)
		SettingsManager.camera_shake = gameplay.get("camera_shake", SettingsManager.camera_shake)
	
	if data.has("graphics"):
		var graphics = data.graphics
		SettingsManager.shadow_quality = graphics.get("shadow_quality", SettingsManager.shadow_quality)
		SettingsManager.texture_quality = graphics.get("texture_quality", SettingsManager.texture_quality)
		SettingsManager.anti_aliasing = graphics.get("anti_aliasing", SettingsManager.anti_aliasing)
		SettingsManager.bloom_enabled = graphics.get("bloom_enabled", SettingsManager.bloom_enabled)
		SettingsManager.ambient_occlusion = graphics.get("ambient_occlusion", SettingsManager.ambient_occlusion)
	
	# Apply and save locally
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP Request failed with result: " + str(result))
		sync_failed.emit("HTTP request failed: " + str(result))
		return
	
	if response_code >= 200 and response_code < 300:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			
			if typeof(data) == TYPE_DICTIONARY:
				# If this was a GET request, apply the settings
				if data.has("video") or data.has("audio"):
					_apply_settings_from_dict(data)
				
				sync_completed.emit(true)
				print("Settings synced successfully with API")
			else:
				sync_failed.emit("Invalid response format")
		else:
			push_error("Failed to parse JSON response: " + json.get_error_message())
			sync_failed.emit("Failed to parse response")
	else:
		push_error("API returned error code: " + str(response_code))
		sync_failed.emit("API error: " + str(response_code))
