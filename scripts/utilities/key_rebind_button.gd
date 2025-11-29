# res://scripts/utilities/key_rebind_button.gd
extends Button

## Button that captures key presses for rebinding controls

signal key_assigned(action: String, keycode: int)

var action_name: String = ""
var is_listening: bool = false
var original_text: String = ""

func _ready() -> void:
    pressed.connect(_on_pressed)
    focus_exited.connect(_on_focus_lost)

func setup(action: String, current_keycode: int) -> void:
    action_name = action
    update_display(current_keycode)

func update_display(keycode: int) -> void:
    if keycode == KEY_NONE:
        text = "None"
    else:
        text = UserControls.get_key_name(keycode)
    original_text = text

func _on_pressed() -> void:
    if is_listening:
        cancel_listening()
    else:
        start_listening()

func start_listening() -> void:
    is_listening = true
    text = "Press any key..."
    grab_focus()

func cancel_listening() -> void:
    is_listening = false
    text = original_text
    release_focus()

func _on_focus_lost() -> void:
    if is_listening:
        cancel_listening()

func _input(event: InputEvent) -> void:
    if not is_listening:
        return
    
    if event is InputEventKey and event.pressed:
        var keycode = event.keycode
        
        # Prevent unbinding Escape (usually for menu)
        if keycode == KEY_ESCAPE:
            cancel_listening()
            return
        
        # Check if key is already bound
        var existing_action = UserControls.get_action_for_key(keycode)
        if existing_action != "" and existing_action != action_name:
            # Show warning but allow rebind (will swap)
            print("Warning: %s is already bound to %s" % [UserControls.get_key_name(keycode), UserControls.get_action_display_name(existing_action)])
        
        # Assign the new key
        update_display(keycode)
        original_text = text
        is_listening = false
        release_focus()
        
        key_assigned.emit(action_name, keycode)
        
        get_viewport().set_input_as_handled()
