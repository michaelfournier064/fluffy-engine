# Settings System Documentation

## Overview

The settings system provides a comprehensive solution for managing game settings with both local storage and external API synchronization capabilities.

## Components

### 1. SettingsManager (Autoload Singleton)
**Location:** `scripts/save_data/settings_manager.gd`

The core settings manager that handles:
- Video settings (resolution, window mode, VSync)
- Audio settings (master, music, SFX, UI volumes)
- Gameplay settings (mouse sensitivity, camera options)
- Graphics settings (quality presets, effects)
- Local file saving/loading using ConfigFile
- Applying settings to the game engine

**Key Functions:**
```gdscript
SettingsManager.load_settings()          # Load from local file
SettingsManager.save_settings()          # Save to local file
SettingsManager.apply_settings()         # Apply to game engine
SettingsManager.reset_to_defaults()      # Reset all settings
SettingsManager.set_setting(name, value) # Set individual setting
SettingsManager.get_setting(name)        # Get individual setting
```

### 2. Settings Screen UI
**Location:** `scenes/settings_screen.tscn` and `scripts/settings_screen.gd`

A complete tabbed interface with four categories:

- **Video Tab**: Window mode, resolution, VSync
- **Audio Tab**: Volume sliders with real-time preview
- **Gameplay Tab**: Mouse sensitivity, camera options, UI preferences
- **Graphics Tab**: Quality settings and visual effects toggles

**Features:**
- Real-time audio preview (changes apply immediately to sliders)
- Visual feedback for unsaved changes
- Apply button (only enabled when changes exist)
- Reset to defaults button
- CustomButton integration with hover/press effects

### 3. Settings API Service
**Location:** `scripts/save_data/settings_api_service.gd`

Handles communication with external Go backend for cloud storage and synchronization.

**Key Functions:**
```gdscript
SettingsAPIService.save_settings_to_api(user_id)  # POST settings to API
SettingsAPIService.load_settings_from_api(user_id) # GET settings from API
```

**Signals:**
```gdscript
sync_completed(success: bool)  # Emitted when sync succeeds
sync_failed(error: String)     # Emitted when sync fails
```

## Settings Categories

### Video Settings
- `fullscreen: bool` - Fullscreen mode
- `vsync_enabled: bool` - Vertical sync
- `resolution: Vector2i` - Screen resolution
- `window_mode: int` - Window mode (0=Windowed, 3=Fullscreen, 4=Exclusive)

### Audio Settings
- `master_volume: float` (0.0 - 1.0) - Master volume
- `music_volume: float` (0.0 - 1.0) - Music volume
- `sfx_volume: float` (0.0 - 1.0) - Sound effects volume
- `ui_volume: float` (0.0 - 1.0) - UI sounds volume

### Gameplay Settings
- `mouse_sensitivity: float` (0.1 - 2.0) - Mouse sensitivity
- `invert_y_axis: bool` - Invert Y-axis for camera
- `show_fps: bool` - Display FPS counter
- `camera_shake: bool` - Enable camera shake effects

### Graphics Settings
- `shadow_quality: int` (0-3) - Shadow quality (Low/Medium/High/Ultra)
- `texture_quality: int` (0-3) - Texture quality
- `anti_aliasing: bool` - Anti-aliasing enabled
- `bloom_enabled: bool` - Bloom effect
- `ambient_occlusion: bool` - Ambient occlusion

## Local Storage

Settings are saved to: `user://settings.cfg`

The file uses Godot's ConfigFile format:
```ini
[video]
fullscreen=false
vsync_enabled=true
resolution=Vector2i(1920, 1080)

[audio]
master_volume=1.0
music_volume=0.8
...
```

## Go Backend Integration

### API Endpoints

The system expects your Go backend to provide these endpoints:

