extends CharacterBody3D
enum State { IDLE, CHASING, ATTACKING, HURT, DEAD }

@export var player_node: Node3D
@export var attack_distance: float = 2.0
@export var speed: float = 3.0
@export var attack_cooldown: float = 1.0
@export var hurt_duration: float = 1.0
@export var return_distance: float = 10.0

@onready var animation_tree = $AnimationTree

var health: int = 100
var max_health: int = 100

var current_state: State = State.IDLE
var attack_timer: float = 0.0
var target_return_position: Vector3 = Vector3.ZERO
var is_returning: bool = false
var attack_rotation: Vector3 = Vector3.ZERO
var is_attack_in_progress: bool = false

func _ready():
	if not player_node:
		print("Warning: Player node not assigned!")
	
	look_at(player_node.global_position, Vector3.UP, true)

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
	update_state()	
	match current_state:
		State.CHASING:
			chase_player(delta)
		State.ATTACKING:
			attack_player(delta)
		State.HURT:
			handle_hurt_state(delta)
		State.IDLE:
			idle_state(delta)
		State.DEAD:
			pass
	
	if current_state == State.CHASING:
		velocity.y += ProjectSettings.get("physics/3d/default_gravity") * delta

	move_and_slide()

func update_state():
	if not player_node:
		return
	
	var player_distance = global_position.distance_to(player_node.global_position)
	
	match current_state:
		State.IDLE:
			current_state = State.CHASING
		State.CHASING:
			if player_distance <= attack_distance and attack_timer <= 0:
				current_state = State.ATTACKING
				attack_timer = attack_cooldown
				attack_rotation = rotation
				is_attack_in_progress = false
		State.ATTACKING:
			if player_distance > attack_distance + 1.0:
				current_state = State.CHASING

func chase_player(delta):
	if not player_node:
		return
	
	var direction = (player_node.global_position - global_position).normalized()
	velocity = direction * speed
	animation_tree.set("parameters/conditions/is_walking", true)
	animation_tree.set("parameters/conditions/is_idle", false)
	look_at(player_node.global_position, Vector3.UP, true)

func attack_player(delta):
	if is_attack_in_progress:
		return

	is_attack_in_progress = true
	velocity = Vector3.ZERO
	rotation = attack_rotation
	animation_tree.set("parameters/conditions/is_attacking", true)
	player_node.take_damage(20)
	await get_tree().create_timer(2.4167).timeout
	animation_tree.set("parameters/conditions/is_attacking", false)

	# Iniciar el proceso de retorno
	if not is_returning:
		await calculate_return_position()

func calculate_return_position():
	is_returning = true
	var random_angle = randf() * 2 * PI
	var offset = Vector3(cos(random_angle), 0, sin(random_angle)) * return_distance
	target_return_position = player_node.global_position + offset
	position = target_return_position
	await get_tree().create_timer(1).timeout
	is_returning = false
	current_state = State.CHASING

func handle_hurt_state(delta):
	velocity = Vector3.ZERO

func idle_state(delta):
	velocity = Vector3.ZERO
	if player_node:
		look_at(player_node.global_position, Vector3.UP)
#
func take_damage(damage: int):
	if current_state == State.DEAD or current_state == State.HURT:
		return
		
	print("damage")
		
	current_state = State.HURT
	animation_tree.set("parameters/conditions/is_hurting", true)	
	health -= damage
	await get_tree().create_timer(hurt_duration).timeout

	if is_dead():
		health = 0
		_die()
	else:
		is_returning = false
		animation_tree.set("parameters/conditions/is_hurting", false)
		if not is_returning:
			await calculate_return_position()
		
func _die():
	current_state = State.DEAD
	animation_tree.set("parameters/conditions/is_dead", true)
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func is_dead():
	return health <= 0
