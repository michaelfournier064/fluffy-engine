extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var animation_player = $MeshInstance3D/Mage/AnimationPlayer
# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		# Rotate the character left/right
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Rotate the camera up/do
		$Camera3D.rotate_x(event.relative.y * MOUSE_SENSITIVITY)
		# Clamp camera rotation so you can't flip upside down
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, deg_to_rad(-10), deg_to_rad(30))
		
func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction
	var input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	handle_animations()

	
func handle_animations():
		if is_on_floor():
			if velocity.length() > 0.1:
				animation_player.play("Walking_B")  # Change to your walking animation name
			else:
					animation_player.play("Idle")  # Change to your idle animation name
		else:
						animation_player.play("Jump_Full_Short")  # Change to your jumping animation name
