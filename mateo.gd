extends CharacterBody2D

@export var bala_scene: PackedScene
var speed = 250
var lives = 3  # 3 intentos

# Dash variables
var dash_speed = 800
var dash_duration = 0.4
var dash_cooldown = 0.8
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.RIGHT
var last_direction = Vector2.RIGHT

# Knockback variables
var knockback_velocity = Vector2.ZERO
var knockback_strength = 400
var knockback_decay = 10
var is_invulnerable = false
var invulnerability_time = 1.0

func _ready():
	update_health_display()

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Guardar última dirección válida para el dash
	if direction.length() > 0:
		last_direction = direction.normalized()

	# Detectar dash con barra espaciadora
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	# Aplicar knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)

	# Movimiento normal o dash + knockback
	if is_dashing:
		velocity = dash_direction * dash_speed + knockback_velocity
	else:
		velocity = direction * speed + knockback_velocity

	move_and_slide()

	# Limitar el movimiento del jugador a los límites de la pantalla
	position.x = clamp(position.x, 0, 2816)
	position.y = clamp(position.y, 0, 1536)

	# Control de animaciones
	var anim_sprite = $AnimatedSprite2D

	if is_dashing:
		# Animación de dash
		if dash_direction.x >= 0:
			anim_sprite.flip_h = false
			anim_sprite.play("dash_right")
		else:
			anim_sprite.flip_h = true
			anim_sprite.play("dash_right")
	elif direction.length() > 0:
		var new_anim = get_animation_from_direction(direction)
		if anim_sprite.animation != new_anim and not is_dashing:
			anim_sprite.play(new_anim)
	else:
		# Si está quieto, reproducir animación idle
		if anim_sprite.animation != "idle" and not is_dashing:
			anim_sprite.play("idle")

func start_dash():
	is_dashing = true
	can_dash = false
	dash_direction = last_direction

	# Duración del dash
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	# Cooldown del dash
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

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
		health_label.text = "Vidas: " + str(lives)

		# Cambiar color según las vidas
		if lives == 3:
			health_label.add_theme_color_override("font_color", Color(0, 1, 0))
		elif lives == 2:
			health_label.add_theme_color_override("font_color", Color(1, 1, 0))
		else:
			health_label.add_theme_color_override("font_color", Color(1, 0, 0))

	# Actualizar barra de vida (ahora representa vidas)
	if nivel and nivel.has_node("UI/HealthBar"):
		var health_bar = nivel.get_node("UI/HealthBar")
		health_bar.max_value = 3
		health_bar.value = lives

		# Cambiar color de la barra según las vidas
		var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
		if lives == 3:
			fill_style.bg_color = Color(0, 1, 0.5, 1)
			fill_style.border_color = Color(0.5, 1, 0.8, 1)
		elif lives == 2:
			fill_style.bg_color = Color(1, 1, 0, 1)
			fill_style.border_color = Color(1, 1, 0.5, 1)
		else:
			fill_style.bg_color = Color(1, 0, 0.2, 1)
			fill_style.border_color = Color(1, 0.5, 0.5, 1)
		health_bar.add_theme_stylebox_override("fill", fill_style)

# Para recibir daño con knockback
func take_damage(enemy_position: Vector2):
	if is_invulnerable:
		return

	lives -= 1
	update_health_display()

	# Calcular dirección del knockback (alejarse del enemigo)
	var knockback_dir = (global_position - enemy_position).normalized()
	knockback_velocity = knockback_dir * knockback_strength

	# Activar invulnerabilidad temporal
	is_invulnerable = true
	start_invulnerability_effect()

	if lives <= 0:
		die()

# Efecto visual de invulnerabilidad (parpadeo)
func start_invulnerability_effect():
	var tween = create_tween()
	var flashes = 6
	for i in range(flashes):
		tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 0.5), invulnerability_time / (flashes * 2))
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), invulnerability_time / (flashes * 2))

	await tween.finished
	is_invulnerable = false
	modulate = Color(1, 1, 1, 1)

# Función de muerte
func die():
	# Desactivar controles y disparo
	set_physics_process(false)
	if has_node("FireTimer"):
		$FireTimer.stop()

	# Feedback visual: fade a negro
	modulate = Color(0.3, 0.3, 0.3)

	# Esperar un momento antes de volver al menú
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://menu.tscn")
