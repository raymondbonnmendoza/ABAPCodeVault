  METHOD /iwbep/if_mgw_appl_srv_runtime~get_stream.

    DATA :  ls_stream        TYPE ty_s_media_resource,
            ls_upload        TYPE zsd_so_attachment,
            lv_vbeln         TYPE vbak-vbeln,
            lv_filename      TYPE c LENGTH 100,
            lv_ext           TYPE string,
            lv_dummy         TYPE string,
            lv_document_id   TYPE sofolenti1-doc_id,
            lv_length        TYPE i,
            ls_object_header TYPE solisti1,
            header           TYPE ihttpnvp,
            lt_key_tab       TYPE /iwbep/t_mgw_tech_pairs,
            lt_nav           TYPE /iwbep/t_mgw_tech_navi,
            ls_nav           LIKE LINE OF lt_nav.

    DATA: lt_activitygroups TYPE TABLE OF BAPIAGR,
          ls_activitygroups TYPE BAPIAGR,
          lt_return         TYPE TABLE OF bapiret2,
          r_agr             LIKE RANGE OF ls_activitygroups-agr_name,
          ls_agr            LIKE LINE OF r_agr.

    DATA: srch_str         TYPE string,
          lt_results       TYPE TABLE OF TOARS_S,
          lt_TBL1024       TYPE TABLE OF TBL1024,
          lv_filename_temp LIKE lv_filename.

    FIELD-SYMBOLS: <fs_key> LIKE LINE OF lt_key_tab.

    lt_key_tab = io_tech_request_context->get_keys( ).
*   lt_nav = io_tech_request_context->get_navigation_path( ).
*   READ TABLE lt_nav INTO ls_nav INDEX 1.
*   APPEND LINES OF ls_nav-key_tab TO lt_key_tab.
    LOOP AT lt_key_tab ASSIGNING <fs_key>.
      CASE <fs_key>-name.
        WHEN 'DOCUMENTNUMBER'.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = <fs_key>-value
            IMPORTING
              output = lv_vbeln.
        WHEN 'FILENAME'.
          lv_filename = <fs_key>-value.
          TRANSLATE lv_filename TO UPPER CASE.
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

    SELECT * FROM srgbtbrel INTO TABLE @DATA(lt_srgbtbrel)
     WHERE instid_a EQ @lv_vbeln.

    DATA: ls_document_data  TYPE sofolenti1,
          lt_object_header  TYPE TABLE OF solisti1,
          lt_object_content TYPE TABLE OF solisti1,
          lt_contents_hex   TYPE TABLE OF solix,
          ls_srgbtbrel      TYPE srgbtbrel.

    LOOP AT lt_srgbtbrel INTO ls_srgbtbrel.
      lv_document_id = ls_srgbtbrel-instid_b.
      CALL FUNCTION 'SO_DOCUMENT_READ_API1'
        EXPORTING
          document_id                = lv_document_id
        IMPORTING
          document_data              = ls_document_data
        TABLES
          object_header              = lt_object_header
          object_content             = lt_object_content
          contents_hex               = lt_contents_hex
        EXCEPTIONS
          document_id_not_exist      = 1
          operation_no_authorization = 2
          x_error                    = 3
          OTHERS                     = 4.
      IF sy-subrc <> 0.
        CONTINUE.
      ELSE.
        CLEAR ls_upload.
        LOOP AT lt_object_header INTO ls_object_header.
          IF ls_object_header-line CS 'SO_FILENAME'.
            SPLIT ls_object_header-line AT '=' INTO lv_dummy ls_upload-filename.
          ENDIF.
        ENDLOOP.
        IF ls_upload IS NOT INITIAL.
          TRANSLATE ls_upload-filename TO UPPER CASE.
          IF ls_upload-filename EQ lv_filename.
            EXIT.
          ELSE.
            CLEAR ls_upload.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDLOOP.

    IF ls_upload IS INITIAL.
*     Check archived attachments
      CONCATENATE lv_vbeln '%' INTO srch_str.
      SELECT * FROM toa01 INTO TABLE @DATA(lt_toa01)
       WHERE sap_object EQ   'VBAK'
         AND object_id  LIKE @srch_str.

      LOOP AT lt_toa01 INTO DATA(ls_toa01).
        lv_filename_temp = lv_filename.
        REFRESH lt_results.
        CALL FUNCTION 'ALINK_RFC_DOCUMENTS_GET'
          EXPORTING
            im_botype        = ls_toa01-sap_object
            im_boid          = ls_toa01-object_id
          TABLES
            EX_RESULTS       = lt_results.
        READ TABLE lt_results INTO DATA(ls_results) INDEX 1.
        IF sy-subrc EQ 0.
          TRANSLATE ls_results-ddesc TO UPPER CASE.
          REPLACE ls_results-ddesc IN lv_filename_temp WITH space.
          REPLACE '_' IN lv_filename_temp WITH space.
          REPLACE '.' IN lv_filename_temp WITH space.
          REPLACE ls_results-docclass IN lv_filename_temp WITH space.
          CONDENSE lv_filename_temp.
          IF ls_results-docid EQ lv_filename_temp.
            ls_upload-filename = lv_filename.
            ls_upload-mimetype = ls_results-mimetype.
            call function 'ALINK_RFC_TABLE_GET'
              exporting
                im_docid    = ls_results-docid
                im_crepid   = ls_results-crepid
              importing
                ex_length   = lv_length
              tables
                ex_document = lt_TBL1024.
           call method cl_rmps_general_functions=>convert_1024_to_255
             exporting
               im_tab_1024 = lt_TBL1024
             receiving
               re_tab_255  = lt_contents_hex.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF ls_upload IS NOT INITIAL.
      header-name  = 'Content-Disposition'.
      header-value = |inline;filename="{ ls_upload-filename }"|.
      set_header( header ).
      IF lv_length IS INITIAL.
        lv_length = ls_document_data-doc_size.
      ENDIF.
      IF ls_upload-mimetype IS INITIAL.
        ls_upload-mimetype = ls_document_data-obj_type.
        TRANSLATE ls_upload-mimetype TO LOWER CASE.
        SELECT SINGLE type FROM sdokmime INTO ls_upload-mimetype
         WHERE extension EQ ls_upload-mimetype.
      ENDIF.
      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
        EXPORTING
          input_length = lv_length
        IMPORTING
          buffer       = ls_stream-value
        TABLES
          binary_tab   = lt_contents_hex
        EXCEPTIONS
          failed       = 1
          OTHERS       = 2.
      ls_stream-mime_type = ls_upload-mimetype.
      copy_data_to_ref( EXPORTING is_data = ls_stream
                        CHANGING  cr_data = er_stream ).
    ENDIF.

  ENDMETHOD.