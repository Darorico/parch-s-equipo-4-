# Guía visual: editar el juego desde el editor de Godot

Todas las pantallas son **escenas** que puedes abrir, ver dibujadas y modificar con el ratón y el
Inspector, sin tocar código. Esta guía te dice dónde está cada cosa y qué puedes cambiar sin romper nada.

> **Antes de empezar:** si tenías el editor abierto antes de esta actualización, usa
> **Proyecto → Recargar proyecto actual**.

---

## 1. Dónde está cada pantalla

En el panel **Sistema de archivos** (abajo a la izquierda) entra a `res://views/escenas/` y haz doble clic:

| Escena | Pantalla del storyboard | Qué contiene |
|---|---|---|
| `vista_registro.tscn` | 01 Registro | Nombre, colores, avatares, servidor y botones |
| `vista_sala_espera.tscn` | 02 Sala de espera | Lista de jugadores, resumen, botón LISTO y reglas |
| `vista_tablero.tscn` | 03/04 Tablero | **El tablero**, el panel de jugadores y el panel de acciones |
| `panel_jugadores.tscn` | Panel «Jugadores» | Título, lista y caja «Turno de…» |
| `panel_acciones.tscn` | Panel del turno | Dado, «Lanzar dado», fichas 1 a 4, «Liberar» y «Mover» |
| `fila_jugador.tscn` | Una fila de jugador | Avatar, nombre, detalle y etiqueta (LISTO / TURNO) |

`main.tscn` sigue vacía a propósito: solo arranca el juego y va cargando estas escenas.

Al abrir una escena, la pestaña **2D** muestra el papel arrugado, los garabatos, los recuadros a lápiz y,
en `vista_tablero.tscn`, el tablero con **fichas de ejemplo**. Los textos que ves («Nombre del jugador»,
«Turno de …») son de muestra; durante el juego los reemplazan los datos reales.

---

## 2. Estructura de una pantalla (árbol de la pestaña «Escena»)

```
VistaTablero            (Control con el script vista_tablero.gd)
├─ Papel                papel arrugado (shader)
├─ Decoraciones         estrellas, espirales y crayón de las orillas
└─ Contenido            márgenes de la pantalla
   └─ Columna
      ├─ %Encabezado    número, sección, título rojo y logo
      └─ Cuerpo
         ├─ %Tablero    ← EL TABLERO (TableroDibujo)
         └─ Lateral (scroll)
            └─ Paneles
               ├─ %PanelJugadores   (escena panel_jugadores.tscn)
               └─ %PanelAcciones    (escena panel_acciones.tscn)
```

Las otras pantallas siguen el mismo patrón: **Papel → Decoraciones → Contenido → Columna →** tarjetas.

### ⚠️ Los nodos con `%`

Los nodos marcados con **%** (icono de porcentaje junto al nombre) son los que el código busca por nombre,
por ejemplo `%Tablero`, `%BotonLanzar` o `%Nombre`.

- ✅ Puedes **moverlos, cambiarles tamaño, color, texto, fuente y márgenes**.
- ❌ **No los renombres ni los borres**, porque el juego dejaría de encontrarlos y marcaría error.

Si necesitas cambiarle el nombre a uno, avísame para ajustar el script.

---

## 3. Modificar el tablero

1. Abre `vista_tablero.tscn` y selecciona el nodo **%Tablero**.
2. En el **Inspector**, en la sección **Dibujo del tablero**:

| Propiedad | Qué cambia | Valor actual |
|---|---|---|
| Grosor Lapiz | Grosor de todas las líneas de lápiz | 2.4 |
| Temblor | Cuánto ondulan las líneas (0 = rectas, como con regla) | 1.4 |
| Separacion Crayon | Distancia entre rayas del crayón (menos = color más lleno) | 4.5 |
| Radio Ficha | Tamaño de las fichas en el recorrido | 0.42 |
| Fichas De Ejemplo | Mostrar u ocultar las fichas de muestra (solo en el editor) | ✔ |

El tablero se redibuja al instante cuando cambias un valor.

