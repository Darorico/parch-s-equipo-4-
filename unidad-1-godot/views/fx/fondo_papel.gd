@tool
class_name FondoPapel
extends ColorRect
## Fondo de papel arrugado (shader papel.gdshader). Si después consiguen una foto de papel, basta con
## cambiar este nodo por un TextureRect con esa imagen.

const SHADER := preload("res://views/fx/papel.gdshader")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if material == null:
		material = ShaderMaterial.new()
		material.shader = SHADER
	resized.connect(_actualizar_proporcion)


func _actualizar_proporcion() -> void:
	if size.y > 0.0 and material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("proporcion", Vector2(size.x / size.y, 1.0))
