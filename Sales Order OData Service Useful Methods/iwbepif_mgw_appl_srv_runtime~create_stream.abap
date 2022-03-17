METHOD /iwbep/if_mgw_appl_srv_runtime~create_stream.

    DATA: lv_vbeln   TYPE vbak-vbeln,
          lt_key_tab TYPE /iwbep/t_mgw_tech_pairs.

    FIELD-SYMBOLS: <fs_key> LIKE LINE OF lt_key_tab.

    DATA: lt_activitygroups TYPE TABLE OF bapiagr,
          ls_activitygroups TYPE bapiagr,
          lt_return         TYPE TABLE OF bapiret2,
          r_agr             LIKE RANGE OF ls_activitygroups-agr_name,
          ls_agr            LIKE LINE OF r_agr.


    lt_key_tab = io_tech_request_context->get_source_keys( ).
    LOOP AT lt_key_tab ASSIGNING <fs_key>.
      CASE <fs_key>-name.
        WHEN 'SALESORDERNUMBER'.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = <fs_key>-value
            IMPORTING
              output = lv_vbeln.
        WHEN OTHERS.
          me->/iwbep/if_sb_dpc_comm_services~log_message(
            EXPORTING
              iv_msg_type   = 'E'
              iv_msg_id     = '/IWBEP/MC_SB_DPC_ADM'
              iv_msg_number = 021
              iv_msg_v1     = <fs_key>-name ).
          " Raise Exception
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              textid = /iwbep/cx_mgw_tech_exception=>internal_error.
      ENDCASE.
    ENDLOOP.

*   lw_file-mimetype = is_media_resource-mime_type.

    DATA:
      object           TYPE borident,
      attachment       TYPE borident,
      folder_id        TYPE sofdk,
      lt_objcont_hex   TYPE STANDARD TABLE OF solix,
      lt_objhead       TYPE STANDARD TABLE OF solisti1,
      lt_objcont       TYPE STANDARD TABLE OF solisti1,
      dinfo            TYPE sofolenti1,
      docdata          TYPE sodocchgi1,
      file_ext         TYPE sood-file_ext,
      file_name_length TYPE i,
      file_name(255)   TYPE c,
      sood             TYPE sood,
      codepage         TYPE cpcodepage.

    object-objkey = lv_vbeln.
    object-objtype = 'BUS2032'.

    file_name = iv_slug.

    CALL FUNCTION 'TRINT_FILE_GET_EXTENSION'
      EXPORTING
        filename  = file_name
        uppercase = ' '
      IMPORTING
        extension = file_ext.


    file_name_length = strlen( iv_slug ) - strlen( file_ext ) - 1.
    file_name = iv_slug(file_name_length).

    APPEND |&SO_FILENAME={ iv_slug }| TO lt_objhead.
    IF is_media_resource-mime_type(4) = 'text'.
      APPEND '&SO_FORMAT=ASC' TO lt_objhead.
      cl_bcs_convert=>htmlbin_to_htmltxt(
        EXPORTING
          iv_html = is_media_resource-value
        IMPORTING
          et_html = lt_objcont
          ev_codepage = codepage ).
    ELSE.
      APPEND '&SO_FORMAT=EXT' TO lt_objhead.
      lt_objcont_hex = cl_bcs_convert=>xstring_to_solix( is_media_resource-value ).
    ENDIF.

    docdata-obj_name = 'MESSAGE'.
    docdata-obj_descr = file_name.
    docdata-obj_langu = sy-langu.
    docdata-doc_size = xstrlen( is_media_resource-value ).


    CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
      EXPORTING
        region    = 'B'
      IMPORTING
        folder_id = folder_id
      EXCEPTIONS
        OTHERS    = 1.

    IF sy-subrc <> 0.
      log_to_header(
        type = 'E'
        id = 'ZWOT'
        number = '005'
        field = 'Attachment' ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'SO_DOCUMENT_INSERT_API1'
      EXPORTING
        folder_id                  = folder_id ##COMPATIBLE
        document_data              = docdata
        document_type              = 'EXT'
      IMPORTING
        document_info              = dinfo
      TABLES
        object_header              = lt_objhead
        object_content             = lt_objcont
        contents_hex               = lt_objcont_hex
      EXCEPTIONS
        folder_not_exist           = 1
        document_type_not_exist    = 2
        operation_no_authorization = 3
        parameter_error            = 4
        x_error                    = 5
        enqueue_error              = 6
        OTHERS                     = 7.

    IF sy-subrc <> 0.
      log_to_header(
        type = 'E'
        id = 'ZWOT'
        number = '005'
        field = 'Attachment' ).
      RETURN.
    ENDIF.

    attachment-objtype = 'MESSAGE'.
    attachment-objkey = dinfo-doc_id.

    CALL FUNCTION 'BINARY_RELATION_CREATE'
      EXPORTING
        obj_rolea    = object
        obj_roleb    = attachment
        relationtype = 'ATTA'
      EXCEPTIONS
        OTHERS       = 1.

* File extension must be set, but is deliberately not set by the standard API
    SELECT SINGLE *
      INTO sood
      FROM sood
      WHERE
        objtp = dinfo-object_id(3) AND
        objyr = dinfo-object_id+3(2) AND
        objno = dinfo-object_id+5.

    sood-file_ext = file_ext.
    UPDATE sood FROM sood.

    COMMIT WORK.

    DATA: ls_entity TYPE zsd_so_attachment.
    ls_entity-filename = iv_slug.
    ls_entity-mimetype = is_media_resource-mime_type.
    copy_data_to_ref(
      EXPORTING
        is_data = ls_entity
      CHANGING
        cr_data = er_entity ).

  ENDMETHOD.