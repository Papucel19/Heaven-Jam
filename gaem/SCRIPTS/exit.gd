extends Node

# plays the scream if it exists, otherwise the normal exit sound
const SOUND_PATHS := ["res://AUDIO/scream.wav", "res://AUDIO/ExitSound.wav"]

func _ready() -> void:
	# stop any autoplaying players placed in this scene in the editor
	for node in find_children("*", "AudioStreamPlayer", true, false):
		node.stop()
		node.autoplay = false

	# only play if the Exit button was pressed
	if not Engine.get_meta("exit_requested", false):
		return

	var sound_path := ""
	for path in SOUND_PATHS:
		if ResourceLoader.exists(path):
			sound_path = path
			break

	if sound_path == "":
		print("No exit sound found in AUDIO/")
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return

	var player := AudioStreamPlayer.new()
	player.stream = load(sound_path)
	add_child(player)
	player.play()

	# golden flash at the same moment as the sound
	var flash := ColorRect.new()
	flash.color = Color(1, 0.85, 0.2)
	flash.size = Vector2(2000, 2000)
	flash.position = Vector2(-500, -500)
	add_child(flash)
	await get_tree().create_timer(0.08).timeout
	flash.queue_free()

	await get_tree().create_timer(player.stream.get_length()).timeout
	get_tree().quit()
