 # Cuestionario - Neon Havoc Project
## 50 Preguntas y Respuestas sobre el Funcionamiento del Juego

---

## **SECCIÓN 1: NODOS Y ARQUITECTURA**

### **1. ¿Qué tipo de nodo base se utiliza para el jugador y los enemigos? ¿Por qué esta elección?**

**Respuesta:** Se utiliza `CharacterBody2D`. Este nodo es ideal para personajes que necesitan moverse y detectar colisiones con física personalizada. A diferencia de `RigidBody2D` (que usa física automática del motor), `CharacterBody2D` permite control total sobre el movimiento mediante `move_and_slide()`, perfecto para juegos de acción donde necesitas precisión absoluta en el movimiento y respuesta inmediata a los controles.

---

### **2. ¿Qué nodo se usa para las balas y por qué no se usa CharacterBody2D?**

**Respuesta:** Se usa `Area2D` para las balas. No se usa CharacterBody2D porque las balas no necesitan física de colisión compleja ni deslizamiento. `Area2D` es más liviano y eficiente para detectar superposiciones (overlap detection) sin resolver colisiones físicas. Solo necesitamos saber cuándo la bala toca un enemigo, no empujar objetos o deslizarse por superficies.

---

### **3. ¿Qué diferencia hay entre AnimatedSprite2D y Sprite2D en este proyecto?**

**Respuesta:**
- `Sprite2D`: Muestra una sola imagen estática o un frame específico de un spritesheet. Usado para elementos que no cambian (fondos estáticos).
- `AnimatedSprite2D`: Gestiona múltiples animaciones completas (idle, walk_down, walk_up, etc.) y cambia automáticamente entre frames. Incluye control de velocidad de reproducción (`speed`), loop automático, y cambio dinámico de animaciones con `.play("nombre_animacion")`. Se usa para el jugador y enemigos que tienen movimiento animado.

---

### **4. ¿Qué son los grupos en Godot y cómo se utilizan en este proyecto?**

**Respuesta:** Los grupos son etiquetas que permiten agrupar nodos lógicamente sin importar su posición en el árbol de escena. En el proyecto se usan:
- `"player"`: Para identificar al jugador, usado por enemigos para encontrarlo
- `"enemy"`: Para identificar enemigos, usado por el sistema de disparo automático y las balas
- `"nivel"`: Para identificar el nodo del nivel, usado para actualizar el UI

Se accede con `get_tree().get_nodes_in_group("enemy")` para buscar todos los nodos con esa etiqueta, y con `is_in_group("player")` para verificar pertenencia.

---

### **5. ¿Qué es un PackedScene y cómo se usa en el sistema de spawn?**

**Respuesta:** `PackedScene` es un recurso que contiene una escena completa serializada (con nodos, propiedades, conexiones de señales y scripts). Se usa como "molde" para crear instancias:
```gdscript
@export var enemy_scene: PackedScene  # Referencia al archivo .tscn
var enemy = enemy_scene.instantiate()  # Crear copia independiente
enemy.position = spawn_pos
add_child(enemy)  # Agregar al árbol de nodos
```
Permite crear múltiples enemigos a partir de la misma definición sin duplicar datos.

---

## **SECCIÓN 2: ALGORITMOS DE MOVIMIENTO**

### **6. ¿Cómo funciona Input.get_vector() en el movimiento del jugador?**

**Respuesta:** `Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")` lee el estado de múltiples teclas simultáneamente y retorna un `Vector2` que representa la dirección resultante:
- Si presionas solo →: retorna Vector2(1, 0)
- Si presionas ↑ y →: retorna Vector2(0.707, -0.707) (diagonal normalizada automáticamente)
- Si no presionas nada: retorna Vector2(0, 0)
- Si presionas ← y →: se cancelan, retorna Vector2(0, 0)

La normalización automática evita que el movimiento diagonal sea más rápido.

---

### **7. ¿Qué hace move_and_slide() y por qué no usar position += velocity?**

