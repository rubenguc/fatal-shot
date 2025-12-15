extends CharacterBody3D

@onready var body = $body
@onready var animation_tree = $AnimationTree
@onready var animation = $AnimationPlayer

@export var cameras: Node3D 
@export var HUD: CanvasLayer
@export var enable_keyboard_movement: bool = true 
@export var hurt_duration: float = 1

const SENSITIBITY: float = 0.5
const SPEED: float = 5.0
var can_act: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var joystick: VirtualJoystick

#signal camera_toggle_pressed()
#
#func _on_camera_toggle_pressed_action():
	#emit_signal("camera_toggle_pressed")

func _ready():
	joystick = HUD.get_node("VirtualJoystick")
	HUD.get_node("CameraToggle").connect("pressed", _on_camera_toggle_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not can_act:
		return

	if event is InputEventScreenDrag:
		var viewport_width = get_viewport().size.x
		if event.position.x > (viewport_width / 2):
			rotate_y(deg_to_rad(-event.relative.x * SENSITIBITY))
			cameras.rotate_x(deg_to_rad(event.relative.y * SENSITIBITY))
			if cameras.is_frontal_camera_open():
				cameras.rotation.x = clamp(cameras.rotation.x, deg_to_rad(-45), deg_to_rad(45))
			else:
				cameras.rotation.x = clamp(cameras.rotation.x, deg_to_rad(-70), deg_to_rad(85))

func _physics_process(_delta: float) -> void:
	if not can_act:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return
	
	var input_dir_joystick = -joystick.get_value()
	
	# Obtener input de teclado (WASD)
	var input_dir_keyboard = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):     # W
		input_dir_keyboard.y = 1
	if Input.is_action_pressed("ui_down"):   # S
		input_dir_keyboard.y -= 1
	if Input.is_action_pressed("ui_left"):   # A
		input_dir_keyboard.x = 1
	if Input.is_action_pressed("ui_right"):  # D
		input_dir_keyboard.x -= 1

	var input_dir = input_dir_joystick
	if enable_keyboard_movement:
		input_dir += input_dir_keyboard
	if input_dir.length() > 1:
		input_dir = input_dir.normalized()
		
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

func take_damage(damage: int) -> void:
	if not can_act:
		return
	
	can_act = false
	if cameras.is_frontal_camera_open():
		_change_to_camera_close_state()
	animation_tree.active = false
	animation.play("player-animations/Hit_Chest", -1, 0.7)
	await animation.animation_finished
	can_act = true
	animation_tree.active = true

func _on_camera_toggle_pressed() -> void:
	if not can_act:
		return

	if cameras.is_frontal_camera_open():
		_change_to_camera_close_state()
	else:
		cameras.hide_camera_toggle()
		animation_tree.set("parameters/conditions/is_camera_close", false)
		animation_tree.set("parameters/conditions/is_camera_open", true)
		await get_tree().create_timer(0.5).timeout
		body.hide()
		var new_rotation_y = body.rotation.y
		rotate_y(new_rotation_y)
		body.rotate_y(-new_rotation_y)
		cameras.switch_to_frontal_camera()

func _change_to_camera_close_state():
	body.show()
	animation_tree.set("parameters/conditions/is_camera_open", false)
	animation_tree.set("parameters/conditions/is_camera_close", true)
	cameras.switch_to_back_camera()
