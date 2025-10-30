-- SCRIPT DE MODIFICACIÓN DE PÁGINA DE APEX
-- PROYECTO: Seguimiento de Metas POA Institucional
-- PÁGINA: 11 - Formulario de Carga de Metas
-- DESCRIPCIÓN: Este script MODIFICA la página 11 existente en la aplicación
--              actual, añadiendo todos los componentes del formulario.

begin
    -- Establecer el contexto de la aplicación y página
    apex_application_install.set_application_id(101);
    apex_application_install.set_page_id(11);
end;
/

begin
-- == REGIÓN PRINCIPAL ==
wwv_flow_api.create_page_plug(
  p_id=>wwv_flow_api.id(1011), -- ID nuevo para esta región
  p_plug_name=>'Nueva Meta del POA',
  p_region_template_options=>'#DEFAULT#',
  p_plug_template=>wwv_flow_api.id(987654321), -- APEX ajustará este ID a tu template por defecto
  p_plug_display_sequence=>10,
  p_plug_query_options=>'DERIVED_REPORT_COLUMNS',
  p_page_id => 11
);

-- == ELEMENTOS (ITEMS/CAMPOS) DEL FORMULARIO ==
-- P11_NOMBRE_INDICADOR (Campo de Texto, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(1101), -- ID nuevo
  p_name=>'P11_NOMBRE_INDICADOR',
  p_item_sequence=>10,
  p_item_plug_id=>wwv_flow_api.id(1011),
  p_prompt=>'Nombre del Indicador',
  p_display_as=>'NATIVE_TEXT_FIELD',
  p_cSize=>60,
  p_cMaxlength=>300,
  p_field_template=>wwv_flow_api.id(1122334455), -- APEX ajustará
  p_is_required=>true,
  p_page_id => 11
);

-- P11_ID_UNIDAD_RESPONSABLE (Lista de Selección, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(1102),
  p_name=>'P11_ID_UNIDAD_RESPONSABLE',
  p_item_sequence=>20,
  p_item_plug_id=>wwv_flow_api.id(1011),
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
  p_is_required=>true,
  p_page_id => 11
);

-- P11_META_VALOR (Campo Numérico, Obligatorio)
wwv_flow_api.create_page_item(
  p_id=>wwv_flow_api.id(1103),
  p_name=>'P11_META_VALOR',
  p_item_sequence=>30,
  p_item_plug_id=>wwv_flow_api.id(1011),
  p_prompt=>'Valor de la Meta',
  p_display_as=>'NATIVE_NUMBER_FIELD',
  p_cSize=>30,
  p_field_template=>wwv_flow_api.id(1122334455),
  p_is_required=>true,
  p_page_id => 11
);

-- (Se pueden añadir más campos aquí de la misma forma)

-- == BOTONES ==
wwv_flow_api.create_page_button(
  p_id=>wwv_flow_api.id(1111), -- ID nuevo
  p_button_sequence=>10,
  p_button_plug_id=>wwv_flow_api.id(1011),
  p_button_name=>'CANCELAR',
  p_button_action=>'REDIRECT_PAGE',
  p_button_template_options=>'#DEFAULT#',
  p_button_template_id=>wwv_flow_api.id(5566778899), -- APEX ajustará
  p_button_image_alt=>'Cancelar',
  p_button_position=>'CLOSE',
  p_button_redirect_url=>'javascript:apex.navigation.dialog.cancel(true);',
  p_page_id => 11
);
wwv_flow_api.create_page_button(
  p_id=>wwv_flow_api.id(1112),
  p_button_name=>'CREAR',
  p_button_sequence=>20,
  p_button_plug_id=>wwv_flow_api.id(1011),
  p_button_action=>'SUBMIT',
  p_button_template_options=>'#DEFAULT#:t-Button--hot',
  p_button_template_id=>wwv_flow_api.id(5566778899),
  p_button_is_hot=>'Y',
  p_button_image_alt=>'Crear Meta',
  p_button_position=>'CREATE',
  p_page_id => 11
);

-- == PROCESOS ==
wwv_flow_api.create_page_process(
  p_id=>wwv_flow_api.id(1121), -- ID nuevo
  p_process_sequence=>10,
  p_process_point=>'AFTER_SUBMIT',
  p_process_type=>'NATIVE_PLSQL',
  p_process_name=>'Guardar Nueva Meta',
  p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
    'BEGIN',
    '    PKG_POA_CARGA.crear_meta(',
    '        p_nombre_indicador      => :P11_NOMBRE_INDICADOR,',
    '        p_formula               => null,',
    '        p_linea_base            => null,',
    '        p_meta_valor            => :P11_META_VALOR,',
    '        p_unidad_medida         => null,',
    '        p_fecha_meta            => null,',
    '        p_rango_tolerancia      => null,',
    '        p_periodicidad          => null,',
    '        p_id_unidad_responsable => :P11_ID_UNIDAD_RESPONSABLE,',
    '        p_usuario_creador       => :APP_USER',
    '    );',
    'END;'
  )),
  p_process_when_button_id=>wwv_flow_api.id(1112),
  p_process_success_message=>'Meta creada con éxito.',
  p_page_id => 11
);
wwv_flow_api.create_page_process(
  p_id=>wwv_flow_api.id(1122),
  p_process_sequence=>20,
  p_process_point=>'AFTER_SUBMIT',
  p_process_type=>'NATIVE_CLOSE_DIALOG',
  p_process_name=>'Cerrar Diálogo',
  p_process_when_button_id=>wwv_flow_api.id(1112),
  p_page_id => 11
);
end;
/

commit;
