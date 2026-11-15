extends CharacterBody2D

class_name ENEMY

signal died(points: int)


@export var gravity: int = 1500
@export var hitbox: Area2D
@export var health: int = 14
@export var damage: int = 1
@export var head_offset_y: float = -60.0
@export var points:= 10



var speed: int = 100
var dash_speed: int = 360
var jump_force: int = -780
var friction: int = 900

@onready var sprite = $AnimatedSprite2D

enum State { IDLE, CHASE, DASH, JUMP_SLAM, KNOCKBACK, GOOFY_SPIN, TAUNT }
var current_state: State = State.IDLE

var player: PLAYER = null
var state_timer: Timer
var is_enraged: bool = false
var max_health: int
var dash_direction: float = 1.0
var health_label: Label
var taunt_label: Label

var goofy_lines = [
	"SKILL ISSUE",
	"TOO SLOW BRO",
	"LOL?",
	"MY GRANDMA HITS HARDER",
	"BRUH MOMENT",
	"NICE AIM",
	"IM BUILT DIFFERENT"
]

func _ready() -> void:
	add_to_group("stompable")
	max_health = health
	create_boss_health_ui()
	update_boss_ui()
	
	if not hitbox:
		for child in get_children():
			if child is Area2D:
				hitbox = child
				break
				
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		print(name + " has no Hitbox Area2D assigned!")
		
	player = get_tree().get_first_node_in_group("Player")
	
	state_timer = Timer.new()
	state_timer.one_shot = true
	state_timer.timeout.connect(_on_state_timer_timeout)
	add_child(state_timer)
	
	enter_idle(1.0)

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

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			return


	if not is_on_floor():
		if current_state == State.JUMP_SLAM and velocity.y > 0:
			velocity.y += (gravity * 2.2) * delta
		elif current_state == State.GOOFY_SPIN:
			velocity.y += (gravity * 0.3) * delta 
		else:
			velocity.y += gravity * delta

	var dir_to_player = sign(player.global_position.x - global_position.x)
	if dir_to_player == 0:
		dir_to_player = 1

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if sprite:
				sprite.flip_h = (dir_to_player < 0)
			
		State.CHASE:
			velocity.x = dir_to_player * speed
			if sprite:
				sprite.flip_h = (dir_to_player < 0)
				
		State.DASH:
			velocity.x = dash_direction * dash_speed
			
		State.JUMP_SLAM:
			if is_on_floor() and velocity.y >= 0:
				spawn_ground_shockwaves()
				enter_idle(1.1)
				
		State.KNOCKBACK:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			
		State.GOOFY_SPIN:
			if sprite:
				sprite.rotation += 25.0 * delta
			velocity.x = dir_to_player * (speed * 0.9)
			
		State.TAUNT:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if is_on_floor():
				velocity.y = -180 

	move_and_slide()

func enter_idle(duration: float) -> void:
	current_state = State.IDLE
	if sprite:
		sprite.rotation = 0 
	state_timer.start(duration * (0.7 if is_enraged else 1.0))

func _on_state_timer_timeout() -> void:
	if not is_instance_valid(player):
		return
		
	if current_state == State.IDLE:
		var roll = randf()
		if roll < 0.25:
			current_state = State.CHASE
			state_timer.start(1.3)
		elif roll < 0.50:
			start_dash_combo()
		elif roll < 0.72:
			start_jump_slam()
		elif roll < 0.84:
			start_goofy_spin()
		elif roll < 0.93:
			start_fakeout_sneeze()
		else:
			start_goofy_taunt()
	elif current_state == State.CHASE:
		enter_idle(0.9)

