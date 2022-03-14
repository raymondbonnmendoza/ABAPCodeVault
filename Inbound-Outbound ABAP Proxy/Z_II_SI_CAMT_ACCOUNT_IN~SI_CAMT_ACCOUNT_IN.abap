method Z_II_SI_CAMT_ACCOUNT_IN~SI_CAMT_ACCOUNT_IN.

   DATA: lo_server_context      TYPE REF TO if_ws_server_context,
         lo_payload_protocol    TYPE REF TO if_wsprotocol,
         lo_attachment_protocol TYPE REF TO if_wsprotocol_attachments,
         ls_standard            TYPE z_exchange_fault_data,
         ls_detail              TYPE z_exchange_log_data,
         lt_attach              TYPE prx_attach,
         lo_attachment          TYPE REF TO if_ai_attachment,
         lv_kind                TYPE sychar01,
         lv_xstring             TYPE xstring,
         lv_string              TYPE string,
         lv_path_file           TYPE string,
         lv_error               TYPE string,
         lv_lenght              TYPE i,
         lv_path_key            TYPE feb_path,
         lv_directory           TYPE feb_directory,
         lv_filename            TYPE string.

* Load attachment
  TRY.
      lo_server_context = cl_proxy_access=>get_server_context( ).
      lo_payload_protocol = lo_server_context->get_protocol( if_wsprotocol=>payload ).
      lo_attachment_protocol ?=
      lo_server_context->get_protocol( if_wsprotocol=>attachments ).

      CALL METHOD lo_attachment_protocol->get_attachments
        RECEIVING
          attachments = lt_attach.

    CATCH cx_ai_system_fault.
*     Init error
      CLEAR: ls_standard, ls_detail.
      ls_detail-severity     = 'HIGH'.
      ls_standard-fault_text = 'Load of attachment failed'(001).
      APPEND ls_detail TO ls_standard-fault_detail.
*     Rasie error
      RAISE EXCEPTION TYPE z_cx_exchange_fault_data
        EXPORTING
          standard = ls_standard.
  ENDTRY.

* Get and convert attachment from XML to String
  LOOP AT lt_attach INTO lo_attachment.

    CLEAR lv_kind.
    CALL METHOD lo_attachment->get_kind
      RECEIVING
        p_kind = lv_kind.

    IF lv_kind NE space.
      CALL METHOD lo_attachment->get_binary_data
        RECEIVING
          p_data = lv_xstring.
    ENDIF.

    CALL FUNCTION 'LXE_COMMON_XSTRING_TO_STRING'
      EXPORTING
        in_xstring  = lv_xstring
      IMPORTING
        ex_string   = lv_string
      EXCEPTIONS
        error       = 1
        OTHERS      = 2.

    IF sy-subrc NE 0.
*     Init error
      CLEAR: ls_standard, ls_detail.
      ls_detail-severity     = 'HIGH'.
      ls_standard-fault_text = 'XML not converted to string'(002).
      APPEND ls_detail TO ls_standard-fault_detail.
*     Rasie error
      RAISE EXCEPTION TYPE z_cx_exchange_fault_data
        EXPORTING
          standard = ls_standard.
    ENDIF.

  ENDLOOP.

* Find path
  CLEAR: lv_path_file, lv_error, ls_standard.

  lv_path_key = input-mt_camt_inbound_xml-sending_bank.

  SELECT SINGLE directory INTO lv_directory FROM feb_filepath
    WHERE path EQ lv_path_key.

  IF sy-subrc NE 0.
    CONCATENATE text-004 lv_path_key INTO lv_error SEPARATED BY space.
  ELSE.
*   Replace with sy
    REPLACE text-006 IN lv_directory WITH sy-sysid.

*   Find filename
    CLEAR lv_filename.
    IF input-mt_camt_inbound_xml-filename IS NOT INITIAL.
*     From bank
      lv_filename = input-mt_camt_inbound_xml-filename.
    ELSE.
*     Generate file name
      CONCATENATE input-mt_camt_inbound_xml-sending_bank
                  sy-datum
                  sy-uzeit
                  text-005 INTO lv_filename.
    ENDIF.

*   Update final path and file
    CONCATENATE lv_directory lv_filename INTO lv_path_file.
    CONDENSE lv_path_file.
  ENDIF.

  IF lv_error IS NOT INITIAL.
*   Init error
    CLEAR: ls_standard, ls_detail.
    ls_detail-severity     = 'HIGH'.
    ls_standard-fault_text = lv_error.
    APPEND ls_detail TO ls_standard-fault_detail.
*   Rasie error
    RAISE EXCEPTION TYPE z_cx_exchange_fault_data
      EXPORTING
        standard = ls_standard.
  ENDIF.

* Write file
  OPEN DATASET lv_path_file FOR OUTPUT IN TEXT MODE
    ENCODING UTF-8 IGNORING CONVERSION ERRORS.

  lv_lenght = strlen( lv_string ).
  TRANSFER lv_string TO lv_path_file LENGTH lv_lenght.

* Close the created data files
  CLOSE DATASET lv_path_file.

ENDMETHOD.