**Respuesta:** `move_and_slide()` es un método de CharacterBody2D que:
1. Mueve al personaje según la velocidad definida
2. Detecta colisiones con otros cuerpos
3. Resuelve colisiones deslizándose por superficies (sliding)
4. Actualiza automáticamente la velocidad después de colisiones

`position += velocity * delta` ignora totalmente las colisiones, haciendo que el personaje atraviese paredes. `move_and_slide()` maneja automáticamente la física de colisiones de manera eficiente.

---

### **8. ¿Cómo funciona el algoritmo de detección de 8 direcciones?**

**Respuesta:** El algoritmo divide el círculo (360°) en 8 sectores de 45° cada uno:
```gdscript
var angle = direction.angle()  # Obtener ángulo en radianes
var degrees = rad_to_deg(angle)  # Convertir a grados (-180 a 180)

if degrees >= -22.5 and degrees < 22.5:
    return "walk_right"  # Sector derecha
elif degrees >= 22.5 and degrees < 67.5:
    return "walk_down_right"  # Sector diagonal abajo-derecha
# ... y así para las 8 direcciones
```

Cada sector de 45° corresponde a una animación específica. El centro de cada sector está en múltiplos de 45° (0°, 45°, 90°, 135°, etc.).

---

### **9. ¿Por qué se usa normalized() en los vectores de dirección?**

**Respuesta:** `normalized()` convierte cualquier vector a longitud 1.0 manteniendo su dirección. Esto es crucial porque:
- Vector2(1, 0) tiene magnitud 1.0
- Vector2(1, 1) sin normalizar tiene magnitud √2 ≈ 1.41
- Vector2(1, 1).normalized() = Vector2(0.707, 0.707) con magnitud 1.0

Sin normalizar, el personaje se movería 41% más rápido en diagonal. La normalización garantiza velocidad constante en todas direcciones. Se calcula como: `vector / vector.length()`.

---

### **10. ¿Cómo funciona la función clamp() para limitar el movimiento?**

**Respuesta:** `clamp(value, min, max)` restringe un valor entre un mínimo y máximo:
```gdscript
position.x = clamp(position.x, 0, 2816)
```
- Si `position.x < 0`, se fuerza a 0
- Si `position.x > 2816`, se fuerza a 2816
- Si está entre 0 y 2816, se mantiene sin cambios

Es equivalente a: `max(0, min(position.x, 2816))`. Crea "paredes invisibles" en los bordes del mapa sin usar nodos de colisión.

---

## **SECCIÓN 3: SISTEMA DE COMBATE**

### **11. ¿Cómo funciona el algoritmo de búsqueda del enemigo más cercano?**

**Respuesta:** Usa un algoritmo de búsqueda lineal comparando distancias:
```gdscript
var nearest = enemies[0]  # Asumir el primero como el más cercano
for enemy in enemies:
    var dist_to_current = global_position.distance_to(enemy.global_position)
    var dist_to_nearest = global_position.distance_to(nearest.global_position)
    if dist_to_current < dist_to_nearest:
        nearest = enemy
```

Complejidad: O(n) donde n es el número de enemigos. `distance_to()` calcula la distancia euclidiana: `sqrt((x2-x1)² + (y2-y1)²)`.

---

### **12. ¿Qué es un "homing missile" y cómo está implementado?**

**Respuesta:** Es un proyectil que persigue automáticamente a su objetivo. La implementación usa interpolación lineal (lerp):
```gdscript
# Calcular dirección hacia el objetivo
var target_direction = (target.global_position - global_position).normalized()

# Interpolar suavemente desde dirección actual hacia el objetivo
direccion = direccion.lerp(target_direction, homing_strength * delta).normalized()
```

`lerp(a, b, weight)` calcula: `a + (b - a) * weight`. Con `homing_strength = 3.0` y `delta = 0.016`, el proyectil gira ~4.8% hacia el objetivo cada frame, creando un movimiento curvo de persecución.

---

### **13. ¿Cómo se detectan colisiones entre balas y enemigos?**

