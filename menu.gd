extends Control

@onready var letters = $Letters
@onready var flicker_timer = $FlickerTimer

func _ready():
	letters.visible = true
	flicker_timer.start()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://select.tscn")

func _on_flicker_timer_timeout():
	letters.visible = !letters.visible

	# Variar el tiempo para efecto neón más orgánico
	flicker_timer.wait_time = randf_range(0.08, 0.3)
