-- SCRIPT DE EXPORTACIÓN DE PÁGINA DE APEX
-- PROYECTO: Seguimiento de Metas POA Institucional
-- PÁGINA: 2 - Formulario de Carga de Metas
-- DESCRIPCIÓN: Al ejecutar este script en el Taller de SQL, se creará
--              la página 2 con todos sus componentes (región, elementos,
--              botones y procesos) ya configurados.

set define off
--
prompt --application/pages/page_00002
--
begin
--
-- Import de la Página 2
--
wwv_flow_api.create_page(
  p_id=>2,
  p_user_interface_id=>wwv_flow_api.id(123456789), -- Reemplaza con el ID de tu UI si lo conoces, si no, APEX lo ajustará
  p_name=>'Formulario de Carga de Metas',
  p_alias=>'FORMULARIO-DE-CARGA-DE-METAS',
  p_page_mode=>'MODAL',
  p_step_title=>'Formulario de Carga de Metas',
  p_autocomplete_on_off=>'OFF',
  p_page_template_options=>'#DEFAULT#:ui-dialog--stretch:t-Dialog--noPadding',
  p_last_updated_by=>'JULES_AI',
  p_last_upd_yyyymmddhh24miss=>'20231029110000'
);

-- == REGIÓN PRINCIPAL ==
wwv_flow_api.create_page_plug(
  p_id=>wwv_flow_api.id(1001),
  p_plug_name=>'Nueva Meta del POA',
  p_region_template_options=>'#DEFAULT#',
  p_plug_template=>wwv_flow_api.id(987654321), -- Reemplaza con el ID de tu template de región, si no, APEX lo ajustará
  p_plug_display_sequence=>10,
  p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);

-- == ELEMENTOS (ITEMS/CAMPOS) DEL FORMULARIO ==

-- P2_NOMBRE_INDICADOR (Campo de Texto, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2001),
  p_name=>'P2_NOMBRE_INDICADOR',
  p_item_sequence=>10,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Nombre del Indicador',
  p_display_as=>'NATIVE_TEXT_FIELD',
  p_cSize=>60,
  p_cMaxlength=>300,
  p_field_template=>wwv_flow_api.id(1122334455), -- Reemplaza con tu template, APEX lo ajustará
  p_is_required=>true
);

-- P2_ID_UNIDAD_RESPONSABLE (Lista de Selección, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2002),
  p_name=>'P2_ID_UNIDAD_RESPONSABLE',
  p_item_sequence=>20,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Unidad Responsable',
  p_display_as=>'NATIVE_SELECT_LIST',
  p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
    'SELECT TITULO d, ID_UNIDAD_ADMINISTRATIVA r',
    'FROM SYS_UNIDAD_ADMINISTRATIVA',
    'START WITH ID_UNIDAD_ADMINISTRATIVA = :UNIDAD_ID_USUARIO_LOGUEADO',
    'CONNECT BY CUA_PADRE = PRIOR CUA',
    'ORDER BY TITULO'
  )),
  p_lov_display_extra=>'NO',
  p_cHeight=>1,
  p_field_template=>wwv_flow_api.id(1122334455),
  p_is_required=>true
);

-- P2_FORMULA (Área de Texto)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2003),
  p_name=>'P2_FORMULA',
  p_item_sequence=>30,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Fórmula',
  p_display_as=>'NATIVE_TEXTAREA',
  p_cSize=>60,
  p_cHeight=>4,
  p_field_template=>wwv_flow_api.id(1122334455)
);

-- P2_META_VALOR (Campo Numérico, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2004),
  p_name=>'P2_META_VALOR',
  p_item_sequence=>40,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Valor de la Meta',
  p_display_as=>'NATIVE_NUMBER_FIELD',
  p_cSize=>30,
  p_field_template=>wwv_flow_api.id(1122334455),
  p_is_required=>true
);

-- P2_FECHA_META (Selector de Fecha)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2005),
  p_name=>'P2_FECHA_META',
  p_item_sequence=>50,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Fecha de la Meta',
  p_display_as=>'NATIVE_DATE_PICKER',
  p_cSize=>30,
  p_field_template=>wwv_flow_api.id(1122334455)
);

