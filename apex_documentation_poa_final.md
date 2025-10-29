# Documentación APEX (Versión Final Corregida)
## Proyecto: Seguimiento de Metas POA Institucional

### 1. Resumen de la Aplicación
- **Enfoque:** Seguimiento de metas del POA por Unidad Administrativa con una clara separación de roles: los usuarios de una unidad **actualizan** sus metas, mientras que los superiores jerárquicos solo **supervisan** el avance de sus subordinados.

---

### 2. Lógica de Autorización (Ítems y Procesos Clave)

1.  **Crear un Ítem de Aplicación:** `UNIDAD_ID_USUARIO_LOGUEADO`
    - **Ámbito:** Aplicación.
    - **Cálculo:** Se debe establecer al iniciar la sesión.
      ```sql
      SELECT ID_UNIDAD_ADMINISTRATIVA
      INTO :UNIDAD_ID_USUARIO_LOGUEADO
      FROM SYS_FUNCIONARIO
      WHERE numero_ci = :APP_USER;
      ```

---

### 3. Estructura de Páginas

#### PÁGINA 1: Seguimiento de Metas POA

- **Tipo:** Página con Reporte Interactivo.

##### **Región 1: Reporte "Seguimiento POA"**
- **Tipo:** Reporte Interactivo.
- **Fuente (SQL):** **¡VERSIÓN CORREGIDA!** La consulta jerárquica ahora navega hacia abajo (subordinados).
  ```sql
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
      estado,
      CASE
          WHEN id_unidad_responsable = :UNIDAD_ID_USUARIO_LOGUEADO THEN 'Y'
          ELSE 'N'
      END AS permite_editar
  FROM
      V_POA_METAS_UNIDAD
  WHERE
      id_unidad_responsable IN (
          -- CONSULTA JERÁRQUICA CORREGIDA:
          -- Obtiene la unidad del usuario y todas las que descienden de ella.
          SELECT ID_UNIDAD_ADMINISTRATIVA
          FROM SYS_UNIDAD_ADMINISTRATIVA
          START WITH ID_UNIDAD_ADMINISTRATIVA = :UNIDAD_ID_USUARIO_LOGUEADO
          CONNECT BY CUA_PADRE = PRIOR CUA
      )
  ```

##### **Columnas del Reporte Interactivo:**
- **`PERMITE_EDITAR`**: Oculta.
- **Acción 1: "Editar Meta" (Link)**
  - **Condición (Server-side Condition):** `Column Value = 'Y'`, Columna: `permite_editar`.
- **Acción 2: "Registrar Avance" (Link)**
  - **Condición (Server-side Condition):** `Column Value = 'Y'`, Columna: `permite_editar`.

---

#### PÁGINA 2: Formulario de Meta (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_metas`.
- **Lógica de Seguridad:**
  - **Lista de Valores para `P2_ID_UNIDAD_RESPONSABLE`:** **¡VERSIÓN CORREGIDA!**
    - La consulta ahora muestra la unidad del usuario y sus subordinadas, permitiendo a un gerente asignar metas hacia abajo.
      ```sql
      SELECT TITULO, ID_UNIDAD_ADMINISTRATIVA
      FROM SYS_UNIDAD_ADMINISTRATIVA
      START WITH ID_UNIDAD_ADMINISTRATIVA = :UNIDAD_ID_USUARIO_LOGUEADO
      CONNECT BY CUA_PADRE = PRIOR CUA
      ORDER BY TITULO;
      ```
  - **Item `P2_USUARIO_CREADOR`**: Oculto, valor por defecto `:APP_USER`.

---

#### PÁGINA 3: Formulario de Avance (Página Modal)

- **Tipo:** Formulario Modal.
- **Fuente:** Tabla `poa_historial_avances`.
- **Lógica de Seguridad:**
  - **Proceso de Carga (Pre-Rendering):** Añadir una validación para asegurar que solo el personal autorizado pueda registrar avances.
    ```sql
    DECLARE
        v_permite_editar VARCHAR2(1);
    BEGIN
        SELECT
            CASE
                WHEN id_unidad_responsable = :UNIDAD_ID_USUARIO_LOGUEADO THEN 'Y'
                ELSE 'N'
            END
        INTO v_permite_editar
        FROM poa_metas
        WHERE id = :P3_META_ID;

        IF v_permite_editar = 'N' THEN
            RAISE_APPLICATION_ERROR(-20001, 'No tiene permiso para registrar avances en esta meta.');
        END IF;
    END;
    ```
  - **Item `P3_USUARIO_REGISTRO`**: Oculto, valor por defecto `:APP_USER`.

---

### 4. CSS Personalizado (Sin Cambios)

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
