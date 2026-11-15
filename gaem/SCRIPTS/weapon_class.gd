extends Area2D

class_name WEAPON

var direction = Vector2.from_angle(rotation)

@export var damage: int = 1
@export var knockback: int = 200

var cooldown: Timer

func _ready() -> void:
	cooldown = Timer.new()
	cooldown.one_shot = true
	cooldown.wait_time = 1
	add_child(cooldown)

func _physics_process(delta: float) -> void:
	direction = (get_global_mouse_position() - global_position). normalized()
	rotation = direction.angle()
	
func attack(target: Node2D) -> void:
	if not cooldown.is_stopped():
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
	if target.has_method("take_knockback"):
		target.take_knockback(knockback, direction)
		
	cooldown.start()
