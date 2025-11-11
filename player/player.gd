extends CharacterBody3D

@onready var head = $Cameras
@onready var body = $body
@onready var animation_tree = $AnimationTree
@onready var animation = $AnimationPlayer
@onready var player_camera = $"Cameras/3d/PlayerCamera"
@onready var frontal_camera = $Cameras/FrontalCamera
@onready var camera_toggle = %CameraToggle
@onready var camera_raycast = $Cameras/FrontalCamera/Raycast
@onready var camera_ring = %CameraFocus

@export var joystick: VirtualJoystick

const SENSITIBITY: float = 0.5
const SPEED: float = 5.0

var energy_bar = 0
var charging_speed = 1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var viewport_width = get_viewport().size.x
		if event.position.x > (viewport_width / 2):
			rotate_y(deg_to_rad(-event.relative.x * SENSITIBITY))
			head.rotate_x(deg_to_rad(event.relative.y * SENSITIBITY))
			
			body.rotate_y(deg_to_rad(event.relative.x * SENSITIBITY))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-70), deg_to_rad(85))

func _physics_process(_delta: float) -> void:
	var input_dir = -joystick.get_value()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	animation_tree.set("parameters/conditions/idle", !direction)
	animation_tree.set("parameters/conditions/walk", !!direction)
	
	if direction:
		body.look_at(position -direction * 100)	
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _switch_to_front_camera() -> void:	
	body.show()
	camera_raycast.enabled = false
	camera_ring.visible = false
	camera_ring.progress = 0
	animation_tree.set("parameters/conditions/is_camera_open", false)
	player_camera.current = true
	frontal_camera.current = false
	animation_tree.set("parameters/conditions/is_camera_close", true)

func _switch_to_player_camera() -> void:	
	camera_toggle.visible = false
	animation_tree.set("parameters/conditions/is_camera_close", false)
	animation_tree.set("parameters/conditions/is_camera_open", true)
	await get_tree().create_timer(0.5).timeout
	body.hide()
	player_camera.current = false
	frontal_camera.current = true
	camera_toggle.visible = true
	camera_ring.visible = true
	camera_raycast.enabled = true

func _on_raycast_is_focusing_enemy(isFocusing: bool) -> void:	
	if isFocusing:
		energy_bar += charging_speed
	else:
		energy_bar -= charging_speed
	energy_bar = clamp(energy_bar, 0, 100)
	camera_ring.progress = energy_bar
	print(energy_bar)
	


func _on_camera_toggle_pressed() -> void:
	var is_camera_open: Variant = animation_tree.get("parameters/conditions/is_camera_open")
	if is_camera_open:
		_switch_to_front_camera()
	else:
		_switch_to_player_camera()