**Respuesta:** El nodo `Area2D` de la bala tiene habilitado `monitoring = true`, permitiéndole detectar cuando entra en contacto con otros cuerpos. La señal `body_entered` se conecta al método:
```gdscript
func _on_body_entered(body):
    if body.is_in_group("enemy"):  # Verificar que es enemigo
        if body.has_method("take_damage"):  # Verificar que tiene el método
            body.take_damage(1)  # Causar daño
        queue_free()  # Destruir bala
```

`has_method()` previene errores si el cuerpo no tiene la función de daño.

---

### **14. ¿Cómo funciona el sistema de daño visual (feedback)?**

**Respuesta:** Usa la propiedad `modulate` para tintear temporalmente el sprite:
```gdscript
modulate = Color(1, 0.3, 0.3)  # Tinte rojo (R=100%, G=30%, B=30%)
await get_tree().create_timer(0.1).timeout  # Esperar 100ms
modulate = Color(1, 1, 1)  # Restaurar color normal
```

`modulate` multiplica el color de cada pixel del sprite. Color(1, 0.3, 0.3) reduce los canales verde y azul al 30%, dejando el rojo al 100%, creando un "flash" rojo que indica daño recibido.

---

### **15. ¿Cómo funciona el contador de kills y su actualización?**

**Respuesta:** El enemigo notifica al nivel cuando muere:
```gdscript
# En drone_paco.gd cuando health <= 0:
var nivel = get_tree().get_first_node_in_group("nivel")
if nivel and nivel.has_method("add_kill"):
    nivel.add_kill()

# En nivel.gd:
func add_kill():
    kills += 1
    update_kills_display()

func update_kills_display():
    $UI/KillsLabel.text = "Kills: " + str(kills)
```

Usa el patrón de comunicación mediante grupos y verificación de métodos para desacoplar enemigos del nivel.

---

## **SECCIÓN 4: ANIMACIONES Y SPRITES**

### **16. ¿Qué es un AtlasTexture y cómo funciona?**

**Respuesta:** `AtlasTexture` define una región rectangular dentro de una imagen grande (spritesheet):
```gdscript
[sub_resource type="AtlasTexture" id="AtlasTexture_walk_down_0"]
atlas = ExtResource("1_sprite")  # La imagen completa
region = Rect2(140, 128, 139, 136)  # X, Y, Width, Height
```

Permite:
- Tener múltiples sprites en un solo archivo PNG
- Reducir llamadas de carga (1 archivo vs 100)
- Mejorar rendimiento de GPU (1 textura en VRAM)
- Facilitar organización (sprites relacionados juntos)

La GPU solo renderiza la región especificada, no toda la imagen.

---

### **17. ¿Cómo se organiza un SpriteFrames para múltiples animaciones?**

**Respuesta:** `SpriteFrames` es un recurso que contiene múltiples animaciones, cada una con su propia lista de frames:
```gdscript
animations = [{
    "name": &"idle",
    "frames": [AtlasTexture_idle_0, AtlasTexture_idle_1, ...],
    "speed": 8.0,  # FPS
    "loop": true
}, {
    "name": &"walk_down",
    "frames": [AtlasTexture_walk_down_0, ...],
    "speed": 10.0,
    "loop": true
}]
```

AnimatedSprite2D usa esto para cambiar entre animaciones con `.play("walk_down")`.

---

### **18. ¿Cómo funciona el cambio dinámico de animaciones según movimiento?**

**Respuesta:** En cada frame (`_physics_process`):
```gdscript
if direction.length() > 0:  # Si hay movimiento
    var new_anim = get_animation_from_direction(direction)
    if anim_sprite.animation != new_anim:  # Solo cambiar si es diferente
        anim_sprite.play(new_anim)
else:  # Sin movimiento
    if anim_sprite.animation != "idle":
        anim_sprite.play("idle")
```

La verificación `if anim_sprite.animation != new_anim` evita reiniciar la animación en cada frame, permitiendo que se reproduzca suavemente.

---

### **19. ¿Qué hace la propiedad flip_h y cuándo se usa?**

