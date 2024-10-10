extends CharacterBody2D

# Constants for movement
var speed = 200
var jump_speed = -400
var gravity = 1000

# Number of allowed jumps
var max_jumps = 2
var jump_count = 0

# Get the AnimatedSprite2D node for animations
@onready var sprite = $AnimatedSprite2D

# Player Stats
var max_health: int = 100
var current_health: int = 100
var is_dead: bool = false

# States for character
var is_crouching = false
var is_attacking = false
var is_dodging = false

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0  # Reset vertical velocity on the ground
		jump_count = 0   # Reset jump count

	# Handle crouching
	if Input.is_action_pressed("ui_down"):
		if not is_crouching:
			sprite.play("crouch")
		is_crouching = true
		velocity.x = 0  # Prevent movement while crouching
	else:
		is_crouching = false

	# Movement logic
	if not is_crouching and not is_attacking and not is_dodging:
		velocity.x = 0  # Reset horizontal velocity each frame

		if Input.is_action_pressed("ui_right"):
			velocity.x += speed
			sprite.flip_h = false  # Face right
		elif Input.is_action_pressed("ui_left"):
			velocity.x -= speed
			sprite.flip_h = true  # Face left

	# Jumping logic
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = jump_speed
			jump_count += 1
		elif jump_count < max_jumps:
			velocity.y = jump_speed
			jump_count += 1

	# Dodge logic
	if Input.is_action_just_pressed("dodge"):
		if not is_dodging:  # Prevent dodging if already dodging
			is_dodging = true
			sprite.play("dodge")  # Play dodge animation
			# Apply some horizontal force for the dodge (adjust speed as needed)
			velocity.x = speed * (1 if not sprite.flip_h else -1)
			await get_tree().create_timer(0.5).timeout  # Duration of dodge
			is_dodging = false

	# Attack logic
	if Input.is_action_just_pressed("attack"):
		if not is_attacking:  # Prevent attack if already attacking
			is_attacking = true
			sprite.play("attack")  # Play attack animation
			# Wait for the attack animation to finish before resetting
			await get_tree().create_timer(0.7).timeout  # Adjust duration as needed
			is_attacking = false

	# Apply movement using move_and_slide()
	move_and_slide()

	# Animation handling
	if is_attacking:
		# Skip normal animation updates if attacking
		return
	elif is_dodging:
		# Skip normal animation updates if dodging
		return
	elif is_crouching:
		if sprite.animation != "crouch":  # Play crouch animation only if not already playing
			sprite.play("crouch")
	elif velocity.y < 0:
		sprite.play("jump")
	elif velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

# Function to take damage
func take_damage(damage: int) -> void:
	if is_dead:
		return  # If player is dead, no more damage can be taken

	current_health -= damage
	if current_health <= 0:
		current_health = 0
		die()  # Call death function when health reaches zero
	else:
		sprite.play("hurt")  # Play hurt animation if taking damage
	print("Player Health: ", current_health)

# Function to handle player's death
func die() -> void:
	is_dead = true
	sprite.play("dead")
	set_physics_process(false)  # Disable player input
	# Optional: Restart level, respawn, or show game over screen
	await get_tree().create_timer(1.6).timeout  # Wait for 1 second before restarting
	get_tree().reload_current_scene()  # Restart the level (optional)
