extends Camera3D

@onready var area := $Area3D as Area3D
@onready var collision_shape := $Area3D/CollisionShape3D as CollisionShape3D
@onready var camera_shot_button = %CameraShot as TouchScreenButton  # Especificar el tipo

@export var ray_length: float = 30.0
@export var half_view_size_multiplier: float = 0.3
@export var shot_delay: float = 1.0  # Tiempo en segundos de bloqueo del botón

signal is_focusing_enemy

var is_shot_delayed = false

var normal_color: Color = Color.WHITE
var disabled_color: Color = Color(1, 1, 1, 0.5)

func _ready() -> void:
	update_area_size()
	# Guardar el color original
	normal_color = camera_shot_button.modulate

func _process(delta: float) -> void:	
	if current:
		var bodies = area.get_overlapping_bodies()
		var found_enemy = false
		
		for body in bodies:
			if body is CharacterBody3D && body.collision_layer == 4:
				found_enemy = !body.is_dead()
				break
		is_focusing_enemy.emit(found_enemy)

func update_area_size() -> void:
	var half_height = tan(deg_to_rad(fov / 2.0)) * ray_length
	var aspect = get_viewport().size.x / get_viewport().size.y
	var half_width = half_height * aspect
	var cylinder_radius = min(half_width, half_height) * half_view_size_multiplier

	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = cylinder_radius
	cylinder_shape.height = ray_length
	collision_shape.shape = cylinder_shape

	collision_shape.rotation_degrees = Vector3(90, 0, 0)
	collision_shape.position = Vector3(0, 0, ray_length / 2)	

func _on_camera_shot_pressed() -> void:
	if current and not is_shot_delayed:
		var bodies = area.get_overlapping_bodies()		
		for body in bodies:
			if body is CharacterBody3D && body.collision_layer == 4: 
				if body.has_method("take_damage") and !body.is_dead():
					body.take_damage(90)
					# Iniciar el delay del botón
					start_shot_delay()
				break

func start_shot_delay():
	camera_shot_button.set_process_input(false)
	# Cambiar el color a transparente o semi-transparente
	camera_shot_button.modulate = disabled_color
	is_shot_delayed = true

	# Esperar el tiempo de delay
	await get_tree().create_timer(shot_delay).timeout

	# Rehabilitar el botón
	camera_shot_button.set_process_input(true)
	camera_shot_button.modulate = normal_color
	is_shot_delayed = false
