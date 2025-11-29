extends Node

## Manages user control bindings using Godot's InputMap
## Provides save/load functionality for custom key bindings

const SAVE_FILE_PATH := "user://key_bindings.cfg"

signal bindings_changed()

# Default key bindings for each action (2D Fishing Game)
var default_bindings := {
    "move_left": KEY_A,
    "move_right": KEY_D,
    "move_up": KEY_W,
    "move_down": KEY_S,
    "cast_line": KEY_SPACE,
    "reel_in": KEY_SPACE,
    "interact": KEY_E,
    "inventory": KEY_I,
    "pause": KEY_ESCAPE
}

# Action display names for UI
var action_names := {
    "move_left": "Move Left",
    "move_right": "Move Right",
    "move_up": "Move Up",
    "move_down": "Move Down",
    "cast_line": "Cast Fishing Line",
    "reel_in": "Reel In",
    "interact": "Interact",
    "inventory": "Open Inventory",
    "pause": "Pause Menu"
}

func _ready() -> void:
    ensure_input_actions_exist()
    load_bindings()

## Ensure all input actions exist in InputMap
func ensure_input_actions_exist() -> void:
    for action in default_bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            # Add default key
            var event = InputEventKey.new()
            event.keycode = default_bindings[action]
            InputMap.action_add_event(action, event)

## Load custom bindings from file
func load_bindings() -> void:
    var config = ConfigFile.new()
    var err = config.load(SAVE_FILE_PATH)
    
    if err != OK:
        print("No custom key bindings found, using defaults")
        return
    
    for action in default_bindings.keys():
        if config.has_section_key("bindings", action):
            var keycode = config.get_value("bindings", action)
            set_action_key(action, keycode, false)
    
    bindings_changed.emit()
    print("Key bindings loaded")

## Save current bindings to file
func save_bindings() -> void:
    var config = ConfigFile.new()
    
    for action in default_bindings.keys():
        var keycode = get_action_keycode(action)
        config.set_value("bindings", action, keycode)
    
    var err = config.save(SAVE_FILE_PATH)
    if err == OK:
        print("Key bindings saved")
    else:
        push_error("Failed to save key bindings: " + str(err))

## Set a new key for an action
func set_action_key(action: String, keycode: int, save_immediately: bool = true) -> void:
    if not InputMap.has_action(action):
        push_error("Action does not exist: " + action)
        return
    
    # Clear existing events for this action
    InputMap.action_erase_events(action)
    
    # Add new key event
    var event = InputEventKey.new()
    event.keycode = keycode
    InputMap.action_add_event(action, event)
    
    bindings_changed.emit()
    
    if save_immediately:
        save_bindings()

## Get the current keycode for an action
func get_action_keycode(action: String) -> int:
    if not InputMap.has_action(action):
        return KEY_NONE
    
    var events = InputMap.action_get_events(action)
    for event in events:
        if event is InputEventKey:
            return event.keycode
    
    return KEY_NONE

## Get human-readable key name
func get_key_name(keycode: int) -> String:
    return OS.get_keycode_string(keycode)

## Get display name for an action
func get_action_display_name(action: String) -> String:
    return action_names.get(action, action.capitalize())

## Check if a keycode is already bound to another action
func is_key_bound(keycode: int, exclude_action: String = "") -> bool:
    for action in default_bindings.keys():
        if action == exclude_action:
            continue
        if get_action_keycode(action) == keycode:
            return true
    return false

## Get action that a key is bound to (if any)
func get_action_for_key(keycode: int) -> String:
    for action in default_bindings.keys():
        if get_action_keycode(action) == keycode:
            return action
    return ""

## Reset all bindings to defaults
func reset_to_defaults() -> void:
    for action in default_bindings.keys():
        set_action_key(action, default_bindings[action], false)
    save_bindings()
    bindings_changed.emit()
    print("Key bindings reset to defaults")

## Get all actions as an array
func get_all_actions() -> Array:
    return default_bindings.keys()

