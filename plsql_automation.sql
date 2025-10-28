--==============================================================================
-- PAQUETE PL/SQL PARA PROCESOS AUTOMÁTICOS Y NOTIFICACIONES
-- Versión: 2.0
-- Descripción: Automatiza el envío de notificaciones y realiza cálculos
-- predictivos. Integrado con SYS_FUNCIONARIO para obtener destinatarios.
--==============================================================================

CREATE OR REPLACE PACKAGE PKG_METAS_AUTOMATIZACION AS

    -- Procedimiento para enviar notificaciones (integrado con APEX_MAIL)
    PROCEDURE enviar_notificacion (
        p_destinatario_id IN NUMBER, -- ID_FUNCIONARIO
        p_asunto          IN VARCHAR2,
        p_cuerpo_html     IN CLOB
    );

    -- Job para verificar metas próximas a vencer y enviar recordatorios
    PROCEDURE job_verificar_vencimientos;

    -- Job para detectar metas con progreso estancado
    PROCEDURE job_detectar_metas_sin_progreso;

    -- Función para análisis predictivo simple (cálculo de tendencia)
    FUNCTION calcular_tendencia(p_meta_id IN NUMBER) RETURN VARCHAR2;

    -- Función para estimar la fecha de finalización basada en el ritmo actual
    FUNCTION estimar_fecha_fin(p_meta_id IN NUMBER) RETURN DATE;

END PKG_METAS_AUTOMATIZACION;
/

