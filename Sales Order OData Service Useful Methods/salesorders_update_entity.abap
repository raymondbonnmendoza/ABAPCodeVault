  METHOD salesorders_update_entity.

    DATA: ls_salesorder        TYPE sra017_s_so_header,
          lv_vbeln             TYPE vbak-vbeln,
          lt_key_tab           TYPE /iwbep/t_mgw_tech_pairs,
          ls_keys              TYPE /iwbep/s_mgw_tech_pair,
          lo_message_container TYPE REF TO /iwbep/if_message_container,
          ls_message           TYPE scx_t100key,
          ls_header_in         TYPE bapisdh1,
          ls_header_inx        TYPE bapisdh1x,
          lt_return            TYPE TABLE OF bapiret2,
          ls_return            TYPE bapiret2,
          lt_item_in           TYPE TABLE OF bapisditm,
          lt_item_inx	         TYPE TABLE OF bapisditmx,
          ls_item_in           TYPE bapisditm,
          ls_item_inx	         TYPE bapisditmx,
          ls_vbap              TYPE vbap,
          lt_extensionin       TYPE TABLE OF bapiparex,
          lt_extensionex       TYPE TABLE OF bapiparex,
          ls_extensionin       TYPE bapiparex,
          ls_extensionex       TYPE bapiparex.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_salesorder ).
    er_entity = ls_salesorder.

    lt_key_tab = io_tech_request_context->get_keys( ).

    LOOP AT lt_key_tab INTO ls_keys.
      CASE ls_keys-name.
        WHEN 'SALESORDERNUMBER'.
          
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = ls_keys-value
            IMPORTING
              output = lv_vbeln.
        WHEN OTHERS.
          " Log message in the application log
          me->/iwbep/if_sb_dpc_comm_services~log_message(
            EXPORTING
              iv_msg_type   = 'E'
              iv_msg_id     = '/IWBEP/MC_SB_DPC_ADM'
              iv_msg_number = 021
              iv_msg_v1     = ls_keys-name ).
          " Raise Exception
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              textid = /iwbep/cx_mgw_tech_exception=>internal_error.
      ENDCASE.
    ENDLOOP.

    DATA: lv_checkmbdat TYPE xfeld,
          lv_nonworkday TYPE xfeld,
          lv_plant      TYPE werks_d,
          lv_mbdat      TYPE vbep-mbdat.

    SELECT SINGLE vdatu FROM vbak INTO @DATA(lv_vdatu)
     WHERE vbeln EQ @lv_vbeln.
    SELECT * FROM vbap INTO TABLE @DATA(lt_vbap)
     WHERE vbeln EQ @lv_vbeln.
    SELECT *
      INTO TABLE @DATA(lt_vbep)
      FROM vbep
      WHERE vbeln = @lv_vbeln.

*   STANDARD
    IF ls_salesorder-po IS NOT INITIAL.
      ls_header_in-purch_no_c  = ls_salesorder-po.
      ls_header_inx-purch_no_c = 'X'.
    ENDIF.
    IF ls_salesorder-zzrequesteddatedisplay IS NOT INITIAL.
      TRY .
          ls_header_in-req_date_h  = convert_date_to_sapintern( ls_salesorder-zzrequesteddatedisplay ).
          ls_header_inx-req_date_h = 'X'.
          IF ls_header_in-req_date_h NE lv_vdatu.
            lv_checkmbdat = abap_true.
          ENDIF.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '003'
            v1 = ls_salesorder-zzrequesteddatedisplay
            v2 = 'REQUESTED DELIVERY DATE'
            field = 'RequestedDate' ).
          RETURN.

      ENDTRY.
    ENDIF.
    IF ls_salesorder-zzpaymenttermscode IS NOT INITIAL.
      ls_header_in-pmnttrms  = ls_salesorder-zzpaymenttermscode.
      ls_header_inx-pmnttrms = 'X'.
    ENDIF.
    ls_header_in-compl_dlv  = ls_salesorder-singleshipmentindicator.
    ls_header_inx-compl_dlv = 'X'.
    IF ls_salesorder-currency IS NOT INITIAL.
      ls_header_in-currency  = ls_salesorder-currency.
      ls_header_inx-currency = 'X'.
    ENDIF.
    IF ls_salesorder-zztypeofpackagingmat IS NOT INITIAL.
      ls_header_in-cust_grp2  = ls_salesorder-zztypeofpackagingmat.
      ls_header_inx-cust_grp2 = 'X'.
    ENDIF.
    ls_header_in-cust_grp3  = ls_salesorder-zztypeofdemand.
    ls_header_inx-cust_grp3 = 'X'.
    IF ls_salesorder-zzpodate IS NOT INITIAL.
      TRY .
          ls_header_in-purch_date  = convert_date_to_sapintern( ls_salesorder-zzpodate ).
          ls_header_inx-purch_date = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '003'
            v1 = ls_salesorder-zzpodate
            v2 = 'PLACED ON'
            field = 'PODate' ).
          RETURN.

      ENDTRY.
    ENDIF.