**Respuesta:** `flip_h` (flip horizontal) refleja el sprite horizontalmente sin cambiar su posición. Se usa para reutilizar animaciones:
```gdscript
# En lugar de crear walk_up_right:
if moving_up_right:
    anim_sprite.flip_h = true
    anim_sprite.play("walk_up_left")  # Reutilizar walk_up_left reflejado
```

Reduce a la mitad la cantidad de sprites necesarios para direcciones simétricas. Es más eficiente que duplicar sprites en memoria.

---

### **20. ¿Cómo se calcula la rotación del sprite de la bala según su dirección?**

**Respuesta:**
```gdscript
rotation = direccion.angle()
```

`Vector2.angle()` retorna el ángulo en radianes del vector respecto al eje X positivo:
- Vector2(1, 0).angle() = 0 (derecha)
- Vector2(0, 1).angle() = π/2 ≈ 1.57 (abajo)
- Vector2(-1, 0).angle() = π ≈ 3.14 (izquierda)
- Vector2(0, -1).angle() = -π/2 ≈ -1.57 (arriba)

La propiedad `rotation` acepta radianes directamente.

---

## **SECCIÓN 5: SISTEMA DE AUDIO**

### **21. ¿Cómo funciona la selección aleatoria de música de fondo?**

**Respuesta:**
```gdscript
var bgm_tracks = [
    "res://bgm/bgm01.mp3",
    "res://bgm/bgm02.mp3",
    "res://bgm/bgm03.mp3",
    "res://bgm/bgm04.mp3"
]
var random_index = randi() % bgm_tracks.size()  # 0 a 3
var selected_track = bgm_tracks[random_index]
var audio_stream = load(selected_track)
music.stream = audio_stream
music.stream.loop = true
music.play()
```

`randi()` genera un entero aleatorio. El operador módulo `%` limita el rango: `randi() % 4` produce 0, 1, 2 o 3.

---

### **22. ¿Qué diferencia hay entre AudioStreamPlayer y AudioStreamPlayer2D?**

**Respuesta:**
- `AudioStreamPlayer`: Audio sin posición espacial, mismo volumen en todo el nivel. Ideal para música de fondo y UI sounds.
- `AudioStreamPlayer2D`: Audio posicional, el volumen disminuye con la distancia. Ideal para efectos de sonido de personajes y objetos del mundo.

En el proyecto se usa `AudioStreamPlayer` para BGM (música omnipresente) y probablemente `AudioStreamPlayer2D` para el sonido de disparo de balas.

---

### **23. ¿Cómo funciona el loop de audio en los archivos .import?**

**Respuesta:** En archivos `.mp3.import`:
```ini
[params]
loop=true
loop_offset=0
```

- `loop=true`: El audio se reproduce infinitamente
- `loop_offset=0`: Al reiniciar, vuelve al segundo 0 (sin offset)

Godot lee estos parámetros al importar el audio y configura el `AudioStreamMP3` automáticamente. Sin `loop=true`, la música se detendría al terminar.

---

### **24. ¿Por qué el sonido de bala se reproduce en _ready() y no en _process()?**

**Respuesta:**
```gdscript
func _ready():
    if has_node("BulletSound"):
        $BulletSound.play()
```

`_ready()` se llama UNA VEZ cuando la bala se instancia. `_process()` se llama cada frame (~60 veces por segundo). Si se pusiera en `_process()`, el sonido se reproduciría 60 veces por segundo simultáneamente, creando un ruido horrible y saturando el sistema de audio.

---

### **25. ¿Qué hace la propiedad volume_db y cómo funciona?**

**Respuesta:** `volume_db` controla el volumen en decibelios (dB):
- 0 dB = volumen original (100%)
- -6 dB ≈ 50% de volumen
- -12 dB ≈ 25% de volumen
- -∞ dB = silencio (0%)

La escala es logarítmica porque el oído humano percibe el volumen logarítmicamente. Cada -6 dB reduce el volumen percibido a la mitad. En el proyecto: `volume_db = -5.0` reduce ligeramente el volumen de la música.

---

## **SECCIÓN 6: INTERFAZ DE USUARIO**

