extends ProgressBar

@export var player: Node

func _ready():
	max_value = player.max_health
	value = player.current_health
	
	player.health_changed.connect(update_health_bar)

func update_health_bar(new_health):
	value = new_health
