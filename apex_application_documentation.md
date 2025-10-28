# Documentación de la Aplicación APEX: Tablero de Metas v2.0

## 1. Resumen de la Aplicación
- **Nombre:** Tablero de Seguimiento de Metas
- **ID de Aplicación:** (Se asignará al crear)
- **Esquema de Autenticación:** APEX Accounts (o el que se utilice en la aplicación existente)
- **Esquema de Autorización:** Basado en Roles por Departamento (requiere tabla de usuarios/roles)

---

## 2. Páginas de la Aplicación

### PÁGINA 1: Dashboard Ejecutivo (Página Principal)

- **Tipo:** Página Estándar
- **Acceso Público:** No

#### Región 1: KPIs Estratégicos
- **Tipo:** Cards (Contenedor con 4 regiones de Cards)
- **Fuente (SQL para las 4 cards):**
  ```sql
  SELECT
      (SELECT COUNT(*) FROM V_METAS_DETALLE WHERE estado = 'EN PROGRESO') AS total_metas_activas,

      (SELECT ROUND(AVG(porcentaje_completado), 2) FROM V_METAS_DETALLE WHERE estado IN ('COMPLETADO', 'EN PROGRESO')) AS tasa_cumplimiento_global,

      (SELECT COUNT(*) FROM V_METAS_DETALLE WHERE estado = 'ATRASADO' OR esta_atrasada = 'SI') AS metas_en_riesgo,

      (SELECT SUM(presupuesto_utilizado) || ' de ' || SUM(presupuesto_asignado) FROM V_METAS_DETALLE) AS presupuesto_total
  FROM DUAL;
  ```
- **Atributos:**
  - **Card 1 (Total Metas Activas):** Título "Metas Activas", Valor `total_metas_activas`, Icono `fa-bullseye`, Color `blue`.
  - **Card 2 (Tasa Cumplimiento):** Título "Cumplimiento Global (%)", Valor `tasa_cumplimiento_global`, Icono `fa-check-circle`, Color `green`.
  - **Card 3 (Metas en Riesgo):** Título "Metas en Riesgo", Valor `metas_en_riesgo`, Icono `fa-exclamation-triangle`, Color `red`.
  - **Card 4 (Presupuesto):** Título "Presupuesto Utilizado", Valor `presupuesto_total`, Icono `fa-money`, Color `orange`.


#### Región 2: Progreso por Categoría
- **Tipo:** Chart (Gráfico)
- **Tipo de Gráfico:** Bar (Barra Apilada)
- **Fuente (SQL):**
  ```sql
  SELECT
      categoria_nombre,
      estado,
      COUNT(id) AS total_metas
  FROM
      V_METAS_DETALLE
  GROUP BY
      categoria_nombre, estado
  ORDER BY
      categoria_nombre;
  ```
- **Configuración de Ejes:**
  - **Eje X (Label):** `categoria_nombre`
  - **Eje Y (Value):** `total_metas`
  - **Serie Apilada (Stack):** `estado`
- **Apariencia:** Asignar colores específicos por estado (Ej: 'COMPLETADO' -> verde, 'EN PROGRESO' -> azul, 'ATRASADO' -> rojo).


#### Región 3: Mapa de Calor de Prioridades
- **Tipo:** Chart (Gráfico) -> Bubble
- **Plugin Requerido:** Se puede simular con un gráfico de burbujas (Bubble Chart) o buscar un plugin de Heatmap.
- **Fuente (SQL):**
  ```sql
  SELECT
      prioridad,
      estado,
      -- El tamaño de la burbuja representa la complejidad
      CASE complejidad
          WHEN 'BAJA' THEN 1
          WHEN 'MEDIA' THEN 3
          WHEN 'ALTA' THEN 5
          ELSE 1
      END AS tamano_burbuja,
      -- El color representa el avance promedio de las metas en ese cruce
      AVG(porcentaje_completado) AS avg_completado
  FROM
      V_METAS_DETALLE
  GROUP BY
      prioridad, estado, complejidad;
  ```
- **Configuración:**
  - **Eje X:** `prioridad`
  - **Eje Y:** `estado`
  - **Tamaño (Size):** `tamano_burbuja`
  - **Color:** Basado en `avg_completado` (usar `Color` -> `Gradients` en la configuración del gráfico).


#### Región 4: Timeline de Metas Críticas
- **Tipo:** Reporte Clásico o plugin de Timeline/Gantt
- **Fuente (SQL):**
  ```sql
  SELECT
      id,
      nombre,
      fecha_fin,
      responsable_nombre,
      porcentaje_completado,
      CASE
          WHEN estado = 'ATRASADO' THEN 'danger'
          WHEN fecha_fin BETWEEN SYSDATE AND SYSDATE + 7 THEN 'warning'
          ELSE 'success'
      END AS status_color
  FROM V_METAS_DETALLE
  WHERE prioridad = 'CRITICA' AND estado NOT IN ('COMPLETADO', 'CANCELADO')
  ORDER BY fecha_fin ASC;
  ```
