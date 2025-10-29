--==============================================================================
-- PAQUETE PL/SQL PARA LA CARGA DE DATOS DEL POA
-- Proyecto: Seguimiento de Metas POA Institucional
-- Versión: 1.0
-- Descripción: Contiene los procedimientos para crear metas y registrar
-- avances. Este paquete será el intermediario entre la interfaz
-- de APEX y la base de datos.
--==============================================================================

CREATE OR REPLACE PACKAGE PKG_POA_CARGA AS

    /**
     * Procedimiento para crear una nueva meta del POA.
     * Es llamado desde el formulario de creación de metas en APEX.
     */
    PROCEDURE crear_meta (
        p_nombre_indicador      IN VARCHAR2,
        p_formula               IN VARCHAR2,
        p_linea_base            IN VARCHAR2,
        p_meta_valor            IN NUMBER,
        p_unidad_medida         IN VARCHAR2,
        p_fecha_meta            IN DATE,
        p_rango_tolerancia      IN VARCHAR2,
        p_periodicidad          IN VARCHAR2,
        p_id_unidad_responsable IN NUMBER,
        p_usuario_creador       IN VARCHAR2
    );

    /**
     * Procedimiento para registrar un nuevo avance en una meta existente.
     * Es llamado desde el formulario de registro de avances en APEX.
     */
    PROCEDURE registrar_avance (
        p_meta_id           IN NUMBER,
        p_usuario_registro  IN VARCHAR2,
        p_valor_nuevo       IN NUMBER,
        p_observaciones     IN CLOB
    );

END PKG_POA_CARGA;
/

CREATE OR REPLACE PACKAGE BODY PKG_POA_CARGA AS

    PROCEDURE crear_meta (
        p_nombre_indicador      IN VARCHAR2,
        p_formula               IN VARCHAR2,
        p_linea_base            IN VARCHAR2,
        p_meta_valor            IN NUMBER,
        p_unidad_medida         IN VARCHAR2,
        p_fecha_meta            IN DATE,
        p_rango_tolerancia      IN VARCHAR2,
        p_periodicidad          IN VARCHAR2,
        p_id_unidad_responsable IN NUMBER,
        p_usuario_creador       IN VARCHAR2
    ) AS
    BEGIN
        INSERT INTO poa_metas (
            nombre_indicador,
            formula,
            linea_base,
            meta_valor,
            unidad_medida,
            fecha_meta,
            rango_tolerancia,
            periodicidad,
            id_unidad_responsable,
            usuario_creador,
            fecha_creacion
        ) VALUES (
            p_nombre_indicador,
            p_formula,
            p_linea_base,
            p_meta_valor,
            p_unidad_medida,
            p_fecha_meta,
            p_rango_tolerancia,
            p_periodicidad,
            p_id_unidad_responsable,
            p_usuario_creador,
            SYSDATE
        );
    END crear_meta;

    PROCEDURE registrar_avance (
        p_meta_id           IN NUMBER,
        p_usuario_registro  IN VARCHAR2,
        p_valor_nuevo       IN NUMBER,
        p_observaciones     IN CLOB
    ) AS
        v_valor_anterior NUMBER;
    BEGIN
        -- Antes de insertar, obtenemos el progreso actual para guardarlo en el historial.
        SELECT progreso_actual
        INTO v_valor_anterior
        FROM poa_metas
        WHERE id = p_meta_id;

        -- Insertamos el nuevo registro en el historial.
        -- El trigger 'trg_actualizar_progreso_poa_final' se disparará automáticamente
        -- después de este INSERT para actualizar la tabla principal 'poa_metas'.
        INSERT INTO poa_historial_avances (
            meta_id,
            fecha_registro,
            usuario_registro,
            valor_anterior,
            valor_nuevo,
            observaciones
        ) VALUES (
            p_meta_id,
            SYSDATE,
            p_usuario_registro,
            v_valor_anterior,
            p_valor_nuevo,
            p_observaciones
        );
    END registrar_avance;

END PKG_POA_CARGA;
/

--==============================================================================
-- Ejemplo de cómo llamar a los procedimientos (para pruebas)
--==============================================================================
/*
-- Ejemplo 1: Crear una nueva meta
BEGIN
    PKG_POA_CARGA.crear_meta(
        p_nombre_indicador      => '% DE CUMPLIMIENTO DE LAS SAC/SAM/SAI',
        p_formula               => 'ACCIONES CUMPLIDAS/ACCIONES A CUMPLIR * 100',
        p_linea_base            => '0%',
        p_meta_valor            => 100,
        p_unidad_medida         => '%',
        p_fecha_meta            => TO_DATE('31/12/2024', 'DD/MM/YYYY'),
        p_rango_tolerancia      => '30%',
        p_periodicidad          => 'MENSUAL',
        p_id_unidad_responsable => 123, -- Reemplazar con un ID válido de SYS_UNIDAD_ADMINISTRATIVA
        p_usuario_creador       => 'USUARIO_PRUEBA'
    );
    COMMIT;
END;
/

-- Ejemplo 2: Registrar un avance para la meta recién creada (asumiendo que su ID es 1)
BEGIN
    PKG_POA_CARGA.registrar_avance(
        p_meta_id           => 1, -- Reemplazar con el ID de la meta a actualizar
        p_usuario_registro  => 'USUARIO_PRUEBA',
        p_valor_nuevo       => 25,
        p_observaciones     => 'Se completó el primer hito del proyecto.'
    );
    COMMIT;
END;
/
*/
