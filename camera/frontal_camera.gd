extends Camera3D

@onready var camera_shot_button = %CameraShot as TouchScreenButton
@onready var camera_ring = %CameraFocus

@export var ray_length: float = 30.0
@export_range(0.01, 1.0, 0.01) var focus_angle_multiplier: float = 0.55
@export var shot_delay: float = 1.0 


const ENEMY_COLLISION_LAYER: int = 4

# State
var is_shot_delayed = false
var normal_color: Color = Color.WHITE
var disabled_color: Color = Color(1, 1, 1, 0.5)
var energy_bar = 0
var charging_speed = 0.2

func _ready() -> void:
	normal_color = camera_shot_button.modulate

func _process(delta: float):
	if current:
		if get_focused_enemy() != null:
			energy_bar += charging_speed
		else:
			energy_bar -= charging_speed
		energy_bar = clamp(energy_bar, 0, 100)
		camera_ring.progress = energy_bar

func get_focused_enemy() -> CharacterBody3D:
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	query.shape.radius = ray_length
	query.transform = global_transform
	query.collision_mask = ENEMY_COLLISION_LAYER
	query.exclude = [self] 

	var results = space_state.intersect_shape(query)
	
	var camera_forward = -global_transform.basis.z.normalized()
	var allowed_angle_rad = deg_to_rad(fov / 2.0 * focus_angle_multiplier)
	var strict_threshold = cos(allowed_angle_rad) 

	for result in results:
		var body = result.collider
		if body is CharacterBody3D and body.collision_layer == ENEMY_COLLISION_LAYER and not body.is_dead():
			var direction_to_enemy = (body.global_position - global_position).normalized()
			var dot_product = camera_forward.dot(direction_to_enemy)
			
			if dot_product < 0:
				continue 

			var distance = global_position.distance_to(body.global_position)
			
			if distance < 4.5:
				if is_clear_sight(global_position, body.global_position):
					return body

			elif dot_product > strict_threshold:
				if is_clear_sight(global_position, body.global_position):
					return body

	return null

func is_clear_sight(from: Vector3, to: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = (1 << 1) 
	query.hit_from_inside = true 
	var result = space_state.intersect_ray(query)	
	return result.is_empty()

func _on_camera_shot_pressed() -> void:
	if current and not is_shot_delayed:
		var enemy_to_damage = get_focused_enemy()
		if enemy_to_damage != null:
			if enemy_to_damage.has_method("take_damage"):
				enemy_to_damage.take_damage(90)
				start_shot_delay()

func start_shot_delay():
	camera_shot_button.set_process_input(false)
	camera_shot_button.modulate = disabled_color
	is_shot_delayed = true

	await get_tree().create_timer(shot_delay).timeout

	camera_shot_button.set_process_input(true)
	camera_shot_button.modulate = normal_color
	is_shot_delayed = false

func reset_energy():
	energy_bar = 0
