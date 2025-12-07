extends Node3D

# Cameras
@onready var back_camera = $"3d/BackCamera"
@onready var frontal_camera = $FrontalCamera

# UI
@onready var camera_toggle = %CameraToggle
@onready var camera_shot_button = %CameraShot
@onready var camera_ring = %CameraFocus

# State
var saved_back_camera_transform: Transform3D
var is_frontal_active: bool = false

func _ready() -> void:
	back_camera.current = true
	frontal_camera.current = false
	is_frontal_active = false

func _process(delta: float) -> void:
	pass


func switch_to_frontal_camera(body_rotation: Vector3):
	saved_back_camera_transform = transform
	is_frontal_active = true
	back_camera.current = false
	rotation.x = 0
	rotation.y = body_rotation.y
	frontal_camera.current = true
	camera_toggle.visible = true
	camera_ring.visible = true
	camera_shot_button.visible = true
	
func switch_to_back_camera():
	is_frontal_active = false
	if saved_back_camera_transform != Transform3D():
		transform = saved_back_camera_transform
	back_camera.current = true
	frontal_camera.current = false
	camera_ring.visible = false
	frontal_camera.reset_energy()
	camera_shot_button.visible = false

func is_frontal_camera_open() -> bool:
	return frontal_camera.current

func hide_camera_toggle():
	camera_toggle.visible = false
