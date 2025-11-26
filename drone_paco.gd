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

		# Voltear el sprite según la dirección horizontal
		if has_node("Sprite2D"):
			# Si el jugador está a la derecha (dirección.x positiva), voltear
			$Sprite2D.flip_h = direction.x > 0

		# Detectar colisión con el jugador
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()

			# Si chocamos con alguien del grupo "player"
			if collider.is_in_group("player"):
				if collider.has_method("take_damage"):
					collider.take_damage(damage)
