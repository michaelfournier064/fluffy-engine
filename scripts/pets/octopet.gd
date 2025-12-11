# res://scripts/pets/octopet.gd
extends CharacterBody2D

## ============================================================================
## OCTOPET - Player's Pet Companion
## ============================================================================
## This script controls the octopet that follows the player around
## The octopet stays near the player and animates based on movement
## ============================================================================

## Movement settings
var follow_speed: float = 100.0  # How fast the octopet moves
var follow_distance: float = 50.0  # How close to stay to the player
var player: CharacterBody2D = null  # Reference to the player

## Components
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	# Safely get animated sprite
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		print("[Octopet] Warning: AnimatedSprite2D not found!")

	# Find the player in the scene (use call_deferred to avoid issues)
	call_deferred("find_player")

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player:
		# Position near the player to start
		global_position = player.global_position + Vector2(40, 0)
		print("[Octopet] Ready! Following player.")
	else:
		print("[Octopet] Error: Player not found!")

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player.global_position)

	# Only move if too far from player
	if distance_to_player > follow_distance:
		# Move towards player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * follow_speed
		move_and_slide()

		# Flip sprite based on direction (face the direction we're moving)
		if animated_sprite:
			if direction.x < 0:
				animated_sprite.flip_h = true  # Face left
			elif direction.x > 0:
				animated_sprite.flip_h = false  # Face right

		# Play walk animation when moving
		if animated_sprite and animated_sprite.sprite_frames:
			if animated_sprite.sprite_frames.has_animation("walk"):
				if not animated_sprite.is_playing():
					animated_sprite.play("walk")
	else:
		# Close enough, stop moving and stop animation
		velocity = Vector2.ZERO

		# Stop the animation when caught up
		if animated_sprite:
			animated_sprite.stop()