### **26. ¿Qué es un CanvasLayer y por qué se usa para el UI?**

**Respuesta:** `CanvasLayer` es un nodo que renderiza sus hijos en una capa separada, independiente de la cámara del juego. Beneficios:
- El UI no se mueve aunque la cámara se mueva
- El UI siempre está visible sin importar el zoom
- Se puede controlar el orden de renderizado (z-index de capas)

Sin CanvasLayer, el UI se movería con la cámara o quedaría fijo en el mundo del juego.

---

### **27. ¿Cómo se actualiza dinámicamente el color del texto de vida?**

**Respuesta:**
```gdscript
if health > 70:
    health_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Verde
elif health > 30:
    health_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo
else:
    health_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Rojo
```

`add_theme_color_override()` sobrescribe temporalmente el color del theme sin modificar el theme global. Permite feedback visual inmediato del estado del jugador: verde (saludable), amarillo (herido), rojo (crítico).

---

### **28. ¿Cómo se comunica el jugador con el UI para actualizar la vida?**

**Respuesta:** El jugador busca el nodo del nivel mediante grupos:
```gdscript
func update_health_display():
    var nivel = get_tree().get_first_node_in_group("nivel")
    if nivel and nivel.has_node("UI/HealthLabel"):
        var health_label = nivel.get_node("UI/HealthLabel")
        health_label.text = "HP: " + str(health)
```

Usa:
1. `get_tree().get_first_node_in_group("nivel")`: Encontrar el nivel
2. `has_node("UI/HealthLabel")`: Verificar que existe el nodo
3. `get_node("UI/HealthLabel")`: Obtener referencia
4. Modificar directamente el texto

Esto desacopla el jugador del UI específico.

---

### **29. ¿Qué hace theme_override_constants/outline_size?**

**Respuesta:** Crea un borde alrededor del texto para mejorar legibilidad:
```gdscript
theme_override_colors/font_outline_color = Color(0, 0, 0)  # Negro
theme_override_constants/outline_size = 4  # 4 pixels
```

El borde negro de 4 píxeles hace que el texto blanco sea legible sobre cualquier fondo. Sin outline, el texto blanco sobre fondo claro sería invisible. El outline se renderiza en todos los lados del texto.

---

### **30. ¿Cómo funciona la conversión de números a texto en el UI?**

**Respuesta:**
```gdscript
health_label.text = "HP: " + str(health)
kills_label.text = "Kills: " + str(kills)
```

`str()` convierte cualquier tipo de dato a String:
- `str(100)` → `"100"`
- `str(3.14)` → `"3.14"`
- `str(Vector2(1, 2))` → `"(1, 2)"`

El operador `+` concatena strings. Labels solo aceptan String, no int/float directamente.

---

## **SECCIÓN 7: GESTIÓN DE ESCENAS Y NODOS**

### **31. ¿Qué hace queue_free() y cuándo usarlo vs free()?**

**Respuesta:**
- `queue_free()`: Marca el nodo para eliminación segura al final del frame actual. La eliminación se pospone.
- `free()`: Elimina el nodo inmediatamente.

**Siempre usar `queue_free()`** porque:
```gdscript
# PELIGRO con free():
func _on_body_entered(body):
    body.free()  # Elimina inmediatamente
    body.position = Vector2(0, 0)  # ERROR: body ya no existe
```

`queue_free()` permite que el frame termine procesando antes de eliminar, evitando errores de referencia nula.

---

### **32. ¿Qué diferencia hay entre add_child() y get_tree().root.add_child()?**

**Respuesta:**
- `add_child(bala)`: Agrega como hijo del nodo actual. Si el padre se destruye, todos sus hijos también.
- `get_tree().root.add_child(bala)`: Agrega directamente a la raíz del SceneTree. El nodo persiste independientemente.

En el proyecto, las balas se agregan a la raíz:
```gdscript
get_tree().root.add_child(b)
```

Así las balas continúan existiendo incluso si el jugador muere, permitiendo ver sus proyectiles terminar su trayectoria.

---

