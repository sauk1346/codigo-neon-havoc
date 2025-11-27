# Script de ayuda para calcular posiciones de sprites
# Ejecuta esto en Godot (Script Editor → Run) para ver las coordenadas

extends Node

func _ready():
	print("=== CALCULADORA DE COORDENADAS DE SPRITES ===")
	print()

	var sprite_width = 139
	var sprite_height = 136
	var sheet_width = 976
	var sheet_height = 1088

	# Primera fila (IDLE) - 4 frames centrados
	print("--- IDLE (Fila 0) ---")
	var idle_frames = 4
	var offset_x = (sheet_width - (idle_frames * sprite_width)) / 2
	for i in range(idle_frames):
		var x = offset_x + (i * sprite_width)
		var y = 0
		print("Frame %d: Rect2(%d, %d, %d, %d)" % [i, x, y, sprite_width, sprite_height])

	print()

	# Resto de filas (WALK) - 7 frames cada una
	var animations = [
		"WALK_DOWN",
		"WALK_UP",
		"WALK_LEFT",
		"WALK_RIGHT",
		"WALK_DOWN_LEFT",
		"WALK_DOWN_RIGHT",
		"WALK_UP_LEFT"
	]

	for row in range(7):
		print("--- %s (Fila %d) ---" % [animations[row], row + 1])
		var y = (row + 1) * sprite_height
		for col in range(7):
			var x = col * sprite_width
			print("Frame %d: Rect2(%d, %d, %d, %d)" % [col, x, y, sprite_width, sprite_height])
		print()

	print("=== COPIA ESTAS COORDENADAS PARA USARLAS EN GODOT ===")
