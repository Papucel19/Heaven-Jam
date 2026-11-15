extends Marker2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.5
@export var max_enemies: int = 6

@onready var timer: Timer = $Timer

func _ready() -> void:
	print("Spawner ready. enemy_scene = ", enemy_scene)
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_spawn)
	timer.start()

func _spawn() -> void:
	if enemy_scene == null:
		print("Spawner: no enemy scene assigned!")
		return
	var count = get_tree().get_nodes_in_group("enemies").size()
	if count >= max_enemies:
		print("Spawner: at max enemies (", count, ")")
		return
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector2(randf_range(-6, 6), 0)
	print("Spawned ", enemy.name, " at ", enemy.global_position)