### **33. ¿Cómo funciona get_tree().change_scene_to_file()?**

**Respuesta:**
```gdscript
get_tree().change_scene_to_file("res://nivel.tscn")
```

1. Marca todos los nodos actuales para eliminación con `queue_free()`
2. Carga la nueva escena desde el archivo
3. Instancia la escena cargada
4. Agrega la nueva escena como hijo de la raíz
5. Todo ocurre entre frames para evitar glitches visuales

Es más robusto que `get_tree().reload_current_scene()` porque especifica explícitamente la escena objetivo.

---

### **34. ¿Qué hace is_instance_valid() en el sistema de homing?**

**Respuesta:**
```gdscript
if not is_instance_valid(target):
    # Buscar nuevo objetivo
```

Verifica que la referencia apunte a un objeto que aún existe en memoria. Previene errores cuando:
- El enemigo objetivo fue eliminado
- El enemigo llamó a `queue_free()`
- La referencia es `null`

Sin esto, intentar acceder a `target.global_position` causaría error fatal si el enemigo ya fue destruido.

---

### **35. ¿Cómo funciona el sistema de señales con _on_spawner_timer_timeout()?**

**Respuesta:** En `nivel.tscn`:
```gdscript
[connection signal="timeout" from="SpawnerTimer" to="." method="_on_spawner_timer_timeout"]
```

Cuando el Timer termina su cuenta:
1. El nodo Timer emite la señal `timeout`
2. El sistema de señales busca conexiones registradas
3. Llama al método `_on_spawner_timer_timeout()` del nodo padre
4. El Timer automáticamente reinicia (si `autostart=true`)

Las señales permiten comunicación desacoplada entre nodos.

---

## **SECCIÓN 8: FÍSICA Y COLISIONES**

### **36. ¿Qué son las collision layers y masks?**

**Respuesta:**
- `collision_layer`: En qué capas existe este nodo (qué es)
- `collision_mask`: Qué capas puede detectar (con qué colisiona)

En el proyecto:
```gdscript
# Jugador:
collision_layer = 1 (capa 1)
collision_mask = 2 (detecta capa 2)

# Enemigo:
collision_layer = 2 (capa 2)
collision_mask = 1 (detecta capa 1)
```

El jugador está en capa 1 y detecta capa 2 (enemigos). Los enemigos están en capa 2 y detectan capa 1 (jugador). Así se detectan mutuamente.

---

### **37. ¿Cómo funciona get_slide_collision_count()?**

**Respuesta:** Después de `move_and_slide()`, retorna el número de colisiones que ocurrieron durante el movimiento:
```gdscript
move_and_slide()
for i in get_slide_collision_count():  # Iterar cada colisión
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
    # Procesar colisión
```

Permite detectar múltiples colisiones simultáneas (ej: enemigo choca con jugador y pared al mismo tiempo). `get_slide_collision(i)` retorna un objeto `KinematicCollision2D` con datos de la colisión.

---

### **38. ¿Qué información contiene un objeto KinematicCollision2D?**

**Respuesta:** Contiene datos sobre una colisión:
```gdscript
var collision = get_slide_collision(i)
collision.get_collider()  # El nodo con el que chocó
collision.get_position()  # Punto exacto de contacto
collision.get_normal()    # Vector perpendicular a la superficie
collision.get_travel()    # Distancia recorrida antes de colisión
collision.get_remainder() # Distancia que faltó recorrer
```

Usado para determinar con qué chocó el enemigo y ejecutar lógica específica (ej: dañar jugador).

---

### **39. ¿Cómo funciona el sistema de áreas (Area2D) para las balas?**

**Respuesta:** `Area2D` no resuelve colisiones físicas, solo detecta superposiciones:
```gdscript
# Configuración:
monitoring = true  # Detectar otros cuerpos/áreas
monitorable = true  # Ser detectado por otros

# Señales:
body_entered(body)  # Cuando un PhysicsBody2D entra
body_exited(body)   # Cuando un PhysicsBody2D sale
area_entered(area)  # Cuando otra Area2D entra
```

