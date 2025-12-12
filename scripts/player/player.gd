extends CharacterBody2D

@export var speed: float = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing_system: Node = $FishingSystem
@onready var fishing_ui: CanvasLayer = $FishingUI

var is_fishing: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left
var last_vertical_direction: int = 0  # 1 for down, -1 for up, 0 for none
var in_water_area: bool = false

func _physics_process(_delta: float) -> void:
	if not is_fishing:
		handle_movement()
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

func handle_movement() -> void:
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		facing_direction = 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		facing_direction = -1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		last_vertical_direction = -1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
		last_vertical_direction = 1

	input_vector = input_vector.normalized()
	velocity = input_vector * speed

	# Update sprite direction for horizontal movement
	if input_vector.x != 0:
		animated_sprite.flip_h = input_vector.x < 0

func update_animation() -> void:
	if is_fishing:
		if animated_sprite.animation != "fishing":
			animated_sprite.play("fishing")
		return

	if velocity.length() > 0:
		# Prioritize vertical movement for animation
		if abs(velocity.y) > abs(velocity.x):
			if velocity.y < 0:
				animated_sprite.play("walk_up")
			else:
				animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_side")
	else:
		# Stop animation on current frame when not moving
		animated_sprite.stop()

func _ready() -> void:
	# Connect fishing UI to fishing system
	if fishing_ui and fishing_system:
		fishing_ui.set_fishing_system(fishing_system)

	# Connect to fishing system signals
	if fishing_system:
		fishing_system.fishing_ended.connect(_on_fishing_ended)
		fishing_system.fish_caught.connect(_on_fish_caught)
		fishing_system.fish_escaped.connect(_on_fish_escaped)
	
	# Connect to GameState signals to load player position
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		game_state.game_loaded.connect(_on_game_loaded)
		# Apply position immediately if already loaded
		if game_state.current_save_id >= 0 and game_state.player_position != Vector2.ZERO:
			position = game_state.player_position
			print("[Player] Position loaded: ", position)
	
	# Re-enable pausing now that the game scene is loaded
	if has_node("/root/PauseManager"):
		var pause_manager = get_node("/root/PauseManager")
		pause_manager.can_pause = true
		print("[Player] Pause manager re-enabled")

func _input(event: InputEvent) -> void:
	# Left click to cancel fishing
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_fishing:
				toggle_fishing()
				return

	# Check for minigame input first (W, A, S, D)
	if fishing_system and fishing_system.minigame_active:
		if event.is_action_pressed("move_up"):
			fishing_system.check_key_input("move_up")
			return
		elif event.is_action_pressed("move_down"):
			fishing_system.check_key_input("move_down")
			return
		elif event.is_action_pressed("move_left"):
			fishing_system.check_key_input("move_left")
			return
		elif event.is_action_pressed("move_right"):
			fishing_system.check_key_input("move_right")
			return

	if event.is_action_pressed("cast_line"):
		if is_fishing:
			# Attempt to reel in (catch the fish / start minigame)
			if fishing_system.fish_hooked_active:
				fishing_system.attempt_catch()
		elif in_water_area:
			# Start fishing
			toggle_fishing()

func toggle_fishing() -> void:
	if not in_water_area and not is_fishing:
		return

	is_fishing = !is_fishing

	if is_fishing:
		# Play casting animation if available, otherwise fishing
		if animated_sprite.sprite_frames.has_animation("casting"):
			animated_sprite.play("casting")
			await animated_sprite.animation_finished
		animated_sprite.play("fishing")
		# Start the fishing minigame
		fishing_system.start_fishing()
	else:
		fishing_system.end_fishing()

# Called when entering water area
func _on_water_area_entered(_area: Area2D) -> void:
	in_water_area = true

# Called when leaving water area
func _on_water_area_exited(_area: Area2D) -> void:
	in_water_area = false
	if is_fishing:
		toggle_fishing()  # Stop fishing if you leave water

# Called when fishing ends (success or failure)
func _on_fishing_ended() -> void:
	is_fishing = false

# Called when fish is caught
func _on_fish_caught(_fish_data: Dictionary) -> void:
	# Fishing will end automatically via fishing_ended signal
	pass

# Called when fish escapes
func _on_fish_escaped() -> void:
	# Fishing will end automatically via fishing_ended signal
	pass

# Called when game is loaded from a save
func _on_game_loaded() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.player_position != Vector2.ZERO:
			position = game_state.player_position
			print("[Player] Position restored: ", position)
