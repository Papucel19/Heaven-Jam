extends CharacterBody2D

class_name RAT_BOSS

@export var gravity: int = 1500
@export var hitbox: Area2D
@export var health: int = 30
@export var damage: int = 2
@export var head_offset_y: float = -60.0
@export var points := 25
@export var max_rats_alive: int = 8
@export var faces_right: bool = true
@export var rat_spawn_interval: float = 7.0 
@export var touch_damage_interval: float = 1.2 

var rat_scene: PackedScene = preload("res://SCENES/ratata.tscn")
var speed: int = 90
var charge_speed: int = 500
var friction: int = 900
var rat_cooldown: float = 1.7   
var touch_cooldown: float = 0.0

@onready var sprite = $AnimatedSprite2D

enum State { IDLE, CHASE, CHARGE, RAT_THROW, RAT_RAIN, STOMP, KNOCKBACK, SQUEAK }
var current_state: State = State.IDLE

var player: PLAYER = null
var state_timer: Timer
var is_enraged: bool = false
var max_health: int
var charge_direction: float = 1.0
var health_label: Label
var taunt_label: Label
var dead := false

var squeak_lines = [
	"SQUEAK!",
	"GET HIM, BOYS!",
	"RATS RULE",
	"CHEESE TAX",
	"YOU SMELL LIKE CAT",
	"SCURRY!"
]

func _ready() -> void:
	add_to_group("stompable")
	max_health = health
	create_boss_health_ui()
	update_boss_ui()

	if not hitbox:
		# search all descendants, not just direct children
		var found = find_children("*", "Area2D", true, false)
		if found.size() > 0:
			hitbox = found[0]

	if not hitbox:
		# no Area2D in the scene, so build one from the body's collision shape
		hitbox = Area2D.new()
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1   # your player is on layer 1
		var shapes = find_children("*", "CollisionShape2D", false, false)
		if shapes.size() > 0 and shapes[0].shape:
			var cs = CollisionShape2D.new()
			cs.shape = shapes[0].shape
			cs.position = shapes[0].position
			hitbox.add_child(cs)
		add_child(hitbox)
		print("RAT_BOSS: no Area2D found, created one in code")

	hitbox.body_entered.connect(_on_hitbox_body_entered)

	find_player()

	state_timer = Timer.new()
	state_timer.one_shot = true
	state_timer.timeout.connect(_on_state_timer_timeout)
	add_child(state_timer)

	enter_idle(1.0)

func find_player() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		# walk through the player, the hitbox Area2D still hurts
		add_collision_exception_with(player)
		player.add_collision_exception_with(self)

func create_boss_health_ui() -> void:
	health_label = Label.new()
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_outline_color", Color.BLACK)
	health_label.add_theme_constant_override("outline_size", 3)
	health_label.size = Vector2(200, 24)
	health_label.position = Vector2(-100, head_offset_y)
	add_child(health_label)

	taunt_label = Label.new()
	taunt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	taunt_label.add_theme_font_size_override("font_size", 12)
	taunt_label.add_theme_color_override("font_color", Color.YELLOW)
	taunt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	taunt_label.add_theme_constant_override("outline_size", 3)
	taunt_label.size = Vector2(240, 24)
	taunt_label.position = Vector2(-120, head_offset_y - 18)
	taunt_label.visible = false
	add_child(taunt_label)

func show_taunt_text(msg: String, duration: float = 1.4) -> void:
	if not is_instance_valid(taunt_label):
		return
	taunt_label.text = msg
	taunt_label.visible = true
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(taunt_label):
			taunt_label.visible = false
	)

func face(dir: float) -> void:
	if sprite and dir != 0:
		sprite.flip_h = (dir < 0) if faces_right else (dir > 0)

func _physics_process(delta: float) -> void:
	rat_cooldown -= delta
	touch_cooldown -= delta

	# keep hurting the player while they overlap the hitbox
	if touch_cooldown <= 0.0 and hitbox and not dead:
		for body in hitbox.get_overlapping_bodies():
			if body is PLAYER and body.has_method("take_damage"):
				if body.has_method("try_stomp") and body.try_stomp(self, 1):
					touch_cooldown = 0.4
					break
				body.take_damage(damage)
				touch_cooldown = touch_damage_interval
				break

	if not is_instance_valid(player):
		find_player()
		if not player:
			return

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir_to_player = sign(player.global_position.x - global_position.x)
	if dir_to_player == 0:
		dir_to_player = 1

	match current_state:
		State.IDLE, State.RAT_THROW, State.SQUEAK:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			face(dir_to_player)

		State.CHASE:
			velocity.x = dir_to_player * speed
			face(dir_to_player)

		State.CHARGE:
			velocity.x = charge_direction * charge_speed
			# slam into a wall = stunned
			if is_on_wall():
				enter_stunned()

		State.RAT_RAIN:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		State.STOMP:
			if is_on_floor() and velocity.y >= 0:
				spawn_ground_shockwaves()
				enter_idle(1.1)

		State.KNOCKBACK:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

