extends Node3D

# Cameras
@onready var back_camera = $"3d/BackCamera"
@onready var frontal_camera = $FrontalCamera

# HUD
@export var HUD: CanvasLayer

# State
var is_frontal_active: bool = false
var camera_toggle: TouchScreenButton
var camera_shot: TouchScreenButton
var camera_ring_focus: RadialProgress

func _ready() -> void:
	camera_toggle = HUD.get_node("CameraToggle")
	camera_shot = HUD.get_node("CameraShot")
	camera_ring_focus = HUD.get_node("CameraRingFocus")
	back_camera.current = true
	frontal_camera.current = false
	is_frontal_active = false

func _process(delta: float) -> void:
	pass


func switch_to_frontal_camera():
	back_camera.current = false
	reset_camera_x()
	frontal_camera.current = true
	camera_toggle.visible = true
	camera_ring_focus.visible = true
	camera_shot.visible = true
	
func switch_to_back_camera():
	reset_camera_x()
	back_camera.current = true
	frontal_camera.current = false
	camera_ring_focus.visible = false
	frontal_camera.reset_energy()
	camera_shot.visible = false

func reset_camera_x():
	rotation.x = 0

func is_frontal_camera_open() -> bool:
	return frontal_camera.current

func rotate_back_camera():
	pass
		

func hide_camera_toggle():
	camera_toggle.visible = false
