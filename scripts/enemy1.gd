extends CharacterBody2D

# Constants for movement and attack
var speed = 100
var attack_distance = 50
var detection_radius = 200  # Radius to detect the player
var damage = 10
var health = 50
var gravity = 200  # Gravity force

@onready var sprite = $AnimatedSprite2D

# Reference to the player
var player: Node2D = null

# States
var is_dead = false
var is_attacking = false
var is_on_ground = false  # Track if the enemy is on the ground

func _ready():
	# Find the player node in the scene
	player = get_tree().get_root().get_node("MainScene/Player")  # Adjust this path as needed

func _physics_process(delta):
	if is_dead:
		return  # Skip logic if the enemy is dead

	# Apply gravity
	if not is_on_floor():  # Check if the enemy is on the ground
		velocity.y += gravity * delta
		is_on_ground = false
	else:
		velocity.y = 0  # Reset vertical velocity on the ground
		is_on_ground = true

	# Check for player's presence
	if player and position.distance_to(player.position) < detection_radius:
		move_towards_player()
		# Check if close enough to attack
		if position.distance_to(player.position) < attack_distance:
			attack()
	else:
		# If the player is out of detection range, return to idle
		velocity.x = 0  # Reset horizontal velocity when idle
		sprite.play("idle")  # Play idle animation

	# Apply movement using move_and_slide()
	move_and_slide()

# Function to move towards the player
func move_towards_player():
	if player:
		var direction = (player.position - position).normalized()  # Get direction towards player
		velocity.x = speed * direction.x  # Move towards the player

		# Flip the sprite based on movement direction
		sprite.flip_h = direction.x < 0  # Flip sprite if moving left

		# Update animations
		if not is_attacking:  # Only play run animation if not attacking
			sprite.play("run")  # Play running animation
	else:
		velocity.x = 0  # Reset horizontal velocity if no player is detected

# Attack the player
func attack():
	if not is_attacking:  # Prevent multiple attacks in a row
		is_attacking = true
		sprite.play("attack")  # Play attack animation
		await get_tree().create_timer(0.5).timeout  # Wait for the attack animation duration
		player.take_damage(damage)  # Call the player's take_damage method
		is_attacking = false  # Reset attacking state

# Function to take damage
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()
	else:
		sprite.play("hurt")  # Play hurt animation

# Function to handle enemy death
func die():
	is_dead = true
	velocity = Vector2.ZERO  # Stop all movement
	sprite.play("dead")  # Play dead animation
	await get_tree().create_timer(1.0).timeout  # Wait before removing the enemy
	queue_free()  # Remove the enemy from the scene