#### Save Settings (POST)
```
POST /api/settings?user_id={user_id}
Content-Type: application/json

{
  "video": {
    "fullscreen": false,
    "vsync_enabled": true,
    "resolution": {"width": 1920, "height": 1080},
    "window_mode": 0
  },
  "audio": {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 0.8,
    "ui_volume": 1.0
  },
  "gameplay": {
    "mouse_sensitivity": 0.5,
    "invert_y_axis": false,
    "show_fps": false,
    "camera_shake": true
  },
  "graphics": {
    "shadow_quality": 2,
    "texture_quality": 2,
    "anti_aliasing": true,
    "bloom_enabled": true,
    "ambient_occlusion": true
  },
  "timestamp": 1234567890
}
```

#### Load Settings (GET)
```
GET /api/settings?user_id={user_id}

Returns the same JSON structure as above
```

### Example Go Handler Structure

```go
type GameSettings struct {
    Video    VideoSettings    `json:"video"`
    Audio    AudioSettings    `json:"audio"`
    Gameplay GameplaySettings `json:"gameplay"`
    Graphics GraphicsSettings `json:"graphics"`
    Timestamp int64           `json:"timestamp"`
}

func SaveSettingsHandler(w http.ResponseWriter, r *http.Request) {
    userID := r.URL.Query().Get("user_id")
    var settings GameSettings
    json.NewDecoder(r.Body).Decode(&settings)
    
    // Save to database
    // ...
    
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

func LoadSettingsHandler(w http.ResponseWriter, r *http.Request) {
    userID := r.URL.Query().Get("user_id")
    
    // Load from database
    // var settings GameSettings = ...
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(settings)
}
```

## Usage Examples

### Accessing Settings in Game Code

```gdscript
# Get current mouse sensitivity
var sensitivity = SettingsManager.mouse_sensitivity

# Check if FPS counter should be shown
if SettingsManager.show_fps:
    fps_label.visible = true

# Listen for setting changes
func _ready():
    SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(setting_name: String, value):
    print("Setting changed: ", setting_name, " = ", value)
```

### Syncing with API

To enable API syncing, add the SettingsAPIService as an autoload:

1. Open Project Settings > Autoload
2. Add `res://scripts/save_data/settings_api_service.gd` as `SettingsAPIService`

Then use it in your code:

```gdscript
# Save to API after applying settings
func _on_apply_pressed():
    apply_all_settings()
    SettingsAPIService.save_settings_to_api(player_user_id)

# Load from API on game start
func _ready():
    SettingsAPIService.sync_completed.connect(_on_sync_completed)
    SettingsAPIService.load_settings_from_api(player_user_id)

func _on_sync_completed(success: bool):
    if success:
        print("Settings loaded from cloud")
```

### Customizing API URL

Edit `settings_api_service.gd`:

```gdscript
const API_BASE_URL := "https://your-api-domain.com/api"
```

## Configuration

### Adding New Settings

1. Add the variable to `SettingsManager`:
```gdscript
var my_new_setting: bool = true
```

2. Add to `load_settings()` and `save_settings()`:
```gdscript
my_new_setting = config.get_value("category", "my_new_setting", my_new_setting)
config.set_value("category", "my_new_setting", my_new_setting)
```

3. Add to UI in `settings_screen.tscn`

4. Update API service's `_get_settings_dict()` and `_apply_settings_from_dict()`

### Changing Default Values

Edit the variable initialization in `SettingsManager` and the `reset_to_defaults()` function.

## Testing

1. Run the game and open Settings from the title screen
2. Change various settings
3. Click Apply to save
4. Restart the game to verify persistence
5. Test API sync (requires Go backend running)

## Audio Bus Setup

The settings system expects these audio buses to exist:
- Master (default)
- Music
- SFX  
- UI

To add them in Godot:
1. Open Audio bus panel (bottom of editor)
2. Add buses with these exact names
3. Parent them under Master

## Notes

- Settings are saved locally immediately when Apply is pressed
- Audio settings apply in real-time as sliders move for preview
- API sync is optional - local settings work independently
- The Apply button is disabled until changes are made
- Window changes take effect immediately when applied