func enter_idle(duration: float) -> void:
	current_state = State.IDLE
	modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE
	state_timer.start(duration * (0.7 if is_enraged else 1.0))

func enter_stunned() -> void:
	# brief vulnerable moment after hitting a wall
	velocity.x = -charge_direction * 120
	velocity.y = -200
	show_taunt_text("*ow*", 1.0)
	enter_idle(1.6)

func _on_state_timer_timeout() -> void:
	if not is_instance_valid(player):
		return

	if current_state == State.IDLE:
		var roll = randf()
		if rat_cooldown <= 0.0:
			# time for a rat attack, then reset the cooldown
			rat_cooldown = rat_spawn_interval * (0.6 if is_enraged else 1.0)
			if roll < 0.5:
				start_rat_throw()
			elif roll < 0.8:
				start_rat_rain()
			else:
				start_squeak()
		else:
			# no rats right now, use a body attack instead
			if roll < 0.35:
				current_state = State.CHASE
				state_timer.start(1.3)
			elif roll < 0.7:
				start_charge()
			else:
				start_stomp()
	elif current_state == State.CHASE:
		enter_idle(0.9)

# ---------- RAT SPAWNING ----------

func rats_alive() -> int:
	# only count rats this boss made, not rats from your Spawner
	return get_tree().get_nodes_in_group("boss_rats").size()

func spawn_rat(pos: Vector2, vel: Vector2) -> void:
	if rat_scene == null:
		print("RAT_BOSS: rat_scene failed to load!")
		return
	if rats_alive() >= max_rats_alive:
		print("RAT_BOSS: rat cap reached (", rats_alive(), ")")
		return
	var rat = rat_scene.instantiate()
	rat.add_to_group("boss_rats")
	get_parent().add_child(rat)
	rat.global_position = pos
	rat.velocity = vel
	# let the thrown rat keep its momentum for a moment
	if "acceleration" in rat:
		var old_accel = rat.acceleration
		rat.acceleration = 150
		get_tree().create_timer(0.7).timeout.connect(func():
			if is_instance_valid(rat):
				rat.acceleration = old_accel
		)

# ---------- ATTACKS ----------

func start_rat_throw() -> void:
	current_state = State.RAT_THROW
	modulate = Color(1.5, 1.2, 0.8)
	show_taunt_text("FETCH!", 0.8)

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or current_state != State.RAT_THROW:
		return

	var count = 5 if is_enraged else 3
	for i in range(count):
		if not is_inside_tree() or not is_instance_valid(player) or current_state != State.RAT_THROW:
			return
		var dx = player.global_position.x - global_position.x
		var vx = clamp(dx * randf_range(0.7, 1.3), -520, 520)
		var vy = -randf_range(380, 560)
		spawn_rat(global_position + Vector2(sign(dx) * 40, -50), Vector2(vx, vy))
		await get_tree().create_timer(0.3 if not is_enraged else 0.2).timeout

	if is_inside_tree() and current_state == State.RAT_THROW:
		enter_idle(1.2)

func start_rat_rain() -> void:
	current_state = State.RAT_RAIN
	modulate = Color(1.2, 1.2, 1.6)
	show_taunt_text("RAIN OF RATS!!", 1.2)

	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or current_state != State.RAT_RAIN:
		return

	var count = 7 if is_enraged else 5
	for i in range(count):
		if not is_inside_tree() or not is_instance_valid(player) or current_state != State.RAT_RAIN:
			return
		var spawn_pos = player.global_position + Vector2(randf_range(-260, 260), -360)
		spawn_rat(spawn_pos, Vector2(0, 0))
		await get_tree().create_timer(0.22).timeout

	if is_inside_tree() and current_state == State.RAT_RAIN:
		enter_idle(1.3)

func start_charge() -> void:
	var passes = 3 if is_enraged else 2

	for i in range(passes):
		if not is_inside_tree() or not is_instance_valid(player) or current_state == State.KNOCKBACK:
			return

		current_state = State.IDLE
		charge_direction = sign(player.global_position.x - global_position.x)
		if charge_direction == 0:
			charge_direction = 1
		face(charge_direction)
		modulate = Color(3, 0.3, 0.3)
		show_taunt_text("SKRRRR...", 0.5)

		var windup = 0.5 if i == 0 else 0.3
		await get_tree().create_timer(windup).timeout
		if not is_inside_tree() or current_state == State.KNOCKBACK:
			return

		modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE
		current_state = State.CHARGE

		await get_tree().create_timer(0.6).timeout
		if not is_inside_tree() or current_state == State.KNOCKBACK:
			return
		if current_state == State.IDLE:
			return # got stunned by a wall, stunned handler took over

	if is_inside_tree() and current_state == State.CHARGE:
		enter_idle(1.2)

