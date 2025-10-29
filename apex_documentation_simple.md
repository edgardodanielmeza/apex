# Documentación APEX (Versión Simplificada)
## Proyecto: Mi POA Individual

### 1. Resumen de la Aplicación
- **Enfoque:** Proveer una interfaz simple y directa para que cada funcionario gestione sus metas personales del POA.
- **Páginas Clave:**
  - **Página 1: Mis Metas (Página de Inicio)**. Un reporte interactivo para ver y gestionar las metas.
  - **Página 2: Formulario de Meta (Modal)**. Para crear o editar una meta.
  - **Página 3: Formulario de Avance (Modal)**. Para registrar un nuevo avance en una meta.

---

### 2. Estructura de Páginas

#### PÁGINA 1: Mis Metas

- **Tipo:** Página con Reporte Interactivo.
- **Nombre:** Mis Metas del POA.

##### **Región 1: Reporte "Mis Metas"**
- **Tipo:** Reporte Interactivo (Interactive Report).
- **Fuente (SQL):** Se utilizará la vista `V_POA_METAS_FUNCIONARIO` para simplificar.
  ```sql
  SELECT
      id,
      nombre,
      descripcion,
      fecha_inicio,
      fecha_fin,
      valor_inicial,
      valor_meta,
      progreso_actual,
      unidad_medida,
      porcentaje_completado,
      estado,
      -- Columnas para los botones de acción
      'fa fa-edit' as icono_editar,
      'fa fa-plus-circle' as icono_avance
  FROM
      V_POA_METAS_FUNCIONARIO
  WHERE
      id_funcionario = (SELECT id_funcionario FROM sys_funcionario WHERE numero_ci = :APP_USER)
      -- NOTA: Usar el predicado que corresponda para obtener el ID del usuario logueado.
      -- Si :APP_USER es el ID_FUNCIONARIO directamente, sería: id_funcionario = :APP_USER
  ```
- **Filtro de Autorización:** La cláusula `WHERE` asegura que cada usuario solo vea sus propias metas.
- **Botón Principal en la Región:**
  - **Nombre:** "Crear Nueva Meta"
  - **Acción:** Redirigir a la Página 2 (Formulario de Meta) en modo modal, sin pasar ID (para creación).

##### **Columnas del Reporte Interactivo:**
- **`ID`**: Columna oculta.
- **`NOMBRE`**: Título de la meta.
- **`PORCENTAJE_COMPLETADO`**:
  - **Tipo de Columna:** Gráfico de Porcentaje (`Percent Graph`).
  - **Formato Condicional:**
    - `>= 80%`: Color verde (`#28a745`)
    - `Entre 50% y 79%`: Color amarillo (`#ffc107`)
    - `< 50%`: Color rojo (`#dc3545`)
- **`ESTADO`**:
  - **Tipo de Columna:** Expresión HTML.
  - **Expresión:** `<span class="badge-status badge--#ESTADO#">#ESTADO#</span>` (requiere CSS).
- **`FECHA_FIN`**: Plazo de la meta.
- **Acción 1: "Editar Meta"**
  - **Tipo de Columna:** Enlace (Link).
  - **Texto del Enlace:** `#ICONO_EDITAR#` (para mostrar solo el ícono).
  - **Destino:** Página 2 (Formulario de Meta) en modo modal.
  - **Parámetros:** `P2_META_ID` -> `#ID#` (para cargar la meta a editar).
- **Acción 2: "Registrar Avance"**
  - **Tipo de Columna:** Enlace (Link).
  - **Texto del Enlace:** `#ICONO_AVANCE#`.
  - **Destino:** Página 3 (Formulario de Avance) en modo modal.
  - **Parámetros:** `P3_META_ID` -> `#ID#`.

---

#### PÁGINA 2: Formulario de Meta (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_metas`.
- **Procesos:**
  - **Proceso de Carga:** "Form - Initialization" estándar para cargar los datos de la meta cuando `P2_META_ID` no es nulo.
  - **Proceso de Guardado:** "Form - Automatic Row Processing (DML)" para insertar o actualizar la meta.
- **Items del Formulario:**
  - `P2_META_ID`: Oculto, clave primaria.
  - `P2_NOMBRE`: Campo de texto, requerido.
  - `P2_DESCRIPCION`: Área de texto.
  - `P2_ID_FUNCIONARIO`:
    - **Tipo:** Oculto.
    - **Valor por Defecto (solo en creación):** Lógica SQL para obtener el `id_funcionario` del usuario actual.
  - `P2_FECHA_INICIO`, `P2_FECHA_FIN`: Selectores de fecha.
  - `P2_VALOR_INICIAL`, `P2_VALOR_META`: Campos numéricos, requeridos.
  - `P2_UNIDAD_MEDIDA`: Campo de texto.
- **Botones:** "Cancelar", "Guardar" (o "Crear" si es un nuevo registro).

---

#### PÁGINA 3: Formulario de Avance (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_historial_avances`.
- **Procesos:**
  - **Proceso de Carga:** Un proceso PL/SQL personalizado para obtener el `valor_anterior` (que es el `progreso_actual` de la meta).
    ```sql
    -- Código para el proceso de carga
    SELECT progreso_actual
    INTO :P3_VALOR_ANTERIOR
    FROM poa_metas
    WHERE id = :P3_META_ID;
    ```
  - **Proceso de Guardado:** Proceso DML estándar para insertar un nuevo registro en `poa_historial_avances`.
- **Items del Formulario:**
  - `P3_META_ID`: Oculto, FK a la meta.
  - `P3_USUARIO_REGISTRO`: Oculto, obtener ID del usuario logueado.
  - `P3_VALOR_ANTERIOR`: Campo de solo lectura.
  - `P3_VALOR_NUEVO`: Campo numérico, requerido. El usuario ingresa aquí su nuevo progreso.
  - `P3_OBSERVACIONES`: Área de texto.
- **Botones:** "Cancelar", "Registrar".

---

### 3. CSS Personalizado (Para los Badges de Estado)

Añadir en la sección de CSS de la aplicación para dar color a los estados:
```css
.badge-status {
    padding: 3px 8px;
    border-radius: 12px;
    color: white;
    font-weight: bold;
    font-size: 0.8rem;
}
.badge--PENDIENTE { background-color: #6c757d; }
.badge--EN.PROGRESO { background-color: #007bff; }
.badge--COMPLETADO { background-color: #28a745; }
.badge--ATRASADO { background-color: #dc3545; }
.badge--CANCELADO { background-color: #343a40; }
```
