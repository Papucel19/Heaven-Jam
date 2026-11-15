extends Area2D

class_name PROJECTILE

@export var damage: int = 1
@export var knockback: int = 250
@export var speed: int = 500
@export var cooldown: int = 1
@export var hitbox: Area2D
@export var max_bounces: int = 3     
@export var lifetime: float = 3.0     
@export var radius: float = 7.0       

const HIT_SOUND_PATH := "res://AUDIO/ball_hit.wav"
const HIT_MASK := (1 << 0) | (1 << 2)

var life_time: Timer
var direction = Vector2.RIGHT
var bounces := 0
var hit_sound: AudioStream
var excluded: Array[RID] = []

func _ready() -> void:
	direction = (get_global_mouse_position() - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()

	if ResourceLoader.exists(HIT_SOUND_PATH):
		hit_sound = load(HIT_SOUND_PATH)

	# the ball starts at the player, so it must ignore the player
	for p in get_tree().get_nodes_in_group("Player"):
		if p is CollisionObject2D:
			excluded.append(p.get_rid())

	life_time = Timer.new()
	life_time.wait_time = lifetime
	life_time.one_shot = true
	add_child(life_time)
	life_time.start()

func _physics_process(delta: float) -> void:
	if life_time.is_stopped():
		queue_free()
		return

	var step = direction * speed * delta
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + step + direction * radius,
		HIT_MASK
	)
	query.exclude = excluded
	var hit = get_world_2d().direct_space_state.intersect_ray(query)

	if hit.is_empty():
		global_position += step
		return

	_on_hit(hit)

func _on_hit(hit: Dictionary) -> void:
	var collider = hit.get("collider")

	# hurt enemies
	if collider and collider.has_method("take_damage") and collider is not PLAYER:
		collider.take_damage(damage)
		if collider.has_method("take_knockback"):
			collider.take_knockback(knockback, direction)

	_play_hit_sound()

	# out of bounces: the ball is gone
	if bounces >= max_bounces:
		queue_free()
		return

	# bounce off whatever we hit (wall or enemy)
	bounces += 1
	direction = direction.bounce(hit.normal).normalized()
	rotation = direction.angle()
	global_position = hit.position + hit.normal * (radius + 1.0)

func _play_hit_sound() -> void:
	if hit_sound == null or get_tree().current_scene == null:
		return
	# the sound is added to the level, so it keeps playing after the ball is gone
	var p := AudioStreamPlayer.new()
	p.stream = hit_sound
	p.volume_db = -4.0
	p.pitch_scale = randf_range(0.92, 1.08)
	get_tree().current_scene.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