func start_stomp() -> void:
	if not is_on_floor():
		enter_idle(0.6)
		return

	var dir_to_player = sign(player.global_position.x - global_position.x)
	face(dir_to_player)
	show_taunt_text("BIG RAT SMASH!", 0.9)
	current_state = State.STOMP
	velocity.y = -700
	velocity.x = dir_to_player * 160

func spawn_ground_shockwaves() -> void:
	for dir in [-1, 1]:
		var wave = Area2D.new()
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		var visual = ColorRect.new()
		visual.size = Vector2(10, 50)
		visual.position = Vector2(-10, -30)
		visual.color = Color(0.6, 0.45, 0.35)
		wave.add_child(visual)
		shape.size = Vector2(10, 50)
		col.shape = shape
		wave.add_child(col)

		wave.global_position = global_position + Vector2(dir * 20, 15)
		get_parent().add_child(wave)

		wave.body_entered.connect(func(body):
			if body is PLAYER and body.has_method("take_damage"):
				body.take_damage(1)
				wave.queue_free()
		)

		var tween = wave.create_tween()
		tween.tween_property(wave, "global_position:x", wave.global_position.x + (dir * 320), 1.1)
		tween.tween_callback(wave.queue_free)

func start_squeak() -> void:
	current_state = State.SQUEAK
	show_taunt_text(squeak_lines.pick_random(), 1.3)

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or current_state != State.SQUEAK:
		return
	# calls two helpers
	for i in range(2):
		spawn_rat(global_position + Vector2(randf_range(-60, 60), -40), Vector2(randf_range(-200, 200), -250))

	await get_tree().create_timer(0.7).timeout
	if is_inside_tree() and current_state == State.SQUEAK:
		enter_idle(0.7)

# ---------- DAMAGE / PHASES ----------

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is PLAYER:
		if body.has_method("try_stomp") and body.try_stomp(self, 1):
			touch_cooldown = 0.4
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
			touch_cooldown = touch_damage_interval

var _hint_t := 0
func take_damage(amount: int) -> void:
	if dead:
		return
	if not SFX.stomp_ok(self):
		if Time.get_ticks_msec() - _hint_t > 1500:
			_hint_t = Time.get_ticks_msec()
			show_taunt_text("Stomp my head!", 1.0)
		return
	health = max(health - amount, 0)
	update_boss_ui()

	if not is_enraged and health <= max_health / 2.0 and health > 0:
		enter_phase_two()

	if health <= 0:
		die()
		return

	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree() and not dead:
		modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE

func update_boss_ui() -> void:
	if is_instance_valid(health_label):
		health_label.text = "%d / %d" % [health, max_health]

func enter_phase_two() -> void:
	is_enraged = true
	speed = 115
	charge_speed = 480
	max_rats_alive = 12
	modulate = Color(1.3, 0.7, 0.7)
	show_taunt_text("THE WHOLE COLONY COMES!!", 1.8)

	if is_instance_valid(health_label):
		health_label.modulate = Color(1, 0.3, 0.3)

func take_knockback(amount: int, attacker_direction) -> void:
	# rat attacks can't be interrupted by knockback
	if current_state in [State.RAT_THROW, State.RAT_RAIN, State.SQUEAK]:
		return

	current_state = State.KNOCKBACK
	velocity += amount * attacker_direction

	if is_on_floor():
		velocity.y = -150

	await get_tree().create_timer(0.3).timeout
	if is_inside_tree() and current_state == State.KNOCKBACK:
		enter_idle(0.6)

func die() -> void:
	if dead:
		return
	dead = true
	SFX.play(self)
	get_tree().call_group("score", "add_score", points)
	_play_ending()

func _play_ending() -> void:
	set_physics_process(false)
	visible = false
	collision_layer = 0
	collision_mask = 0
	if hitbox:
		hitbox.set_deferred("monitoring", false)
	var tree := get_tree()
	for n in tree.get_nodes_in_group("enemies"):
		n.queue_free()
	for n in tree.get_nodes_in_group("boss_rats"):
		n.queue_free()
	for n in tree.current_scene.get_children():
		if n is Marker2D:
			n.process_mode = Node.PROCESS_MODE_DISABLED
	await tree.create_timer(1.5).timeout
	var layer := CanvasLayer.new()
	layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)
	tree.root.add_child(layer)
	var tw := layer.create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.8)
	await tw.finished
	tree.change_scene_to_file("res://SCENES/ending.tscn")
	await tree.process_frame
	await tree.process_frame
	layer.queue_free()
