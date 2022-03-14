DATA: l_s_log       TYPE bal_s_log,                             "Log header data
        lo_log        TYPE REF TO if_reca_message_list,
        lv_handle     TYPE balloghndl,
        ls_msg_header TYPE bal_s_log,
        ls_msg        TYPE z_msg_struct,
        lv_status     TYPE string.

  CONSTANTS: lc_object TYPE balobj_d VALUE 'Z_SAVE',
             lc_sub    TYPE balsubobj VALUE 'Z_SUB_SAVE'.

  *create lc_object and lc_sub in tcode SLG0
  lo_log = cf_reca_message_list=>create( id_object = lc_object
                                         id_subobject = lc_sub ).                 "Get logging instance

  lv_handle = lo_log->get_handle( ).

  ls_msg_header-extnumber = im_idocnum.
  ls_msg_header-object = lc_object.
  ls_msg_header-subobject = lc_sub.

  lo_log->change_header( EXPORTING is_msg_header = ls_msg_header ).

  LOOP AT im_msg INTO ls_msg.
    CONCATENATE ls_msg-status ls_msg-status_code INTO lv_status SEPARATED BY space.
    IF ls_msg-status_code = '200'.
      lo_log->add( EXPORTING id_msgty = 'S'
                             id_msgid = 'Z'
                             id_msgno = '000'
                             id_msgv1 = ls_msg-employee_id
                             id_msgv2 = lv_status
                             id_msgv3 = ls_msg-message
                             id_msgv4 = ls_msg-extended_message
                             id_sublog = lv_handle ).
    ELSE.
      lo_log->add( EXPORTING id_msgty = 'E'
                         id_msgid = 'Z'
                         id_msgno = '000'
                         id_msgv1 = ls_msg-employee_id
                         id_msgv2 = lv_status
                         id_msgv3 = ls_msg-message
                         id_msgv4 = ls_msg-extended_message
                         id_sublog = lv_handle ).
    ENDIF.
    CLEAR ls_msg.
  ENDLOOP.


  lo_log->store( if_in_update_task = ' ' ).                                         "Store message
