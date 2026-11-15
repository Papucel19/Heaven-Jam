class_name SFX

static func play(node: Node, path: String = "", db: float = -4.0) -> void:
	if path == "":
		path = "res://AUDIO/enemy_die_pipe.wav" if Engine.get_meta("pipe_mode", false) else "res://AUDIO/enemy_die.wav"
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var stream = load(path)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.finished.connect(p.queue_free)
	node.get_tree().root.add_child(p)
	p.play()

# Bosses only take damage from head stomps (the player sets the "stomp" meta first).
static func stomp_ok(boss: Node) -> bool:
	if boss.has_meta("stomp"):
		boss.remove_meta("stomp")
		return true
	return false