La bala usa `body_entered` para detectar cuando toca un enemigo, sin empujarlo físicamente.

---

### **40. ¿Qué hace z_index y por qué las balas tienen z_index = 10?**

**Respuesta:** `z_index` controla el orden de renderizado (qué se dibuja encima):
- Valores más altos se dibujan encima de valores más bajos
- Valor por defecto: 0

En el proyecto:
```gdscript
# Balas:
z_index = 10  # Dibujadas encima de todo

# Jugador y enemigos:
z_index = 5   # Encima del fondo

# Fondo:
z_index = 0   # Atrás de todo
```

Asegura que las balas siempre sean visibles sobre personajes y fondo.

---

## **SECCIÓN 9: TIMERS Y TEMPORIZACIÓN**

### **41. ¿Cómo funciona un nodo Timer con autostart?**

**Respuesta:**
```gdscript
[node name="SpawnerTimer" type="Timer" parent="."]
wait_time = 2.0
autostart = true
```

1. Al entrar a la escena, el Timer inicia automáticamente
2. Cuenta regresiva desde `wait_time` (2 segundos)
3. Al llegar a 0, emite señal `timeout`
4. Si `one_shot = false` (default), se reinicia automáticamente
5. Repite infinitamente

Crea un spawner que genera enemigos cada 2 segundos sin código adicional.

---

### **42. ¿Qué hace await get_tree().create_timer()?**

**Respuesta:**
```gdscript
await get_tree().create_timer(0.1).timeout
```

1. `get_tree().create_timer(0.1)`: Crea un Timer temporal de 0.1 segundos
2. `.timeout`: Referencia a la señal timeout del Timer
3. `await`: Pausa la ejecución de la función hasta que la señal se emita

Efecto: Espera 0.1 segundos antes de continuar. Es como un `sleep()` pero asíncrono (no bloquea el motor). Usado para el efecto de daño visual que dura 0.1 segundos.

---

### **43. ¿Cuál es la diferencia entre Timer y await create_timer()?**

**Respuesta:**
- **Nodo Timer**: Permanente, reutilizable, visible en el editor, configurable en Inspector
  ```gdscript
  $FireTimer.start()
  $FireTimer.stop()
  ```

- **create_timer()**: Temporal, se destruye después de usarse, creado en código
  ```gdscript
  await get_tree().create_timer(1.0).timeout
  ```

Usa nodo Timer para eventos recurrentes (spawn, disparo automático). Usa create_timer() para pausas únicas (animaciones, efectos temporales).

---

### **44. ¿Cómo funciona el Timer de disparo automático del jugador?**

**Respuesta:**
```gdscript
[node name="FireTimer" type="Timer" parent="."]
autostart = true

func _on_fire_timer_timeout():
    var enemies = get_tree().get_nodes_in_group("enemy")
    if enemies.size() > 0:
        var nearest = find_nearest(enemies)
        shoot(nearest.global_position)
```

1. Timer se inicia automáticamente al crear el jugador
2. Cada X segundos (configurado en Inspector), llama a `_on_fire_timer_timeout()`
3. Busca enemigos vivos
4. Encuentra el más cercano
5. Dispara hacia él
6. Timer se reinicia automáticamente

Crea un sistema de auto-aim sin intervención manual.

---

### **45. ¿Qué hace set_physics_process(false) al morir?**

**Respuesta:**
```gdscript
func die():
    set_physics_process(false)  # Desactivar _physics_process
    if has_node("FireTimer"):
        $FireTimer.stop()
```

`set_physics_process(false)` desactiva las llamadas a `_physics_process()` para este nodo:
- El jugador deja de moverse
- Deja de procesar input
- Deja de detectar colisiones
- Ahorra CPU al no ejecutar lógica innecesaria

Combinado con `$FireTimer.stop()`, el jugador queda completamente inactivo antes de reiniciar el nivel.

---

## **SECCIÓN 10: SISTEMA DE SPAWN Y PROCEDURAL**

### **46. ¿Cómo funciona randf_range() para posiciones aleatorias?**

