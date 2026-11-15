extends Node2D

# Ending: mom comes to the bouncy castle and takes the kid home.

const W := 320.0
const H := 180.0
const FLOOR_Y := 140.0

var kid: Node2D
var mom: Sprite2D
var say: Label
var font: Font

func _ready() -> void:
	font = load("res://ART/font/BoldPixels.ttf")
	_build_background()
	_build_kid()
	_build_mom()
	_build_ui()
	_run()

func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	add_child(r)

func _build_background() -> void:
	_rect(Vector2(0, 0), Vector2(W, H), Color(0.55, 0.78, 0.95))      # sky
	_rect(Vector2(0, FLOOR_Y), Vector2(W, H - FLOOR_Y), Color(0.36, 0.66, 0.3))   # grass
	# bouncy castle on the left
	_rect(Vector2(10, 78), Vector2(110, 62), Color(0.95, 0.45, 0.65))
	_rect(Vector2(10, 62), Vector2(22, 16), Color(0.98, 0.8, 0.25))
	_rect(Vector2(52, 62), Vector2(22, 16), Color(0.98, 0.8, 0.25))
	_rect(Vector2(98, 62), Vector2(22, 16), Color(0.98, 0.8, 0.25))
	_rect(Vector2(48, 100), Vector2(30, 40), Color(0.45, 0.25, 0.7))   # door
	# sun
	_rect(Vector2(270, 16), Vector2(24, 24), Color(1.0, 0.9, 0.3))

func _build_kid() -> void:
	kid = Node2D.new()
	kid.position = Vector2(200, FLOOR_Y)
	add_child(kid)
	var inst = load("res://SCENES/player.tscn").instantiate()
	var spr = inst.get_node_or_null("AnimatedSprite2D")
	if spr:
		inst.remove_child(spr)
		kid.add_child(spr)
		spr.position = Vector2(0, -14)
		spr.play()
	inst.free()

func _build_mom() -> void:
	mom = Sprite2D.new()
	mom.texture = load("res://ART/mom.png")
	mom.centered = false
	mom.offset = Vector2(-12, -30)
	mom.position = Vector2(-40, FLOOR_Y)
	add_child(mom)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	say = Label.new()
	say.position = Vector2(0, 8)
	say.size = Vector2(W, 40)
	say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say.add_theme_font_size_override("font_size", 12)
	say.add_theme_color_override("font_color", Color.WHITE)
	say.add_theme_color_override("font_outline_color", Color.BLACK)
	say.add_theme_constant_override("outline_size", 4)
	if font:
		say.add_theme_font_override("font", font)
	layer.add_child(say)

func _say(text: String) -> void:
	say.text = text

func _run() -> void:
	# kid keeps bouncing
	var b := create_tween().set_loops()
	b.tween_property(kid, "position:y", FLOOR_Y - 34, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	b.tween_property(kid, "position:y", FLOOR_Y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(1.2).timeout
	_say("You beat the Giant Rat!")
	await get_tree().create_timer(2.0).timeout

	# mom walks in
	_say("...")
	var walk := create_tween()
	walk.tween_property(mom, "position:x", 165.0, 2.2)
	var bob := create_tween().set_loops(6)
	bob.tween_property(mom, "position:y", FLOOR_Y - 2, 0.18)
	bob.tween_property(mom, "position:y", FLOOR_Y, 0.18)
	await walk.finished
	_say("MOM: That's enough bouncing for today!")
	await get_tree().create_timer(2.2).timeout
	_say("MOM: Time to go home, sweetheart.")
	await get_tree().create_timer(2.0).timeout

	# kid stops bouncing and gets picked up
	b.kill()
	var land := create_tween()
	land.tween_property(kid, "position", Vector2(mom.position.x + 14, FLOOR_Y - 20), 0.5)
	await land.finished
	_say("MOM: Let's get you some ice cream.")
	await get_tree().create_timer(1.8).timeout

	# walk off together to the right
	mom.flip_h = false
	var out := create_tween().set_parallel(true)
	out.tween_property(mom, "position:x", W + 40, 3.0)
	out.tween_property(kid, "position:x", W + 54, 3.0)
	await out.finished

	_say("")
	var end_label := Label.new()
	end_label.text = "THE END\nthanks for playing"
	end_label.position = Vector2(0, 60)
	end_label.size = Vector2(W, 60)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 16)
	end_label.add_theme_color_override("font_color", Color.BLACK)
	if font:
		end_label.add_theme_font_override("font", font)
	add_child(end_label)
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://SCENES/control.tscn")
