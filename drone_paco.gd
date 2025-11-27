extends CharacterBody2D

var speed = 100
var damage = 10
var health = 3  
var player_ref = null

func _ready():
	player_ref = get_tree().get_first_node_in_group("player")
	
func take_damage(amount):
	health -= amount

	# Feedback visual: parpadeo rojo
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if health <= 0:
		# Notificar al nivel que el enemigo fue eliminado
		var nivel = get_tree().get_first_node_in_group("nivel")
		if nivel and nivel.has_method("add_kill"):
			nivel.add_kill()

		queue_free()

func _physics_process(delta):
	if player_ref:
		# Calcular dirección hacia el jugador
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Control de animaciones con 8 direcciones
		if has_node("AnimatedSprite2D"):
			var anim_sprite = $AnimatedSprite2D
			var new_anim = get_animation_from_direction(direction)
			if anim_sprite.animation != new_anim:
				anim_sprite.play(new_anim)

		# Detectar colisión con el jugador
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()

			# Si chocamos con alguien del grupo "player"
			if collider.is_in_group("player"):
				if collider.has_method("take_damage"):
					collider.take_damage(damage)

func get_animation_from_direction(dir: Vector2) -> String:
	# Normalizar dirección y calcular ángulo
	var angle = dir.angle()
	var anim_sprite = $AnimatedSprite2D

	# Resetear flip
	anim_sprite.flip_h = false

	# Convertir ángulo a grados
	var degrees = rad_to_deg(angle)

	# Determinar animación basada en el ángulo (8 direcciones)
	# Right: -22.5 a 22.5 grados
	if degrees >= -22.5 and degrees < 22.5:
		return "fly_right"
	# Down-Right: 22.5 a 67.5 grados
	elif degrees >= 22.5 and degrees < 67.5:
		return "fly_down_right"
	# Down: 67.5 a 112.5 grados
	elif degrees >= 67.5 and degrees < 112.5:
		return "fly_down"
	# Down-Left: 112.5 a 157.5 grados
	elif degrees >= 112.5 and degrees < 157.5:
		return "fly_down_left"
	# Left: 157.5 a -157.5 grados (±180)
	elif degrees >= 157.5 or degrees < -157.5:
		return "fly_left"
	# Up-Left: -157.5 a -112.5 grados
	elif degrees >= -157.5 and degrees < -112.5:
		return "fly_up_left"
	# Up: -112.5 a -67.5 grados
	elif degrees >= -112.5 and degrees < -67.5:
		return "fly_up"
	# Up-Right: -67.5 a -22.5 grados
	else:
		return "fly_up_right"
