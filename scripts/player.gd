extends CharacterBody2D

@export var speed: float = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing_system: Node = $FishingSystem
@onready var fishing_ui: CanvasLayer = $FishingUI

var is_fishing: bool = false
var is_attacking: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left
var in_water_area: bool = false

func _physics_process(_delta: float) -> void:
	if not is_fishing and not is_attacking:
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
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1

	input_vector = input_vector.normalized()
	velocity = input_vector * speed

	# Update sprite direction
	if input_vector.x != 0:
		animated_sprite.flip_h = input_vector.x < 0

func update_animation() -> void:
	if is_attacking:
		return

	if is_fishing:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return

	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		# Maintain the facing direction when idle
		animated_sprite.flip_h = facing_direction < 0
		animated_sprite.play("idle")

func _ready() -> void:
	# Connect fishing UI to fishing system
	if fishing_ui and fishing_system:
		fishing_ui.set_fishing_system(fishing_system)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_line"):
		if is_fishing:
			# Attempt to reel in (catch the fish)
			fishing_system.attempt_catch()
		elif in_water_area:
			# Start fishing
			toggle_fishing()

	if event.is_action_pressed("attack") and not is_attacking and not is_fishing:
		perform_attack()

func toggle_fishing() -> void:
	if not in_water_area and not is_fishing:
		print("Need to be near water to fish!")
		return
	
	is_fishing = !is_fishing
	if is_fishing:
		# Play casting animation if available, otherwise idle
		if animated_sprite.sprite_frames.has_animation("casting"):
			animated_sprite.play("casting")
			await animated_sprite.animation_finished
		animated_sprite.play("idle")
		# Start the fishing minigame
		fishing_system.start_fishing()
	else:
		animated_sprite.play("idle")
		fishing_system.end_fishing()

func perform_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	is_attacking = false

# Called when entering water area
func _on_water_area_entered(_area: Area2D) -> void:
	in_water_area = true
	print("Entered water area - can fish here!")

# Called when leaving water area
func _on_water_area_exited(_area: Area2D) -> void:
	in_water_area = false
	if is_fishing:
		toggle_fishing()  # Stop fishing if you leave water
	print("Left water area")