*   ITEMS
    DATA: ls_bape_vbap  TYPE bape_vbap,
          ls_bape_vbapx TYPE bape_vbapx,
          lv_string     TYPE string,
          lv_count      TYPE i.

    LOOP AT lt_vbap INTO ls_vbap.
      CLEAR  ls_item_in.
      CLEAR  ls_item_inx.
      CLEAR ls_bape_vbap.
      CLEAR ls_bape_vbapx.

      ls_item_in-itm_number  = ls_item_inx-itm_number = ls_vbap-posnr.
      ls_item_inx-updateflag = 'U'.

      TRY .
          ls_item_in-overdlvtol  = convert_amount_to_sapintern( ls_salesorder-zzoverdlvtolerance ).
          ls_item_inx-overdlvtol = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '002'
            v1 = ls_salesorder-zzoverdlvtolerance
            v2 = 'TOLERANCE OVER DLV'
            field = 'OverDlvTolerance' ).
          RETURN.

        CATCH cx_sy_conversion_overflow.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '001'
            v1 = ls_salesorder-zzoverdlvtolerance
            v2 = 'TOLERANCE OVER DLV'
            field = 'OverDlvTolerance' ).
          RETURN.

      ENDTRY.

      TRY .
          ls_item_in-unddlv_tol  = convert_amount_to_sapintern( ls_salesorder-zzunderdlvtolerance ).
          ls_item_inx-unddlv_tol = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '002'
            v1 = ls_salesorder-zzunderdlvtolerance
            v2 = 'TOLERANCE UNDER DLV'
            field = 'UnderDlvTolerance' ).
          RETURN.

        CATCH cx_sy_conversion_overflow.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '001'
            v1 = ls_salesorder-zzunderdlvtolerance
            v2 = 'TOLERANCE UNDER DLV'
            field = 'UnderDlvTolerance' ).
          RETURN.

      ENDTRY.

      APPEND ls_item_in TO lt_item_in.
      APPEND ls_item_inx TO lt_item_inx.

      ls_bape_vbap-vbeln             = lv_vbeln.
      ls_bape_vbap-posnr             = ls_vbap-posnr.
      ls_bape_vbap-zzkvgr_un_ov_dlv  = ls_salesorder-zzallowunderoverdlv.
      ls_bape_vbapx-vbeln            = lv_vbeln.
      ls_bape_vbapx-posnr            = ls_vbap-posnr.
      ls_bape_vbapx-zzkvgr_un_ov_dlv = 'X'.

      lv_string = ls_bape_vbap.
      lv_count  = strlen( lv_string ).

      ls_extensionin-valuepart1 = lv_string.
      IF lv_count GT 240.
        ls_extensionin-valuepart2 = lv_string+240.
      ENDIF.
      IF lv_count GT 480.
        ls_extensionin-valuepart3 = lv_string+480.
      ENDIF.
      IF lv_count GT 720.
        ls_extensionin-valuepart4 = lv_string+720.
      ENDIF.

      ls_extensionin-structure  = 'BAPE_VBAP'.
      ls_extensionex-structure  = 'BAPE_VBAPX'.
      ls_extensionex-valuepart1 = ls_bape_vbapx.

      APPEND ls_extensionin TO lt_extensionin.
      APPEND ls_extensionex TO lt_extensionin.
    ENDLOOP.

