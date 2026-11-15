extends ENEMY

# Level 1 boss: when the clown is defeated, the player is pulled up
# into the sky and teleported to level 2.
const NEXT_LEVEL := "res://SCENES/level2.tscn"
const PULL_HEIGHT := 260.0
const PULL_TIME := 1.4

var defeated := false

func take_damage(amount: int) -> void:
	if defeated:
		return
	if not SFX.stomp_ok(self):
		_stomp_hint()
		return

	# the hit that kills the clown
	if health - amount <= 0:
		defeated = true
		health = 0
		update_boss_ui()
		_defeat()
		return

	# every other hit works exactly like before (flash, phase two, health bar)
	super.take_damage(amount)

func _defeat() -> void:
	# stop and hide the clown instead of freeing it, so this function can keep running
	if state_timer:
		state_timer.stop()
	set_physics_process(false)
	visible = false
	collision_layer = 0
	collision_mask = 0
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	SFX.play(self)
	get_tree().call_group("score", "add_score", points)

	var scene = get_tree().current_scene

	# stop everything else that could hurt the player during the cutscene
	for rat in get_tree().get_nodes_in_group("enemies"):
		rat.queue_free()
	for spawner in scene.find_children("*", "Marker2D", true, false):
		spawner.process_mode = Node.PROCESS_MODE_DISABLED

	var player = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

		# light beam that pulls the player up
		var beam := ColorRect.new()
		beam.color = Color(1.0, 0.95, 0.6, 0.35)
		beam.size = Vector2(34, 700)
		beam.position = Vector2(player.global_position.x - 17, player.global_position.y - 650)
		scene.add_child(beam)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(player, "global_position:y", player.global_position.y - PULL_HEIGHT, PULL_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(player, "rotation", TAU * 3.0, PULL_TIME)
		await tween.finished

	# white flash, then teleport
	var layer := CanvasLayer.new()
	layer.layer = 100
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)
	scene.add_child(layer)

	var fade := create_tween()
	fade.tween_property(flash, "color:a", 1.0, 0.5)
	await fade.finished

	get_tree().change_scene_to_file(NEXT_LEVEL)

var _hint_t := 0
func _stomp_hint() -> void:
	if Time.get_ticks_msec() - _hint_t > 1500:
		_hint_t = Time.get_ticks_msec()
		show_taunt_text("Only stomps hurt me!", 1.0)