**Respuesta:**
```gdscript
spawn_pos = Vector2(randf_range(50, 2766), randf_range(-50, 50))
```

`randf_range(min, max)` retorna un número flotante aleatorio entre min y max (inclusivo):
- `randf_range(50, 2766)` puede dar: 50.0, 1234.567, 2765.999
- `randf_range(-50, 50)` puede dar: -49.8, 0.0, 49.2

Distribuye enemigos aleatoriamente a lo largo del borde superior del mapa. El rango Y (-50, 50) los coloca justo fuera de la pantalla pero cerca del borde.

---

### **47. ¿Cómo funciona el operador % (módulo) en la selección aleatoria?**

**Respuesta:**
```gdscript
var spawn_side = randi() % 4  # 0, 1, 2 o 3
```

`randi()` genera un entero aleatorio de 0 a 2³²-1. El operador módulo `%` retorna el resto de la división:
- `7 % 4 = 3` (7 ÷ 4 = 1 resto 3)
- `8 % 4 = 0` (8 ÷ 4 = 2 resto 0)
- `5 % 4 = 1` (5 ÷ 4 = 1 resto 1)

`x % 4` siempre retorna 0, 1, 2 o 3, perfecto para elegir uno de 4 lados del mapa.

---

### **48. ¿Por qué los enemigos se agregan al grupo "enemy" dinámicamente?**

**Respuesta:**
```gdscript
enemy.add_to_group("enemy")  # Agregar al grupo DESPUÉS de instanciar
```

Cuando instancias una escena con `instantiate()`, crea una COPIA independiente. Los grupos definidos en el archivo .tscn se copian, pero es buena práctica agregarlos explícitamente porque:
1. Garantiza que el grupo existe
2. Documenta en código qué grupos usa
3. Permite agregar al grupo condicionalmente
4. Funciona aunque la escena original no tenga el grupo

Es defensivo y previene bugs difíciles de rastrear.

---

### **49. ¿Cómo se usa match para el sistema de spawn?**

**Respuesta:**
```gdscript
match spawn_side:
    0:  # Arriba
        spawn_pos = Vector2(randf_range(50, 2766), randf_range(-50, 50))
    1:  # Abajo
        spawn_pos = Vector2(randf_range(50, 2766), randf_range(1486, 1586))
    2:  # Izquierda
        spawn_pos = Vector2(randf_range(-50, 50), randf_range(50, 1486))
    3:  # Derecha
        spawn_pos = Vector2(randf_range(2766, 2866), randf_range(50, 1486))
```

`match` es como `switch` en otros lenguajes. Evalúa `spawn_side` y ejecuta el bloque correspondiente. Es más limpio que múltiples `if-elif` cuando se compara un valor contra múltiples constantes. El compilador puede optimizarlo mejor que if-elif.

---

### **50. ¿Cómo funciona el sistema de reinicio del nivel al morir?**

**Respuesta:**
```gdscript
func die():
    set_physics_process(false)  # 1. Congelar jugador
    if has_node("FireTimer"):
        $FireTimer.stop()  # 2. Detener disparo

    modulate = Color(0.3, 0.3, 0.3)  # 3. Oscurecer sprite

    await get_tree().create_timer(1.0).timeout  # 4. Esperar 1 segundo

    get_tree().change_scene_to_file("res://nivel.tscn")  # 5. Recargar nivel
```

Proceso completo:
1. Desactiva controles del jugador (no puede moverse)
2. Detiene el Timer de disparo (no dispara más)
3. Feedback visual (sprite oscuro indica muerte)
4. Pausa dramática de 1 segundo (jugador procesa que murió)
5. Reinicia el nivel completo (todos los enemigos, kills, vida resetean)

Usa `change_scene_to_file()` en lugar de `reload_current_scene()` para ser explícito sobre qué escena cargar.

---

**FIN DEL CUESTIONARIO**

*Este cuestionario cubre los aspectos fundamentales del proyecto Neon Havoc, incluyendo nodos, algoritmos, física, animaciones, audio, UI, gestión de escenas y sistemas procedurales.*
