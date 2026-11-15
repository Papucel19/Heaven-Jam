extends Node

# Plays a different music loop for each scene. Registered as the autoload "Music",
# so it keeps playing when the scene changes.
const TRACKS := {
	"res://SCENES/control.tscn": "res://AUDIO/music_menu.ogg",
	"res://SCENES/GameStart.tscn": "res://AUDIO/music_menu.ogg",
	"res://SCENES/main.tscn": "res://AUDIO/music_level1.ogg",
	"res://SCENES/level2.tscn": "res://AUDIO/music_level2.ogg",
	"res://SCENES/ending.tscn": "res://AUDIO/music_menu.ogg",
}

var player := AudioStreamPlayer.new()
var current_track := ""
var current_scene_path := ""

func _ready() -> void:
	player.volume_db = -8.0
	add_child(player)
	# loop: start again when the track ends
	player.finished.connect(func():
		if player.stream:
			player.play()
	)

func _process(_delta: float) -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return

	var path: String = scene.scene_file_path
	if path == current_scene_path:
		return
	current_scene_path = path

	var track: String = TRACKS.get(path, "")
	if track == current_track:
		return   # same music keeps playing across scenes
	current_track = track

	if track == "" or not ResourceLoader.exists(track):
		player.stop()
		player.stream = null
		return

	player.stream = load(track)
	player.play()
