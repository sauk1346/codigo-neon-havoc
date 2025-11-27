extends Node2D

# Arrastra el archivo DronePaco.tscn aquí en el Inspector
@export var enemy_scene: PackedScene

var kills = 0

func _ready():
	update_kills_display()

	# Configurar música de fondo aleatoria con loop
	if has_node("BackgroundMusic"):
		var music = $BackgroundMusic

		var bgm_tracks = [
			"res://bgm/bgm01.mp3",
			"res://bgm/bgm02.mp3",
			"res://bgm/bgm03.mp3",
			"res://bgm/bgm04.mp3"
		]

		# Seleccionar una pista aleatoria
		var random_index = randi() % bgm_tracks.size()
		var selected_track = bgm_tracks[random_index]

		# Cargar el audio stream
		var audio_stream = load(selected_track)
		if audio_stream:
			music.stream = audio_stream
			music.stream.loop = true
			music.play()

func add_kill():
	kills += 1
	update_kills_display()

func update_kills_display():
	if has_node("UI/KillsLabel"):
		$UI/KillsLabel.text = "Kills: " + str(kills)

func _on_spawner_timer_timeout():
	var enemy = enemy_scene.instantiate()
	# Spawn en los bordes del mapa (2816x1536)
	var spawn_side = randi() % 4 # 0=arriba, 1=abajo, 2=izquierda, 3=derecha
	var spawn_pos = Vector2.ZERO

	match spawn_side:
		0: # Arriba
			spawn_pos = Vector2(randf_range(50, 2766), randf_range(-50, 50))
		1: # Abajo
			spawn_pos = Vector2(randf_range(50, 2766), randf_range(1486, 1586))
		2: # Izquierda
			spawn_pos = Vector2(randf_range(-50, 50), randf_range(50, 1486))
		3: # Derecha
			spawn_pos = Vector2(randf_range(2766, 2866), randf_range(50, 1486))

	enemy.position = spawn_pos
	enemy.add_to_group("enemy")  # ¡CRÍTICO! Agregar al grupo "enemy"
	add_child(enemy)
