extends CharacterBody2D

class_name RAT

@export var gravity: int = 1000
@export var hitbox: Area2D
@export var sprite: AnimatedSprite2D
@export var health: int = 1
@export var damage: int = 1
@export var speed: int = 85
@export var friction: int = 1000
@export var acceleration: int = 600
@export var jump_force: float = 220.0
@export var jump_chance: float = 0.02
@export var start_animation: String = "idle"
@export var faces_right: bool = true 

var speed_mult := 1.0
var jump_mult := 1.0

@onready var player = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("stompable")
	speed_mult = randf_range(0.8, 1.2)
	jump_mult = randf_range(0.85, 1.25)

	if sprite == null:
		sprite = find_child("*", true, false) as AnimatedSprite2D
		for child in get_children():
			if child is AnimatedSprite2D:
				sprite = child
				break
	if sprite:
		sprite.play(start_animation)

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		print(name + " has no Hitbox Area2D assigned!")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		var dir = sign(to_player.x)

		if sprite and dir != 0:
			sprite.flip_h = (dir < 0) if faces_right else (dir > 0)

		velocity.x = move_toward(velocity.x, dir * speed * speed_mult, acceleration * delta)

		if is_on_floor():
			if is_on_wall():
				velocity.y = -jump_force * jump_mult
			elif to_player.y < -20 and abs(to_player.x) < 40:
				velocity.y = -jump_force * jump_mult
			elif randf() < jump_chance:
				velocity.y = -jump_force * 0.7 * jump_mult
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is PLAYER:
		if body.has_method("try_stomp") and body.try_stomp(self, 1):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
var dead := false
var stomp_immune := true   # stomping a small rat does not hurt it (it just bounces you)

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		SFX.play(self)
		var score_label = get_tree().get_first_node_in_group("labels")
		score_label.score += 1
		score_label.text = "SCORE: " + str(score_label.score)
		queue_free()

func take_knockback(amount: int, attacker_direction) -> void:
	velocity += amount * attacker_direction

func launch_up(launch_power) -> void:
	velocity.y -= launch_power