func start_dash_combo() -> void:
	var dashes = 3 if is_enraged else 2
	
	for i in range(dashes):
		if not is_inside_tree() or not is_instance_valid(player) or current_state == State.KNOCKBACK:
			return
			
		current_state = State.IDLE
		dash_direction = sign(player.global_position.x - global_position.x)
		if dash_direction == 0:
			dash_direction = 1
			
		if sprite:
			sprite.flip_h = (dash_direction < 0)
			modulate = Color(3, 0.3, 0.3)
			
		# Faster telegraph on follow-up dashes
		var windup = 0.45 if i == 0 else 0.25
		await get_tree().create_timer(windup).timeout
		if not is_inside_tree() or current_state == State.KNOCKBACK:
			return
			
		modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE
		current_state = State.DASH
		
		await get_tree().create_timer(0.4).timeout
		
	if is_inside_tree() and current_state != State.KNOCKBACK:
		enter_idle(1.1)

func start_jump_slam() -> void:
	if not is_on_floor():
		enter_idle(0.6)
		return
		
	var dir_to_player = sign(player.global_position.x - global_position.x)
	if sprite:
		sprite.flip_h = (dir_to_player < 0)
		
	show_taunt_text("INCOMING!!", 0.9)
	current_state = State.JUMP_SLAM
	velocity.y = jump_force
	velocity.x = dir_to_player * (speed * 2.0)

func spawn_ground_shockwaves() -> void:
	for dir in [-1, 1]:
		
		var wave = Area2D.new()
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		var visual = ColorRect.new()
		visual.size = Vector2(10, 50)
		visual.position = Vector2(-10, -30)
		visual.color = Color(1.0, 0.2, 0.2)
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

func start_goofy_spin() -> void:
	current_state = State.GOOFY_SPIN
	velocity.y = -320
	show_taunt_text("WEEEEEEEE!!", 1.5)
	
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
		
	if sprite:
		sprite.rotation = 0
	show_taunt_text("*dizzy*", 1.0)
	enter_idle(1.3)

func start_fakeout_sneeze() -> void:
	current_state = State.IDLE
	modulate = Color(4, 0.2, 0.2)
	show_taunt_text("GGRRRRR...", 0.75)
	
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree() or current_state == State.KNOCKBACK:
		return
		
	modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE
	show_taunt_text("achoo...", 1.0)
	
	var away_dir = -sign(player.global_position.x - global_position.x)
	if away_dir == 0:
		away_dir = 1
	velocity.y = -200
	velocity.x = away_dir * 120
	enter_idle(1.0)

func start_goofy_taunt() -> void:
	current_state = State.TAUNT
	show_taunt_text(goofy_lines.pick_random(), 1.3)
	
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree() and current_state == State.TAUNT:
		enter_idle(0.7)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is PLAYER:
		if body.has_method("try_stomp") and body.try_stomp(self, 1):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	update_boss_ui()
	
	if not is_enraged and health <= max_health / 2.0 and health > 0:
		enter_phase_two()
		
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree():
		modulate = Color(1.3, 0.7, 0.7) if is_enraged else Color.WHITE
		
	if health <= 0:
		SFX.play(self)
		queue_free()

func update_boss_ui() -> void:
	if is_instance_valid(health_label):
		health_label.text = "%d / %d" % [health, max_health]

func enter_phase_two() -> void:
	is_enraged = true
	speed = 135
	dash_speed = 440
	modulate = Color(1.3, 0.7, 0.7)
	show_taunt_text("OKAY NOW IM TRYING!!", 1.8)
	
	if is_instance_valid(health_label):
		health_label.modulate = Color(1, 0.3, 0.3)

func take_knockback(amount: int, attacker_direction) -> void:
	if sprite:
		sprite.rotation = 0
	current_state = State.KNOCKBACK
	velocity += amount * attacker_direction
	
	if is_on_floor():
		velocity.y = -150
		
	await get_tree().create_timer(0.25).timeout
	if is_inside_tree() and current_state == State.KNOCKBACK:
		enter_idle(0.6)
		
		
func die() -> void:
	print("die called, points: ", points)
	get_tree().call_group("score", "add_score", points)
	queue_free()
	