- **Visualización:** Usar una plantilla de reporte tipo "Timeline" y aplicar la clase CSS basada en `status_color`.

---

### PÁGINA 10: Gestión de Metas

- **Tipo:** Página con Reporte Interactivo
- **Fuente:** `V_METAS_DETALLE`

#### Región 1: Reporte Interactivo de Metas
- **Atributos del Reporte:**
  - **Búsqueda Facetada:** Habilitada.
  - **Filtros por Defecto:** `departamento_nombre`, `categoria_nombre`, `estado`, `fecha_fin` (rango).
- **Columnas y Formato:**
  - `ID`: Oculta.
  - `NOMBRE`: Visible.
  - `PORCENTAJE_COMPLETADO`:
    - **Tipo:** Porcentaje Gráfico (`Percent Graph`).
    - **Colores:** Aplicar colores condicionales basados en valor (>=80% verde, 50-79% amarillo, <50% rojo).
  - `ESTADO`:
    - **Tipo:** HTML Expression.
    - **Expresión:** `<span class="badge-status badge--#ESTADO#">#ESTADO#</span>` (requiere CSS personalizado).
  - `PRIORIDAD`:
    - **Tipo:** HTML Expression.
    - **Expresión:** `<span class="badge-priority badge--#PRIORIDAD#">#PRIORIDAD#</span>` (requiere CSS personalizado).
  - **Columna de Acciones (Link):**
    - **Target:** Página 20 (Detalle de Meta).
    - **Parámetros:** `P20_META_ID` -> `#ID#`.
    - **Texto del Link:** Icono `fa-search`.
  - **Botón "Registrar Avance":**
    - **Acción:** Abrir página modal (Página 11) para registrar avance, pasando el `ID` de la meta.

---

### PÁGINA 20: Detalle de Meta

- **Tipo:** Página Estándar
- **Parámetro:** `P20_META_ID` (ID de la meta a mostrar).

#### Región 1: Información General
- **Tipo:** Formulario
- **Fuente:** `V_METAS_DETALLE`
- **Proceso de Carga:** "Form - Initialization" que carga los datos de la meta con el `P20_META_ID`.
- **Items:** Todos los campos de la vista `V_METAS_DETALLE`, la mayoría en modo "Solo Lectura".

#### Región 2: Gráfico de Evolución
- **Tipo:** Chart (Gráfico) -> Line with Area
- **Fuente (SQL):**
  ```sql
  SELECT
      h.fecha_registro,
      h.valor_nuevo,
      f.nombre || ' ' || f.apellido as registrador
  FROM
      historial_avances h
  JOIN
      SYS_FUNCIONARIO f ON h.usuario_registro = f.id_funcionario
  WHERE
      h.meta_id = :P20_META_ID
  ORDER BY
      h.fecha_registro ASC;
  ```
- **Configuración:**
  - **Eje X:** `fecha_registro`
  - **Eje Y:** `valor_nuevo`
  - **Tooltip:** `registrador`

#### Región 3: Lista de Hitos
- **Tipo:** Interactive Grid
- **Fuente:** `hitos_metas`
- **Cláusula WHERE:** `meta_id = :P20_META_ID`
- **Atributos:**
  - Edición habilitada para `nombre`, `fecha_objetivo`, `completado`.
  - Columna `COMPLETADO` tipo `Checkbox`.
  - Proceso de guardado estándar de IG.

#### Región 4: Historial de Avances
- **Tipo:** Reporte Clásico
- **Fuente (SQL):**
  ```sql
  SELECT
      h.fecha_registro,
      f.nombre || ' ' || f.apellido as usuario_registro,
      h.valor_anterior,
      h.valor_nuevo,
      h.diferencia,
      h.observaciones
  FROM
      historial_avances h
  JOIN
      SYS_FUNCIONARIO f ON h.usuario_registro = f.id_funcionario
  WHERE
      h.meta_id = :P20_META_ID
  ORDER BY
      h.fecha_registro DESC;
  ```

---

## 3. CSS Personalizado (Opcional, para Badges)

Añadir en la sección de CSS de la aplicación:

```css
.badge-status, .badge-priority {
    padding: 3px 8px;
    border-radius: 12px;
    color: white;
    font-weight: bold;
    text-transform: uppercase;
    font-size: 0.75rem;
}

/* Colores por Estado */
.badge--PENDIENTE { background-color: #6c757d; }
.badge--EN.PROGRESO { background-color: #007bff; }
.badge--COMPLETADO { background-color: #28a745; }
.badge--ATRASADO { background-color: #dc3545; }
.badge--CANCELADO { background-color: #343a40; }

/* Colores por Prioridad */
.badge--BAJA { background-color: #17a2b8; }
.badge--MEDIA { background-color: #ffc107; color: #212529; }
.badge--ALTA { background-color: #fd7e14; }
.badge--CRITICA { background-color: #dc3545; }
```