CREATE OR REPLACE PACKAGE BODY PKG_METAS_AUTOMATIZACION AS

    -- Implementación del envío de notificaciones
    PROCEDURE enviar_notificacion (
        p_destinatario_id IN NUMBER,
        p_asunto          IN VARCHAR2,
        p_cuerpo_html     IN CLOB
    ) AS
        v_email_destinatario VARCHAR2(300);
        v_app_id             NUMBER;
    BEGIN
        -- Obtener el email del funcionario desde la tabla SYS_FUNCIONARIO
        -- ATENCIÓN: Se asume que existe un campo de email. Si no, ajustar la lógica.
        -- Por ejemplo, si el email está en otra tabla como SYS_PERSONA, se haría un JOIN.
        -- Para este ejemplo, se asume un campo 'EMAIL' en SYS_FUNCIONARIO.
        -- Si no existe, puedes reemplazar la lógica por un campo existente o un valor fijo.
        BEGIN
            -- Se asume que el email se puede construir o ya existe.
            -- Ejemplo: usando el nombre de usuario o un campo email.
            -- SELECT email INTO v_email_destinatario FROM SYS_FUNCIONARIO WHERE id_funcionario = p_destinatario_id;
            -- Como no tenemos campo email, simularemos uno. ¡REEMPLAZAR ESTO!
            SELECT lower(nombre1 || '.' || apellido1 || '@dominio.com')
            INTO v_email_destinatario
            FROM SYS_FUNCIONARIO
            WHERE id_funcionario = p_destinatario_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No se encontró el funcionario con ID: ' || p_destinatario_id);
                RETURN;
        END;

        -- Enviar correo solo si estamos en una sesión de APEX
        SELECT v('APP_ID') INTO v_app_id FROM DUAL;
        IF v_app_id IS NOT NULL THEN
            APEX_MAIL.SEND(
                p_to   => v_email_destinatario,
                p_from => 'sistema.metas@tuorganizacion.com', -- Email del remitente
                p_subj => p_asunto,
                p_body_html => p_cuerpo_html
            );
            APEX_MAIL.PUSH_QUEUE; -- Forzar el envío inmediato de la cola de correos
        ELSE
            DBMS_OUTPUT.PUT_LINE('Simulación (No en APEX): Correo a ' || v_email_destinatario || ' con asunto: ' || p_asunto);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Log de errores en una tabla de logs sería ideal
            DBMS_OUTPUT.PUT_LINE('Error enviando notificación: ' || SQLERRM);
    END;

    -- Job que busca metas que vencen en los próximos 7 días
    PROCEDURE job_verificar_vencimientos AS
        v_asunto VARCHAR2(200);
        v_cuerpo CLOB;
    BEGIN
        FOR rec IN (
            SELECT id, nombre, usuario_responsable, fecha_fin
            FROM metas
            WHERE estado NOT IN ('COMPLETADO', 'CANCELADO')
              AND fecha_fin BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7
        ) LOOP
            v_asunto := 'Recordatorio: La meta "' || rec.nombre || '" vence pronto.';
            v_cuerpo := '<h1>Alerta de Vencimiento</h1>' ||
                        '<p>Estimado/a responsable,</p>' ||
                        '<p>Le informamos que la meta <b>' || rec.nombre || '</b> está programada para vencer el <b>' || TO_CHAR(rec.fecha_fin, 'DD/MM/YYYY') || '</b>.</p>' ||
                        '<p>Por favor, asegúrese de registrar todos los avances correspondientes.</p>' ||
                        '<p>Saludos cordiales,<br>Sistema de Seguimiento de Metas</p>';

            IF rec.usuario_responsable IS NOT NULL THEN
                enviar_notificacion(
                    p_destinatario_id => rec.usuario_responsable,
                    p_asunto          => v_asunto,
                    p_cuerpo_html     => v_cuerpo
                );
            END IF;
        END LOOP;
    END;

    -- Job que detecta metas sin registro de avances en los últimos 15 días
    PROCEDURE job_detectar_metas_sin_progreso AS
        v_asunto VARCHAR2(200);
        v_cuerpo CLOB;
    BEGIN
        FOR rec IN (
            SELECT m.id, m.nombre, m.usuario_responsable
            FROM metas m
            LEFT JOIN (
                SELECT meta_id, MAX(fecha_registro) as ultima_fecha
                FROM historial_avances
                GROUP BY meta_id
            ) h ON m.id = h.meta_id
            WHERE m.estado = 'EN PROGRESO'
              AND (h.ultima_fecha IS NULL OR h.ultima_fecha < SYSDATE - 15)
        ) LOOP
            v_asunto := 'Alerta: Posible estancamiento en la meta "' || rec.nombre || '".';
            v_cuerpo := '<h1>Alerta de Inactividad</h1>' ||
                        '<p>Estimado/a responsable,</p>' ||
                        '<p>La meta <b>' || rec.nombre || '</b>, que se encuentra "EN PROGRESO", no ha registrado actualizaciones en los últimos 15 días.</p>' ||
                        '<p>Por favor, revise su estado y registre cualquier avance para mantener la información al día.</p>';

            IF rec.usuario_responsable IS NOT NULL THEN
                enviar_notificacion(
                    p_destinatario_id => rec.usuario_responsable,
                    p_asunto          => v_asunto,
                    p_cuerpo_html     => v_cuerpo
                );
            END IF;
        END LOOP;
    END;

    -- Calcula la tendencia comparando el progreso de la última semana con la anterior
    FUNCTION calcular_tendencia(p_meta_id IN NUMBER) RETURN VARCHAR2 AS
        v_progreso_reciente NUMBER := 0;
        v_progreso_anterior NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(valor_nuevo - valor_anterior), 0) INTO v_progreso_reciente
        FROM historial_avances WHERE meta_id = p_meta_id AND fecha_registro >= SYSDATE - 7;

        SELECT NVL(SUM(valor_nuevo - valor_anterior), 0) INTO v_progreso_anterior
        FROM historial_avances WHERE meta_id = p_meta_id AND fecha_registro BETWEEN SYSDATE - 14 AND SYSDATE - 8;

        IF v_progreso_reciente > v_progreso_anterior THEN RETURN 'POSITIVA';
        ELSIF v_progreso_reciente < v_progreso_anterior THEN RETURN 'NEGATIVA';
        ELSE RETURN 'ESTABLE';
        END IF;
    END;

    -- Estima la fecha de fin basándose en la velocidad promedio de avance
    FUNCTION estimar_fecha_fin(p_meta_id IN NUMBER) RETURN DATE AS
        v_meta metas%ROWTYPE;
        v_velocidad_promedio NUMBER;
        v_dias_restantes NUMBER;
    BEGIN
        SELECT * INTO v_meta FROM metas WHERE id = p_meta_id;

        IF v_meta.estado IN ('COMPLETADO', 'CANCELADO') OR v_meta.fecha_inicio IS NULL THEN
            RETURN v_meta.fecha_cierre;
        END IF;

        IF (TRUNC(SYSDATE) - TRUNC(v_meta.fecha_inicio)) > 0 THEN
            v_velocidad_promedio := (v_meta.progreso_actual - v_meta.valor_inicial) / (TRUNC(SYSDATE) - TRUNC(v_meta.fecha_inicio));
        ELSE
            RETURN NULL; -- No ha pasado suficiente tiempo para calcular
        END IF;

        IF v_velocidad_promedio > 0 THEN
            v_dias_restantes := (v_meta.valor_meta - v_meta.progreso_actual) / v_velocidad_promedio;
            RETURN TRUNC(SYSDATE) + CEIL(v_dias_restantes);
        ELSE
            RETURN NULL; -- Sin progreso, no se puede estimar
        END IF;
    END;

END PKG_METAS_AUTOMATIZACION;
/

--==============================================================================
-- CONFIGURACIÓN DE JOBS (DBMS_SCHEDULER) PARA EJECUTAR LAS TAREAS
--==============================================================================
BEGIN
    -- Eliminar jobs si ya existen para evitar errores en re-ejecución
    BEGIN DBMS_SCHEDULER.DROP_JOB('JOB_VERIFICAR_VENCIMIENTOS_METAS', force => TRUE); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN DBMS_SCHEDULER.DROP_JOB('JOB_DETECTAR_METAS_SIN_PROGRESO', force => TRUE); EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Job que se ejecuta todos los días a las 8 AM
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'JOB_VERIFICAR_VENCIMIENTOS_METAS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_METAS_AUTOMATIZACION.job_verificar_vencimientos; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=8; BYMINUTE=0;',
        enabled         => TRUE,
        comments        => 'Verifica metas que están próximas a vencer y envía recordatorios.'
    );

    -- Job que se ejecuta todos los días a las 9 AM
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'JOB_DETECTAR_METAS_SIN_PROGRESO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_METAS_AUTOMATIZACION.job_detectar_metas_sin_progreso; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=9; BYMINUTE=0;',
        enabled         => TRUE,
        comments        => 'Detecta metas activas sin actualizaciones de progreso recientes.'
    );
END;
/