**Tamaño y posición:** el tablero ocupa todo el espacio que le deja el panel lateral y siempre se mantiene
cuadrado. Para hacerlo más grande, reduce el ancho del nodo **Lateral** (`Custom Minimum Size → x`,
ahora 370) o los márgenes de **Contenido** (*Theme Overrides → Constants*).

**Lo que se cambia en código** (en `views/tablero_dibujo.gd`, al inicio del archivo):
- `CASAS`: posición de cada casa.
- `SALIDAS` y `SEGUROS`: casillas especiales. Deben coincidir con `models/reglas/reglas_mock.gd`.
- `PASILLOS`: pasillos de meta.
- Los colores de los crayones están en `views/estilo.gd` → `COLORES`.

---

## 4. Modificar paneles, botones y textos

- **Texto de un botón o etiqueta:** selecciona el nodo y cambia `Text` en el Inspector.
- **Tamaño de letra:** *Theme Overrides → Font Sizes*.
- **Color de un texto:** *Theme Overrides → Colors → Font Color*.
- **Recuadro de un panel (borde de lápiz y crayón):** *Theme Overrides → Styles → Panel*; haz clic en el
  recurso **StyleBoxCrayon** para cambiar:
  - `Relleno`: color del crayón (transparente = sin relleno);
  - `Borde`: color del lápiz (transparente = sin borde);
  - `Ancho Borde`, `Temblor`, `Separacion Rayado` y `Doble Trazo`.
- **Espacio entre elementos:** en las cajas (`VBoxContainer` / `HBoxContainer`) usa
  *Theme Overrides → Constants → Separation*.
- **Dado:** en `panel_acciones.tscn`, nodo **%Dado**. Cambia `Valor` (0 a 6) para ver cada cara.
- **Avatares y bolitas de color:** nodos `AvatarIcono`. Propiedades `Color` y `Forma`
  (0 estrella, 1 rombo, 2 anillo, 3 triángulo, -1 bolita).

---

## 5. Cambiar el estilo de TODO el juego a la vez: el tema

`res://views/tema/tema_cuaderno.tres` es el tema del proyecto. Ábrelo con doble clic y se abre el
**editor de temas** en el panel inferior. Lo que cambies ahí se aplica a todas las pantallas:

- **Button:** botones normales (estados normal, hover, pressed y disabled).
- **BotonPrimario:** botones azules con letra amarilla («LANZAR DADO», «LISTO»…).
- **PanelContainer:** recuadros de lápiz de las tarjetas.
- **LineEdit:** campos de texto.
- **Label:** color de texto por defecto.

La fuente es **Pangolin** (`res://assets/fuentes/Pangolin-Regular.ttf`).
La versión gruesa para títulos y botones es `res://views/tema/pangolin_negrita.tres`, y su grosor se
cambia con `Variation → Embolden`.

---

## 6. Papel, garabatos y animaciones

- **Papel arrugado:** nodo **Papel** de cada pantalla → *Material → Shader Parameters*:
  - `Escala Arrugas`: tamaño de las arrugas;
  - `Fuerza Arrugas`: qué tan marcadas se ven;
  - `Fuerza Grano` y `Fuerza Dobleces`.
- **Garabatos de las orillas:** `views/fx/decoraciones.gd` (en código).
- **Velocidad de las animaciones:** `views/fx/gestor_animaciones.gd` → `VELOCIDAD`. Ahora vale 0.4, es
  decir, 60 % más lento que el original; 1.0 es la velocidad original.
- **Temblor animado de los trazos:** `Animaciones.linea_viva` (true/false) en el mismo archivo.

---

## 7. Probar tus cambios

1. Guarda la escena con `Ctrl + S`.
2. Presiona **F5** para jugar en escritorio. Para dos jugadores en el mismo equipo, configura
   *Depurar → Personalizar instancias de ejecución* con 2 instancias.
3. Para la versión Web, vuelve a exportar:
   ```powershell
   .\scripts\exportar_web.ps1
   ```

**Si algo se rompe**, Git guarda todas las versiones. Puedes descartar los cambios de una escena con:
```powershell
git checkout -- views/escenas/vista_tablero.tscn
```
