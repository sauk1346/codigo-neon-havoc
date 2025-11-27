extends CharacterBody2D

@export var bala_scene: PackedScene
var speed = 250
var health = 100 # [NUEVO] Vida inicial

func _ready():
	update_health_display()

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# Limitar el movimiento del jugador a los límites de la pantalla
	position.x = clamp(position.x, 0, 2816)
	position.y = clamp(position.y, 0, 1536)

	# Control de animaciones con 8 direcciones
	var anim_sprite = $AnimatedSprite2D

	if direction.length() > 0:
		var new_anim = get_animation_from_direction(direction)
		if anim_sprite.animation != new_anim:
			anim_sprite.play(new_anim)
	else:
		# Si está quieto, reproducir animación idle
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")

func get_animation_from_direction(dir: Vector2) -> String:
	# Normalizar dirección y calcular ángulo
	var angle = dir.angle()
	var anim_sprite = $AnimatedSprite2D

	# Resetear flip
	anim_sprite.flip_h = false

	# Convertir ángulo a grados para facilitar lectura
	var degrees = rad_to_deg(angle)

	# Determinar animación basada en el ángulo (8 direcciones)
	# Right: -22.5 a 22.5 grados
	if degrees >= -22.5 and degrees < 22.5:
		return "walk_right"
	# Down-Right: 22.5 a 67.5 grados
	elif degrees >= 22.5 and degrees < 67.5:
		return "walk_down_right"
	# Down: 67.5 a 112.5 grados
	elif degrees >= 67.5 and degrees < 112.5:
		return "walk_down"
	# Down-Left: 112.5 a 157.5 grados
	elif degrees >= 112.5 and degrees < 157.5:
		return "walk_down_left"
	# Left: 157.5 a -157.5 grados (±180)
	elif degrees >= 157.5 or degrees < -157.5:
		return "walk_left"
	# Up-Left: -157.5 a -112.5 grados
	elif degrees >= -157.5 and degrees < -112.5:
		return "walk_up_left"
	# Up: -112.5 a -67.5 grados
	elif degrees >= -112.5 and degrees < -67.5:
		return "walk_up"
	# Up-Right: -67.5 a -22.5 grados
	else: # degrees >= -67.5 and degrees < -22.5
		# No tenemos walk_up_right, usamos walk_up_left volteado
		anim_sprite.flip_h = true
		return "walk_up_left"

func _on_fire_timer_timeout():
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	if enemies.size() > 0:
		var nearest = enemies[0]
		for enemy in enemies:
			if global_position.distance_to(enemy.global_position) < global_position.distance_to(nearest.global_position):
				nearest = enemy
		shoot(nearest.global_position)

func shoot(target_pos):
	if bala_scene:
		var b = bala_scene.instantiate()
		b.global_position = $Muzzle.global_position
		b.direccion = (target_pos - global_position).normalized()
		get_tree().root.add_child(b)

# Actualizar display de vida en UI
func update_health_display():
	var nivel = get_tree().get_first_node_in_group("nivel")
	if nivel and nivel.has_node("UI/HealthLabel"):
		var health_label = nivel.get_node("UI/HealthLabel")
		health_label.text = "HP: " + str(health)

		# Cambiar color según la vida
		if health > 70:
			health_label.add_theme_color_override("font_color", Color(0, 1, 0))
		elif health > 30:
			health_label.add_theme_color_override("font_color", Color(1, 1, 0))
		else:
			health_label.add_theme_color_override("font_color", Color(1, 0, 0))

# Para recibir daño
func take_damage(amount):
	health -= amount
	update_health_display()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if health <= 0:
		die()

# Función de muerte
func die():
	# Desactivar controles y disparo
	set_physics_process(false)
	if has_node("FireTimer"):
		$FireTimer.stop()

	# Feedback visual: fade a negro
	modulate = Color(0.3, 0.3, 0.3)

	# Esperar un momento antes de reiniciar
	await get_tree().create_timer(1.0).timeout
	# Usar cambio de escena explícito (más robusto que reload)
	get_tree().change_scene_to_file("res://nivel.tscn")