-- P2_PERIODICIDAD (Lista de Selección)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(2006),
  p_name=>'P2_PERIODICIDAD',
  p_item_sequence=>60,
  p_item_plug_id=>wwv_flow_api.id(1001),
  p_prompt=>'Periodicidad',
  p_display_as=>'NATIVE_SELECT_LIST',
  p_lov=>'STATIC:MENSUAL;MENSUAL,BIMESTRAL;BIMESTRAL,TRIMESTRAL;TRIMESTRAL,SEMESTRAL;SEMESTRAL,ANUAL;ANUAL',
  p_lov_display_extra=>'NO',
  p_cHeight=>1,
  p_field_template=>wwv_flow_api.id(1122334455)
);

-- ... (Otros campos como LINEA_BASE, UNIDAD_MEDIDA, RANGO_TOLERANCIA pueden añadirse de la misma forma) ...

-- == BOTONES ==

-- Botón CANCELAR
wwv_flow_api.create_page_button(
  p_id=>wwv_flow_api.id(3001),
  p_button_sequence=>10,
  p_button_plug_id=>wwv_flow_api.id(1001),
  p_button_name=>'CANCELAR',
  p_button_action=>'DEFINED_BY_DA',
  p_button_template_options=>'#DEFAULT#',
  p_button_template_id=>wwv_flow_api.id(5566778899), -- Reemplaza, APEX lo ajustará
  p_button_image_alt=>'Cancelar',
  p_button_position=>'CLOSE'
);
wwv_flow_api.create_page_da_event(
    p_id=>wwv_flow_api.id(3002),
    p_name=>'DA_CANCELAR',
    p_event_sequence=>10,
    p_triggering_element_type=>'BUTTON',
    p_triggering_button_id=>wwv_flow_api.id(3001),
    p_bind_type=>'bind',
    p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
    p_id=>wwv_flow_api.id(3003),
    p_event_id=>wwv_flow_api.id(3002),
    p_event_result=>'TRUE',
    p_action_sequence=>10,
    p_execute_on_page_init=>'N',
    p_action=>'NATIVE_DIALOG_CANCEL'
);


-- Botón CREAR
wwv_flow_api.create_page_button(
  p_id=>wwv_flow_api.id(3004),
  p_button_sequence=>20,
  p_button_plug_id=>wwv_flow_api.id(1001),
  p_button_name=>'CREAR',
  p_button_action=>'SUBMIT',
  p_button_template_options=>'#DEFAULT#:t-Button--hot',
  p_button_template_id=>wwv_flow_api.id(5566778899),
  p_button_is_hot=>'Y',
  p_button_image_alt=>'Crear Meta',
  p_button_position=>'CREATE'
);


-- == PROCESOS (LOGICA DE GUARDADO) ==

-- Proceso que llama al paquete PL/SQL para guardar la meta
wwv_flow_api.create_page_process(
  p_id=>wwv_flow_api.id(4001),
  p_process_sequence=>10,
  p_process_point=>'AFTER_SUBMIT',
  p_process_type=>'NATIVE_PLSQL',
  p_process_name=>'Guardar Nueva Meta',
  p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
    'BEGIN',
    '    PKG_POA_CARGA.crear_meta(',
    '        p_nombre_indicador      => :P2_NOMBRE_INDICADOR,',
    '        p_formula               => :P2_FORMULA,',
    '        p_linea_base            => :P2_LINEA_BASE,',
    '        p_meta_valor            => :P2_META_VALOR,',
    '        p_unidad_medida         => :P2_UNIDAD_MEDIDA,',
    '        p_fecha_meta            => :P2_FECHA_META,',
    '        p_rango_tolerancia      => :P2_RANGO_TOLERANCIA,',
    '        p_periodicidad          => :P2_PERIODICIDAD,',
    '        p_id_unidad_responsable => :P2_ID_UNIDAD_RESPONSABLE,',
    '        p_usuario_creador       => :APP_USER',
    '    );',
    'END;'
  )),
  p_process_when_button_id=>wwv_flow_api.id(3004),
  p_process_success_message=>'Meta creada con éxito.'
);

-- Proceso para cerrar la ventana modal después de guardar
wwv_flow_api.create_page_process(
  p_id=>wwv_flow_api.id(4002),
  p_process_sequence=>20,
  p_process_point=>'AFTER_SUBMIT',
  p_process_type=>'NATIVE_CLOSE_DIALOG',
  p_process_name=>'Cerrar Diálogo',
  p_process_when_button_id=>wwv_flow_api.id(3004)
);

--
end;
/
set define on
--
prompt --application/end_environment
--
commit;
--
-- end of script
--
