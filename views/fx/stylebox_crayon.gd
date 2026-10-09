class_name StyleBoxCrayon
extends StyleBox
## StyleBox «dibujado a mano» para paneles, botones y campos de texto: borde de lápiz tembloroso y
## relleno de crayón rayado. Se usa desde el tema (Estilo.crear_tema), así toda la interfaz cambia
## de estilo sin tocar cada pantalla.

var relleno := Color.TRANSPARENT
var borde := Garabato.LAPIZ
var ancho_borde := 2.2
var temblor := 1.4
var separacion_rayado := 4.0
## Un segundo trazo tenue, como cuando se repasa con el lápiz.
var doble_trazo := true


func _init(p_relleno := Color.TRANSPARENT, p_borde := Garabato.LAPIZ, margen := 12.0) -> void:
	relleno = p_relleno
	borde = p_borde
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
