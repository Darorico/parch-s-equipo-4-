@tool
class_name StyleBoxCrayon
extends StyleBox
## StyleBox «dibujado a mano» para paneles, botones y campos de texto: borde de lápiz tembloroso y
## relleno de crayón rayado. Lo usa el tema (views/tema/tema_cuaderno.tres), así toda la interfaz cambia
## de estilo sin tocar cada pantalla.

## Color del relleno de crayón (transparente = sin relleno).
@export var relleno := Color.TRANSPARENT:
	set(valor):
		relleno = valor
		emit_changed()
## Color del borde de lápiz (transparente = sin borde).
@export var borde := Garabato.LAPIZ:
	set(valor):
		borde = valor
		emit_changed()
@export_range(0.5, 6.0, 0.1) var ancho_borde := 2.2:
	set(valor):
		ancho_borde = valor
		emit_changed()
## Cuánto ondula el trazo del lápiz.
@export_range(0.0, 5.0, 0.1) var temblor := 1.4:
	set(valor):
		temblor = valor
		emit_changed()
## Distancia entre las rayas del crayón (más chica = más relleno).
@export_range(2.0, 12.0, 0.5) var separacion_rayado := 4.0:
	set(valor):
		separacion_rayado = valor
		emit_changed()
## Un segundo trazo tenue, como cuando se repasa con el lápiz.
@export var doble_trazo := true:
	set(valor):
		doble_trazo = valor
		emit_changed()


## `margen` negativo = no tocar los márgenes. Así, al cargar un .tres o una escena (que llaman a _init()
## sin argumentos después de asignar los márgenes guardados), no se pisan esos valores.
func _init(p_relleno := Color.TRANSPARENT, p_borde := Garabato.LAPIZ, margen := -1.0) -> void:
	relleno = p_relleno
	borde = p_borde
	if margen >= 0.0:
		set_content_margin_all(margen)


func _draw(ci: RID, r: Rect2) -> void:
	# La semilla depende del tamaño y no de la posición, para que el dibujo no cambie al desplazar.
	var semilla := Garabato.semilla_de(Vector2i(r.size))
	var interior := r.grow(-2.0)
	if relleno.a > 0.0:
		Garabato.rellenar_rect(ci, interior, relleno, semilla, separacion_rayado)
	if borde.a > 0.0:
		Garabato.rect(ci, interior, borde, ancho_borde, semilla, temblor)
		if doble_trazo:
			Garabato.rect(ci, interior.grow(0.8), Color(borde, borde.a * 0.35), 1.2, semilla + 7, temblor * 1.6)
