# Documentación APEX (Versión POA por Unidad Administrativa)
## Proyecto: Seguimiento de Metas POA Institucional

### 1. Resumen de la Aplicación
- **Enfoque:** Permitir el seguimiento de metas del POA asignadas a Unidades Administrativas, respetando la estructura jerárquica de la organización para la visualización de datos.
- **Páginas Clave:**
  - **Página 1: Seguimiento de Metas POA (Página de Inicio)**.
  - **Página 2: Formulario de Meta (Modal)**.
  - **Página 3: Formulario de Avance (Modal)**.

---

### 2. Estructura de Páginas

#### PÁGINA 1: Seguimiento de Metas POA

- **Tipo:** Página con Reporte Interactivo.
- **Nombre:** Seguimiento de Metas POA.

##### **Lógica de Carga de Datos (Pre-Rendering):**
Antes de que se cargue el reporte, es necesario determinar la unidad administrativa del usuario actual y todas las unidades que están por debajo de ella en la jerarquía.

1.  **Crear un Item de Página Oculto:** `P1_UNIDAD_ID_USUARIO`.
2.  **Crear un Proceso "Pre-Rendering" (Antes de la Cabecera):**
    ```sql
    -- Este proceso obtiene el ID de la unidad del funcionario logueado.
    SELECT ID_UNIDAD_ADMINISTRATIVA
    INTO :P1_UNIDAD_ID_USUARIO
    FROM SYS_FUNCIONARIO
    WHERE numero_ci = :APP_USER; -- O el campo que identifique al usuario
    ```

##### **Región 1: Reporte "Seguimiento POA"**
- **Tipo:** Reporte Interactivo (Interactive Report).
- **Fuente (SQL):** Esta es la consulta clave que implementa la lógica jerárquica.
  ```sql
  -- Esta consulta muestra las metas de la unidad del usuario
  -- y de todas las unidades que dependen jerárquicamente de ella.
  SELECT
      id,
      nombre_indicador,
      formula,
      meta_valor,
      unidad_medida,
      fecha_meta,
      periodicidad,
      unidad_responsable_nombre,
      progreso_actual,
      porcentaje_cumplimiento,
      estado
  FROM
      V_POA_METAS_UNIDAD
  WHERE
      id_unidad_responsable IN (
          -- Subconsulta jerárquica para obtener la unidad del usuario y sus descendientes
          SELECT ID_UNIDAD_ADMINISTRATIVA
          FROM SYS_UNIDAD_ADMINISTRATIVA
          START WITH ID_UNIDAD_ADMINISTRATIVA = :P1_UNIDAD_ID_USUARIO
          CONNECT BY PRIOR CUA = CUA_PADRE
      );
  ```
- **Botón Principal en la Región:** "Crear Nueva Meta", que redirige a la Página 2 (Modal).

##### **Columnas del Reporte Interactivo:**
- **`ID`**: Oculta.
- **`NOMBRE_INDICADOR`**: El nombre de la meta.
- **`UNIDAD_RESPONSABLE_NOMBRE`**: Para que los gerentes vean qué unidad es la dueña.
- **`PORCENTAJE_CUMPLIMIENTO`**:
  - **Tipo:** Gráfico de Porcentaje (`Percent Graph`).
- **`ESTADO`**:
  - **Tipo:** Expresión HTML -> `<span class="badge-status badge--#ESTADO#">#ESTADO#</span>`
- **Acciones (Links):**
  - **"Editar Meta"**: Llama a la Página 2 (Modal) pasando `P2_META_ID`.
  - **"Registrar Avance"**: Llama a la Página 3 (Modal) pasando `P3_META_ID`.

---

#### PÁGINA 2: Formulario de Meta (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_metas`.
- **Items del Formulario:**
  - `P2_META_ID`: Oculto, PK.
  - `P2_NOMBRE_INDICADOR`: Campo de texto, requerido.
  - `P2_FORMULA`: Área de texto.
  - `P2_ID_UNIDAD_RESPONSABLE`:
    - **Tipo:** Lista de Valores (Select List).
    - **Fuente (SQL):**
      ```sql
      -- El usuario solo puede asignar metas a su unidad o a las que dependen de él.
      SELECT TITULO, ID_UNIDAD_ADMINISTRATIVA
      FROM SYS_UNIDAD_ADMINISTRATIVA
      WHERE ID_UNIDAD_ADMINISTRATIVA IN (
          SELECT ID_UNIDAD_ADMINISTRATIVA
          FROM SYS_UNIDAD_ADMINISTRATIVA
          START WITH ID_UNIDAD_ADMINISTRATIVA = (SELECT ID_UNIDAD_ADMINISTRATIVA FROM SYS_FUNCIONARIO WHERE numero_ci = :APP_USER)
          CONNECT BY PRIOR CUA = CUA_PADRE
      )
      ORDER BY TITULO;
      ```
  - `P2_META_VALOR`, `P2_UNIDAD_MEDIDA`: Campos de texto.
  - `P2_FECHA_META`: Selector de fecha.
  - `P2_RANGO_TOLERANCIA`: Campo de texto.
  - `P2_PERIODICIDAD`: Lista de Valores con 'MENSUAL', 'TRIMESTRAL', etc.
  - `P2_USUARIO_CREADOR`: Oculto, con valor por defecto `:APP_USER`.

---

#### PÁGINA 3: Formulario de Avance (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_historial_avances`.
- **Lógica similar a la versión anterior:**
  - Un proceso de carga obtiene el `progreso_actual` de la meta y lo pone en un item `P3_VALOR_ANTERIOR` (solo lectura).
  - El usuario ingresa el `P3_VALOR_NUEVO`.
  - El item `P3_USUARIO_REGISTRO` se rellena automáticamente con `:APP_USER`.

---

### 3. CSS Personalizado (Para Badges de Estado)

```css
.badge-status {
    padding: 3px 8px; border-radius: 12px; color: white; font-weight: bold;
}
.badge--PENDIENTE { background-color: #6c757d; }
.badge--EN.PROGRESO { background-color: #007bff; }
.badge--CUMPLIDO { background-color: #28a745; }
.badge--EN.RIESGO { background-color: #ffc107; }
.badge--INCUMPLIDO { background-color: #dc3545; }
```
