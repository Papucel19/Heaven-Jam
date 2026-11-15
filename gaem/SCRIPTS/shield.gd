extends Node2D

class_name SHIELD

@onready var shield: SHIELD = self

var health = 2
var rotation_speed = 1000
var target_angle: float =  0

func _ready() -> void:
	target_angle = 0

func _process(delta: float) -> void:
	if health <= 0:
		shield.queue_free()
	
	if Input.is_action_just_pressed("shield_left"):
		shield.rotate(deg_to_rad(-1))
		target_angle = deg_to_rad(-180)
		
	if Input.is_action_just_pressed("shield_right"):
		shield.rotate(deg_to_rad(+1))
		target_angle = deg_to_rad(0)
		
	if Input.is_action_just_pressed("shield_up"):
		shield.rotate(deg_to_rad(-1))
		target_angle = deg_to_rad(-90)
		
	if Input.is_action_just_pressed("shield_down"):
		shield.rotate(deg_to_rad(+1))
		target_angle = deg_to_rad(90)
		
	shield.rotation = rotate_toward(rotation, target_angle, deg_to_rad(rotation_speed) * delta)
