extends Control

@onready var level1_highlight = $Level1Highlight
@onready var level2_highlight = $Level2Highlight
@onready var flicker_timer = $FlickerTimer

var selected_level = 1

func _ready():
	# Ambos visibles al inicio
	level1_highlight.visible = true
	level2_highlight.visible = true
	flicker_timer.start()

func _process(_delta):
	# Cambiar selección con flechas izquierda/derecha o arriba/abajo
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up"):
		selected_level = 1
		# Asegurar que ambos estén visibles al cambiar
		level1_highlight.visible = true
		level2_highlight.visible = true
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down"):
		selected_level = 2
		# Asegurar que ambos estén visibles al cambiar
		level1_highlight.visible = true
		level2_highlight.visible = true

	# Confirmar selección
	if Input.is_action_just_pressed("ui_accept"):
		if selected_level == 1:
			get_tree().change_scene_to_file("res://nivel.tscn")
		else:
			get_tree().change_scene_to_file("res://nivel2.tscn")

func _on_flicker_timer_timeout():
	# Solo parpadea el nivel seleccionado, el otro siempre visible
	if selected_level == 1:
		level1_highlight.visible = !level1_highlight.visible
		level2_highlight.visible = true
	else:
		level2_highlight.visible = !level2_highlight.visible
		level1_highlight.visible = true

	flicker_timer.wait_time = randf_range(0.08, 0.25)