*   Schedule lines
    DATA: lt_schedule  TYPE TABLE OF bapischdl,
          ls_schedule  TYPE bapischdl,
          lt_schedulex TYPE TABLE OF bapischdlx,
          ls_schedulex TYPE bapischdlx.

    LOOP AT lt_vbep ASSIGNING FIELD-SYMBOL(<vbep>).
      ls_schedulex-updateflag = 'U'.
      ls_schedule-itm_number = <vbep>-posnr.
      ls_schedule-sched_line = <vbep>-etenr.
      ls_schedulex-itm_number = <vbep>-posnr.
      ls_schedulex-sched_line = <vbep>-etenr.
      ls_schedule-req_date = ls_header_in-req_date_h.
      ls_schedulex-req_date = ls_header_inx-req_date_h.

      APPEND ls_schedule TO lt_schedule.
      APPEND ls_schedulex TO lt_schedulex.
    ENDLOOP.

    DATA: ls_bape_vbak  TYPE bape_vbak,
          ls_bape_vbakx TYPE bape_vbakx.

*   Custom VBAK
    ls_bape_vbak-vbeln      = lv_vbeln.
    ls_bape_vbakx-vbeln     = lv_vbeln.

    ls_bape_vbak-zzcomment  = ls_salesorder-zzgeneralinformationline1.
    ls_bape_vbak-zzcomment2  = ls_salesorder-zzgeneralinformationline2.
    ls_bape_vbak-zzcomment3  = ls_salesorder-zzgeneralinformationline3.
    ls_bape_vbakx-zzcomment = 'X'.
    ls_bape_vbakx-zzcomment2 = 'X'.
    ls_bape_vbakx-zzcomment3 = 'X'.

    ls_bape_vbak-zzkvgr_pamount  = ls_salesorder-zzpenaltyamount.
    ls_bape_vbakx-zzkvgr_pamount = 'X'.

    ls_bape_vbak-zzkvgr_tender  = ls_salesorder-zztendernoandname.
    ls_bape_vbakx-zzkvgr_tender = 'X'.

    TRY .
        ls_bape_vbak-zzkvgr_pstart  = convert_date_to_sapintern( ls_salesorder-zzpenaltystart ).
        ls_bape_vbakx-zzkvgr_pstart = 'X'.
      CATCH cx_sy_conversion_no_number.

        log_to_header(
          type = 'E'
          id = 'ZWOT'
          number = '003'
          v1 = ls_salesorder-zzpenaltystart
          v2 = 'PENALTY START'
          field = 'PenaltyStart' ).
        RETURN.

    ENDTRY.

    ls_bape_vbak-zzkvgr_un_ov_dlv = ls_salesorder-zzallowunderoverdlv.
    ls_bape_vbakx-zzkvgr_un_ov_dlv = 'X'.

    TRY .
        ls_bape_vbak-zzuebto = convert_amount_string( ls_salesorder-zzoverdlvtolerance ).
        ls_bape_vbakx-zzuebto = 'X'.
      CATCH cx_sy_conversion_no_number.

        log_to_header(
          type = 'E'
          id = 'ZWOT'
          number = '002'
          v1 = ls_salesorder-zzoverdlvtolerance
          v2 = 'TOLERANCE OVER DLV'
          field = 'OverDlvTolerance' ).
        RETURN.

      CATCH cx_sy_conversion_overflow.

        log_to_header(
          type = 'E'
          id = 'ZWOT'
          number = '001'
          v1 = ls_salesorder-zzoverdlvtolerance
          v2 = 'TOLERANCE OVER DLV'
          field = 'OverDlvTolerance' ).
        RETURN.

    ENDTRY.

    TRY .
        ls_bape_vbak-zzuntto = convert_amount_string( ls_salesorder-zzunderdlvtolerance ).
        ls_bape_vbakx-zzuntto = 'X'.
      CATCH cx_sy_conversion_no_number.

        log_to_header(
          type = 'E'
          id = 'ZWOT'
          number = '002'
          v1 = ls_salesorder-zzunderdlvtolerance
          v2 = 'TOLERANCE UNDER DLV'
          field = 'UnderDlvTolerance' ).
        RETURN.

      CATCH cx_sy_conversion_overflow.

        log_to_header(
          type = 'E'
          id = 'ZWOT'
          number = '001'
          v1 = ls_salesorder-zzunderdlvtolerance
          v2 = 'TOLERANCE UNDER DLV'
          field = 'UnderDlvTolerance' ).
        RETURN.

    ENDTRY.

    lv_string = ls_bape_vbak.
    lv_count  = strlen( lv_string ).

    ls_extensionin-valuepart1 = lv_string.
    IF lv_count GT 240.
      ls_extensionin-valuepart2 = lv_string+240.
    ENDIF.
    IF lv_count GT 480.
      ls_extensionin-valuepart3 = lv_string+480.
    ENDIF.
    IF lv_count GT 720.
      ls_extensionin-valuepart4 = lv_string+720.
    ENDIF.

    ls_extensionin-structure  = 'BAPE_VBAK'.
    ls_extensionex-structure  = 'BAPE_VBAKX'.
    ls_extensionex-valuepart1 = ls_bape_vbakx.
    APPEND ls_extensionin TO lt_extensionin.
    APPEND ls_extensionex TO lt_extensionin.

    ls_header_inx-updateflag = 'U'.
    CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
      EXPORTING
        salesdocument    = lv_vbeln
        order_header_in  = ls_header_in
        order_header_inx = ls_header_inx
      TABLES
        return           = lt_return
        order_item_in    = lt_item_in
        order_item_inx   = lt_item_inx
        schedule_lines   = lt_schedule
        schedule_linesx  = lt_schedulex
        extensionin      = lt_extensionin
        extensionex      = lt_extensionex.

    LOOP AT lt_return INTO ls_return
      WHERE type EQ 'E'.
      IF message_is_relevant( i_msgid = ls_return-id
                              i_msgno = ls_return-number ) EQ abap_true.
      mo_context->get_message_container( )->add_message_from_bapi(
        is_bapi_message = ls_return
        iv_add_to_response_header = 'X'
        iv_message_target = || && ls_return-field ).
      EXIT.
      ENDIF.
    ENDLOOP.
    IF sy-subrc EQ 0.
      ROLLBACK WORK.
    ELSE.
      LOOP AT lt_return INTO ls_return
        WHERE type EQ 'W'.
        IF message_is_relevant( i_msgid = ls_return-id
                                i_msgno = ls_return-number ) EQ abap_true.
        mo_context->get_message_container( )->add_message_from_bapi(
          is_bapi_message = ls_return
          iv_add_to_response_header = 'X'
          iv_message_target = || && ls_return-field ).
        EXIT.
        ENDIF.
      ENDLOOP.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

*     Warning message
      IF lv_checkmbdat EQ abap_true.
        LOOP AT lt_vbap INTO ls_vbap.
          SELECT SINGLE mbdat FROM vbep INTO lv_mbdat
           WHERE vbeln = ls_vbap-vbeln
             AND posnr = ls_vbap-posnr.
          IF sy-subrc EQ 0 AND lv_mbdat IS NOT INITIAL.
            CALL METHOD nonworkday_check
              EXPORTING
                i_werks      = ls_vbap-werks
                i_matnr      = ls_vbap-matnr
                i_mbdat      = lv_mbdat
              IMPORTING
                e_nonworkday = lv_nonworkday
                e_plant      = lv_plant.
            IF lv_nonworkday EQ abap_true.
              log_to_header(
                  type   = 'W'
                  id     = 'ZSD'
                  number = '002'
                  v1     = lv_mbdat
                  v2     = lv_plant
                  field  = 'DeliveryDate' ).
              EXIT.
            ENDIF.
          ENDIF.

        ENDLOOP.
      ENDIF.
    ENDIF.

  ENDMETHOD.
