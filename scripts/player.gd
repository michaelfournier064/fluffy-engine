extends CharacterBody2D

@export var speed: float = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_fishing: bool = false
var is_attacking: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left

func _physics_process(delta: float) -> void:
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
		if animated_sprite.animation != "fishing_idle":
			animated_sprite.play("fishing_idle")
		return

	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		# Maintain the facing direction when idle
		animated_sprite.flip_h = facing_direction < 0
		animated_sprite.play("idle")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_line"):
		toggle_fishing()

	if event.is_action_pressed("attack") and not is_attacking and not is_fishing:
		perform_attack()

func toggle_fishing() -> void:
	is_fishing = !is_fishing
	if is_fishing:
		animated_sprite.play("casting")
		await animated_sprite.animation_finished
		animated_sprite.play("fishing_idle")
	else:
		animated_sprite.play("idle")

func perform_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	is_attacking = false
