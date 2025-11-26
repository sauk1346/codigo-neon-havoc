extends Area2D

var velocidad = 600
var direccion = Vector2.RIGHT
var homing_strength = 3.0  # Qué tan fuerte persigue al enemigo
var target = null

func _ready():
	z_index = 10  # Asegurar que las balas se dibujen por encima de todo
	monitoring = true
	monitorable = true

	# Reproducir sonido de disparo UNA vez al crear la bala
	if has_node("BulletSound"):
		$BulletSound.play()

func _process(delta):
	# Buscar el enemigo más cercano si no tenemos target
	if not is_instance_valid(target):
		var enemies = get_tree().get_nodes_in_group("enemy")
		if enemies.size() > 0:
			target = enemies[0]
			for enemy in enemies:
				if global_position.distance_to(enemy.global_position) < global_position.distance_to(target.global_position):
					target = enemy
					
	# Auto-dirigirse al enemigo si existe
	if is_instance_valid(target):
		var target_direction = (target.global_position - global_position).normalized()
		direccion = direccion.lerp(target_direction, homing_strength * delta).normalized()

	# Mover la bala
	position += direccion * velocidad * delta

	# Rotar sprite para que apunte en la dirección de movimiento
	rotation = direccion.angle()

	# Debug: verificar cuerpos cercanos
	var overlapping = get_overlapping_bodies()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)  # Resta 1 de vida al enemigo
		queue_free()  # La bala SIEMPRE se destruye al impactar
