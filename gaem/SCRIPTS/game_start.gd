extends Control

func _ready() -> void:
	Engine.set_meta("exit_requested", false)

	# silence any leftover sound players in this scene
	for node in find_children("*", "AudioStreamPlayer", true, false):
		node.stop()
		node.autoplay = false

	var start_button := find_child("Button_Start", true, false) as BaseButton
	var exit_button := find_child("Button_Exit", true, false) as BaseButton

	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	_setup_pipe_label()

var pipe_label: Label

func _setup_pipe_label() -> void:
	pipe_label = Label.new()
	pipe_label.position = Vector2(4, 164)
	pipe_label.add_theme_font_size_override("font_size", 8)
	var f := load("res://ART/font/BoldPixels.ttf")
	if f:
		pipe_label.add_theme_font_override("font", f)
	add_child(pipe_label)
	_refresh_pipe_label()

func _refresh_pipe_label() -> void:
	pipe_label.text = "[R] Metal pipe death sound: " + ("ON" if Engine.get_meta("pipe_mode", false) else "OFF")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		var on: bool = not Engine.get_meta("pipe_mode", false)
		Engine.set_meta("pipe_mode", on)
		_refresh_pipe_label()
		SFX.play(self)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://SCENES/main.tscn")

func _on_exit_pressed() -> void:
	Engine.set_meta("exit_requested", true)
	get_tree().change_scene_to_file("res://SCENES/exit.tscn")
