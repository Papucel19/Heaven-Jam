extends Label

# 1. Update this path to match your exact clown .tscn file!
@onready var clown_scene = preload("res://SCENES/clown.tscn")

var clown_spawned: bool = false

var score: int = 0:
	set(value):
		score = value
		text = "SCORE: " + str(score)
		
		if score >= 10 and not clown_spawned and _is_level_one():
			spawn_clown()

func _ready() -> void:
	add_to_group("labels")
	text = "SCORE: " + str(score)

func _is_level_one() -> bool:
	var scene = get_tree().current_scene if is_inside_tree() else null
	return scene != null and scene.scene_file_path == "res://SCENES/main.tscn"

func spawn_clown() -> void:
	clown_spawned = true
	var clown = clown_scene.instantiate()
	
	# Spawn 200 pixels to the right of the player (and slightly above the floor)
	var player = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(player):
		clown.global_position = Vector2(150, 30)
		player.get_parent().add_child(clown)
	else:
		# Fallback position if the player isn't found
		clown.global_position = Vector2(300, 100)
		get_tree().current_scene.add_child(clown)
