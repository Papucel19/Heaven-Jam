extends CharacterBody2D

class_name PLAYER

@onready var fireball_scene = preload("res://SCENES/fire_ball.tscn")
@onready var smash_hitbox_scene = $smash_hitbox/CollisionShape2D
@onready var player_idle_animation = $AnimatedSprite2D
@onready var health_gui = $"../ColorRect/Label"
@onready var score_label = $"../ColorRect2/score"
@onready var animation_smash1 =	$"../smash_animations"
@onready var animation_smash2 =$"../smash_animations2"

var smash_cooldown: Timer
var health = 12
var score = 0
var speed = 200
var gravity = 1700
var jump_power = -500
var deceleration = 3500
var fireball_cooldown: Timer
var damage_cooldown: Timer
var smashed = false
var was_on_floor = false
var bounce_sound := AudioStreamPlayer.new()
const BOUNCE_SOUND_PATH := "res://AUDIO/bounce.wav"

func _ready() -> void:
	
	if ResourceLoader.exists(BOUNCE_SOUND_PATH):
		bounce_sound.stream = load(BOUNCE_SOUND_PATH)
		bounce_sound.volume_db = -6.0
		add_child(bounce_sound)
	
	animation_smash1.visible = false
	animation_smash2.visible = false
	
	smash_hitbox_scene.disabled = true
	add_to_group("Player")
	
	smash_cooldown = Timer.new()
	smash_cooldown.wait_time = 3
	smash_cooldown.one_shot = true
	add_child(smash_cooldown)
	
	damage_cooldown = Timer.new()
	damage_cooldown.wait_time = 1
	damage_cooldown.one_shot = true
	add_child(damage_cooldown)
	
	var temp_fireball = fireball_scene.instantiate()
	fireball_cooldown = Timer.new()
	fireball_cooldown.wait_time = temp_fireball.cooldown
	fireball_cooldown.one_shot = true
	add_child(fireball_cooldown)
	temp_fireball.free()
	
func _physics_process(delta: float) -> void:
	health_gui.text = "Health: " + str(health)
	
	if smashed and is_on_floor():
		animation_smash1.visible = true
		animation_smash2.visible = true
		play_smash_animations()
		smashed = false
		smash_hitbox_scene.disabled = true
	
	if Input.is_action_just_pressed("smash_attack") and not is_on_floor() and smash_cooldown.is_stopped():
		smashed = true
		smash_hitbox_scene.disabled = false
		velocity.y += gravity
		smash_cooldown.start()
		
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var on_floor_now = is_on_floor()
	if on_floor_now and not was_on_floor and bounce_sound.stream:
		bounce_sound.play()
	was_on_floor = on_floor_now
	
	if is_on_floor():
		velocity.y = jump_power
	
	if Input.is_action_just_pressed("fireball_attack") and fireball_cooldown.is_stopped(): #FIREBALL ATTACK---
		player_idle_animation.play("atk")
		shoot_fireball()
		fireball_cooldown.start()
		await player_idle_animation.animation_finished
		player_idle_animation.play("default")
	
	var direction = Input.get_axis("move_left1", "move_right1")
	
	if direction:
		velocity.x = direction * speed
		if direction == -1:
			player_idle_animation.flip_h = true
		else:
			player_idle_animation.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		
	fall_vy = velocity.y
	move_and_slide()
	_check_stomps()

func take_damage(amount):
	if not damage_cooldown.is_stopped():
		return
		
	health -= amount
	if health <= 0:
		die()
		return
		
	damage_cooldown.start()
	start_flicker()

# Called by enemies. Returns true if the hit was a head-stomp
# (player falling onto the enemy from above): enemy takes damage, player bounces, no damage to player.
var fall_vy := 0.0

func _check_stomps() -> void:
	for e in get_tree().get_nodes_in_group("stompable"):
		if not is_instance_valid(e) or e.get("dead") == true:
			continue
		var hb = e.get("hitbox")
		if hb is Area2D and hb.overlaps_body(self):
			try_stomp(e, 1)

func try_stomp(enemy: Node2D, stomp_damage: int = 1) -> bool:
	if max(velocity.y, fall_vy) <= 0.0:
		return false
	if global_position.y >= enemy.global_position.y - 2.0:
		return false
	if enemy.has_method("take_damage") and enemy.get("stomp_immune") != true:
		enemy.set_meta("stomp", true)
		enemy.take_damage(stomp_damage)
		if is_instance_valid(enemy) and enemy.has_meta("stomp"):
			enemy.remove_meta("stomp")
	velocity.y = jump_power * 1.15
	return true

var dead_flag := false
func die() -> void:
	if dead_flag:
		return
	dead_flag = true
	set_physics_process(false)
	hide()
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 16)
	layer.add_child(box)
	var label := Label.new()
	label.text = "YOU LOSE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := load("res://ART/font/BoldPixels.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	box.add_child(label)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.pressed.connect(func():
		var t := get_tree()
		layer.queue_free()
		t.paused = false
		t.reload_current_scene())
	box.add_child(retry)
	var menu := Button.new()
	menu.text = "MENU"
	menu.pressed.connect(func():
		var t := get_tree()
		layer.queue_free()
		t.paused = false
		t.change_scene_to_file("res://SCENES/control.tscn"))
	box.add_child(menu)
	get_tree().root.add_child(layer)
	get_tree().paused = true
	retry.grab_focus()

func start_flicker() -> void:
	while not damage_cooldown.is_stopped():
		player_idle_animation.modulate = Color(10, 10, 10, 1)
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree():
			return
		player_idle_animation.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree():
			return
	player_idle_animation.modulate = Color.WHITE
	
func shoot_fireball():
	var fireball_instance = fireball_scene.instantiate()
	fireball_instance.global_position.y = self.global_position.y + 10
	fireball_instance.global_position.x = self.global_position.x
	get_parent().add_child(fireball_instance)

func _on_smash_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body is not PLAYER:
		body.take_damage(1)
		body.velocity.y -= 500
		
func play_smash_animations():
	var distance_to_travel = 50
	
	animation_smash1.global_position = self.global_position + Vector2(30, 10)
	animation_smash2.global_position = self.global_position + Vector2(-30, 10)
	animation_smash1.play("default")
	animation_smash2.play("default")
	await animation_smash1.animation_finished
	await animation_smash2.animation_finished
	animation_smash1.visible = false
	animation_smash2.visible = false
	
	
