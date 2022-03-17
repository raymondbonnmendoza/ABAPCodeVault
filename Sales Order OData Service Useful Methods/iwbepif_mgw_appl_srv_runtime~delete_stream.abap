  METHOD /iwbep/if_mgw_appl_srv_runtime~delete_stream.

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
            lt_key_tab       TYPE /iwbep/t_mgw_tech_pairs.

    DATA: lt_activitygroups TYPE TABLE OF BAPIAGR,
          ls_activitygroups TYPE BAPIAGR,
          lt_return         TYPE TABLE OF bapiret2,
          r_agr             LIKE RANGE OF ls_activitygroups-agr_name,
          ls_agr            LIKE LINE OF r_agr.

    FIELD-SYMBOLS: <fs_key> LIKE LINE OF lt_key_tab.

    lt_key_tab = io_tech_request_context->get_keys( ).
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

    DATA: ls_folder_id TYPE soodk,
          ls_object_id TYPE soodk,
          ls_object    TYPE borident,
          ls_folmem_k  TYPE sofmk,
          ls_note      TYPE borident,
          lv_ep_note   TYPE borident-objkey.

    IF ls_upload IS NOT INITIAL.
      ls_folder_id      = lv_document_id.
      ls_object_id      = ls_document_data-object_id.
      ls_object-objkey  = lv_vbeln.
      ls_object-objtype = 'BUS2032'.
      ls_folmem_k-foltp = ls_folder_id-objtp.
      ls_folmem_k-folyr = ls_folder_id-objyr.
      ls_folmem_k-folno = ls_folder_id-objno.
      ls_folmem_k-doctp = ls_object_id-objtp.
      ls_folmem_k-docyr = ls_object_id-objyr.
      ls_folmem_k-docno = ls_object_id-objno.
      lv_ep_note        = ls_folmem_k.
      ls_note-objtype   = 'MESSAGE'.
      ls_note-objkey    = lv_ep_note.

      CALL FUNCTION 'BINARY_RELATION_DELETE_COMMIT'
        EXPORTING
          obj_rolea          = ls_object
          obj_roleb          = ls_note
          relationtype       = 'ATTA'
        EXCEPTIONS
          ENTRY_NOT_EXISTING = 1
          INTERNAL_ERROR     = 2
          NO_RELATION        = 3
          NO_ROLE            = 4
          OTHERS             = 5.
      IF sy-subrc EQ 0.
        COMMIT WORK.
      ELSE.
        me->/iwbep/if_sb_dpc_comm_services~rfc_exception_handling(
          EXPORTING
            iv_subrc            = sy-subrc
            iv_exp_message_text = 'Attachment delete failed' ).
      ENDIF.

      CALL FUNCTION 'SO_OBJECT_DELETE'
        EXPORTING
          folder_id                  = ls_folder_id
          object_id                  = ls_object_id
          put_in_wastebasket         = ' '
        EXCEPTIONS
          communication_failure      = 1
          folder_not_empty           = 2
          folder_not_exist           = 3
          folder_no_authorization    = 4
          forwarder_not_exist        = 5
          object_not_exist           = 6
          object_no_authorization    = 7
          operation_no_authorization = 8
          owner_not_exist            = 9
          substitute_not_active      = 10
          substitute_not_defined     = 11
          system_failure             = 12
          x_error                    = 13
          OTHERS                     = 14.
      IF sy-subrc EQ 0.
        COMMIT WORK.
      ELSE.
        me->/iwbep/if_sb_dpc_comm_services~rfc_exception_handling(
          EXPORTING
            iv_subrc            = sy-subrc
            iv_exp_message_text = 'Attachment delete failed' ).
      ENDIF.
    ENDIF.
  ENDMETHOD.