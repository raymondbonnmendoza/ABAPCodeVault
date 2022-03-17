  METHOD orderitems_update_entity.

    DATA: ls_orderitem         TYPE sra017_s_so_item,
          lv_vbeln             TYPE vbak-vbeln,
          lv_posnr             TYPE vbap-posnr,
          lo_message_container TYPE REF TO /iwbep/if_message_container,
          ls_message           TYPE scx_t100key,
          lt_return            TYPE TABLE OF bapiret2,
          ls_return            TYPE bapiret2,
          lt_key_tab           TYPE /iwbep/t_mgw_tech_pairs,
          ls_keys              TYPE /iwbep/s_mgw_tech_pair.

    DATA: lt_activitygroups TYPE TABLE OF bapiagr,
          ls_activitygroups TYPE bapiagr,
          r_agr             LIKE RANGE OF ls_activitygroups-agr_name,
          ls_agr            LIKE LINE OF r_agr,
          lv_kunnr          TYPE kna1-kunnr.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_orderitem ).
    er_entity = ls_orderitem.

    lt_key_tab = io_tech_request_context->get_keys( ).

    lv_vbeln = ls_orderitem-salesordernumber.
    lv_posnr = ls_orderitem-itemnumber.

    LOOP AT lt_key_tab INTO ls_keys.
      CASE ls_keys-name.
        WHEN 'SALESORDERNUMBER'.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = ls_keys-value
            IMPORTING
              output = lv_vbeln.
        WHEN 'ITEMNUMBER'.
          lv_posnr = ls_keys-value.
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

    DATA: ls_header_in  TYPE bapisdh1,
          ls_header_inx TYPE bapisdh1x,
          lv_werks      TYPE vbap-werks,
          lv_matnr      TYPE vbap-matnr.

    DATA: lt_item_in  TYPE TABLE OF bapisditm,
          lt_item_inx	TYPE TABLE OF bapisditmx,
          ls_item_in  TYPE bapisditm,
          ls_item_inx	TYPE bapisditmx.
    ls_orderitem-salesordernumber = lv_vbeln.
    ls_orderitem-itemnumber       = lv_posnr.
    ls_item_in-itm_number         = lv_posnr.
    ls_item_inx-itm_number        = lv_posnr.
    ls_item_inx-updateflag        = 'U'.
    SELECT SINGLE werks matnr FROM vbap INTO (lv_werks, lv_matnr)
     WHERE vbeln EQ lv_vbeln
       AND posnr EQ lv_posnr.
    IF ls_orderitem-materialnumber IS NOT INITIAL.
      ls_item_in-material  = ls_orderitem-materialnumber.
      ls_item_inx-material = 'X'.
    ENDIF.
    IF lv_werks IS INITIAL.
      CALL METHOD me->read_value_from_table
        EXPORTING
          iv_type  = 'WERKS'
          iv_name  = 'DEFAULT'
        RECEIVING
          ev_value = ls_item_in-plant.
      ls_item_inx-plant = 'X'.
    ENDIF.
    IF ls_orderitem-zzitemtype IS NOT INITIAL.
      CASE ls_orderitem-zzitemtype.
        WHEN 'Standard Item'.
          ls_item_in-item_categ = 'TAN'.
          CLEAR ls_item_in-prc_group1.
          ls_item_inx-item_categ = 'X'.
          ls_item_inx-prc_group1 = 'X'.
        WHEN 'Samples FOC'.
          ls_item_in-item_categ  = 'TANN'.
          ls_item_in-prc_group1  = '001'.
          ls_item_inx-item_categ = 'X'.
          ls_item_inx-prc_group1 = 'X'.
        WHEN 'Free Units-No Sample'.
          ls_item_in-item_categ  = 'TANN'.
          ls_item_in-prc_group1  = '007'.
          ls_item_inx-item_categ = 'X'.
          ls_item_inx-prc_group1 = 'X'.
        WHEN 'Samples Included'.
          ls_item_in-item_categ  = 'ZSIN'.
          ls_item_in-prc_group1  = '001'.
          ls_item_inx-item_categ = 'X'.
          ls_item_inx-prc_group1 = 'X'.
      ENDCASE.
    ENDIF.
    APPEND ls_item_in TO lt_item_in.
    CLEAR  ls_item_in.
    APPEND ls_item_inx TO lt_item_inx.
    CLEAR  ls_item_inx.

*   Schedule Lines
    DATA: lt_schedule  TYPE TABLE OF bapischdl,
          ls_schedule  TYPE bapischdl,
          lt_schedulex TYPE TABLE OF bapischdlx,
          ls_schedulex TYPE bapischdlx.
    SELECT SINGLE * FROM vbep INTO @DATA(ls_vbep)
     WHERE vbeln EQ @lv_vbeln
       AND posnr EQ @lv_posnr.
    IF ls_orderitem-zzquantitydisplay IS NOT INITIAL.
      ls_schedule-itm_number  = lv_posnr.
      ls_schedulex-itm_number = lv_posnr.
      IF ls_vbep IS NOT INITIAL.
        ls_schedulex-updateflag = 'U'.
        ls_schedule-sched_line  = ls_vbep-etenr.
        ls_schedulex-sched_line = ls_vbep-etenr.
      ELSE.
        ls_schedulex-updateflag = 'I'.
        ADD 1 TO ls_schedule-sched_line.
        ADD 1 TO ls_schedulex-sched_line.
      ENDIF.

      TRY.
          ls_schedule-req_qty   = convert_amount_to_sapintern( ls_orderitem-zzquantitydisplay ).
          ls_schedulex-req_qty  = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '002'
            v1 = ls_orderitem-zzquantitydisplay
            v2 = 'QUANTITY'
            field = 'Quantity' ).
          RETURN.

        CATCH cx_sy_conversion_overflow.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '001'
            v1 = ls_orderitem-zzquantitydisplay
            v2 = |QUANTITY (item { lv_posnr })|
            field = 'Quantity' ).
          RETURN.

      ENDTRY.

*      TRY .
*          ls_schedule-req_date  = convert_date_to_sapintern( ls_orderitem-zzestimateddeliverydisplay ).
*          ls_schedulex-req_date = 'X'.
*        CATCH cx_sy_conversion_no_number.
*
*          log_to_header(
*            type = 'E'
*            id = 'ZWOT'
*            number = '003'
*            v1 = ls_orderitem-zzestimateddeliverydisplay
*            v2 = |DELIVERY DATE (item { lv_posnr })|
*            field = 'DeliveryDate' ).
*          RETURN.
*
*      ENDTRY.

      APPEND ls_schedule  TO lt_schedule.
      APPEND ls_schedulex TO lt_schedulex.
    ENDIF.

*   Conditions
    DATA: lt_condition  TYPE TABLE OF bapicond,
          ls_condition  TYPE bapicond,
          lt_conditionx TYPE TABLE OF bapicondx,
          ls_conditionx TYPE bapicondx,
          lv_auart      TYPE vbak-auart,
          lv_knumv      TYPE vbak-knumv,
          lv_vtweg       type vbak-vtweg,
          ls_konv       TYPE konv.
    SELECT SINGLE auart knumv kunnr vtweg FROM vbak INTO (lv_auart, lv_knumv, lv_kunnr, lv_vtweg)
     WHERE vbeln EQ lv_vbeln.
    IF  ls_orderitem-zzfinalpricedisplay IS NOT INITIAL
    AND ls_orderitem-currency            IS NOT INITIAL.
      ls_condition-itm_number = lv_posnr.
      IF lv_auart = 'ZWOR'
        and lv_vtweg ne '01'.
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'LIST_PRICE'
          RECEIVING
            ev_value = ls_condition-cond_type.
      ENDIF.
      IF lv_auart = 'ZWKB' or
       ( lv_auart EQ 'ZWOR'
     and lv_vtweg = '01' ).
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'LIST_PRICE_KB'
          RECEIVING
            ev_value = ls_condition-cond_type.
      ENDIF.
      SELECT SINGLE * FROM konv INTO ls_konv
       WHERE knumv EQ lv_knumv
         AND kposn EQ lv_posnr
         AND kschl EQ ls_condition-cond_type
         AND kinak NE 'Y'.
      IF sy-subrc EQ 0.
        ls_condition-cond_st_no  = ls_konv-stunr.
        ls_condition-cond_count  = ls_konv-zaehk.
        ls_conditionx-cond_st_no = ls_konv-stunr.
        ls_conditionx-cond_count = ls_konv-zaehk.
        ls_conditionx-updateflag = 'U'.
        ls_conditionx-cond_type  = ls_condition-cond_type.
      ELSE.
        ls_conditionx-updateflag = 'I'.
        ls_conditionx-cond_type  = ls_condition-cond_type.
      ENDIF.
      ls_condition-itm_number  = lv_posnr.
      ls_conditionx-itm_number = lv_posnr.
      TRY.
          ls_condition-cond_value  = convert_amount_to_sapintern( ls_orderitem-zzfinalpricedisplay ).
          ls_conditionx-cond_value = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '002'
            v1 = ls_orderitem-zzfinalpricedisplay
            v2 = |PRICE (item { lv_posnr })|
            field = 'Price' ).
          RETURN.

        CATCH cx_sy_conversion_overflow.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '001'
            v1 = ls_orderitem-zzfinalpricedisplay
            v2 = |PRICE (item { lv_posnr })|
            field = 'Price' ).
          RETURN.

      ENDTRY.
      ls_condition-currency    = ls_orderitem-currency.
      ls_conditionx-currency   = 'X'.
      APPEND ls_condition TO lt_condition.
      CLEAR  ls_condition.
      APPEND ls_conditionx TO lt_conditionx.
      CLEAR  ls_conditionx.
    ENDIF.

    DATA: lv_cond_type_main LIKE ls_condition-cond_type,
          lv_cond_type_alt  LIKE ls_condition-cond_type.
    IF ls_orderitem-zzcommission    IS NOT INITIAL
    OR ls_orderitem-zzcurrencyorpct IS NOT INITIAL.
      IF ls_orderitem-zzcommission IS INITIAL.
        ls_orderitem-zzcommission = '0'.
      ENDIF.
      IF ls_orderitem-zzcurrencyorpct = '%'
      OR ls_orderitem-zzcurrencyorpct IS INITIAL.
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'COMMISSION_PC'
          RECEIVING
            ev_value = lv_cond_type_main.
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'COMMISSION_AMOUNT'
          RECEIVING
            ev_value = lv_cond_type_alt.
      ELSE.
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'COMMISSION_AMOUNT'
          RECEIVING
            ev_value = lv_cond_type_main.
        CALL METHOD me->read_value_from_table
          EXPORTING
            iv_type  = 'PRICING_CONDITION'
            iv_name  = 'COMMISSION_PC'
          RECEIVING
            ev_value = lv_cond_type_alt.
      ENDIF.
      SELECT SINGLE * FROM konv INTO ls_konv
       WHERE knumv EQ lv_knumv
         AND kposn EQ lv_posnr
         AND kschl EQ lv_cond_type_main.
      IF sy-subrc EQ 0.
        ls_condition-cond_st_no  = ls_konv-stunr.
        ls_condition-cond_count  = ls_konv-zaehk.
        ls_conditionx-cond_st_no = ls_konv-stunr.
        ls_conditionx-cond_count = ls_konv-zaehk.
        ls_conditionx-updateflag = 'U'.
        ls_condition-cond_type   = lv_cond_type_main.
        ls_conditionx-cond_type  = lv_cond_type_main.
      ELSE.
        ls_conditionx-updateflag = 'I'.
        ls_condition-cond_type   = lv_cond_type_main.
        ls_conditionx-cond_type  = lv_cond_type_main.
      ENDIF.
      ls_condition-itm_number  = lv_posnr.
      ls_conditionx-itm_number = lv_posnr.
      IF  ls_orderitem-zzcurrencyorpct IS NOT INITIAL
      AND ls_orderitem-zzcurrencyorpct NE '%'.
        ls_condition-currency  = ls_orderitem-zzcurrencyorpct.
        ls_conditionx-currency = 'X'.
      ENDIF.
      TRY.
          ls_condition-cond_value  = convert_amount_to_sapintern( ls_orderitem-zzcommission ).
          ls_conditionx-cond_value = 'X'.
        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '002'
            v1 = ls_orderitem-zzcommission
            v2 = |COMMISSION (item { lv_posnr })|
            field = 'Commission' ).
          RETURN.

        CATCH cx_sy_conversion_overflow.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '001'
            v1 = ls_orderitem-zzcommission
            v2 = |COMMISSION (item { lv_posnr })|
            field = 'Commission' ).
          RETURN.

      ENDTRY.
      APPEND ls_condition TO lt_condition.
      CLEAR  ls_condition.
      APPEND ls_conditionx TO lt_conditionx.
      CLEAR  ls_conditionx.
*     CHECK FOR ZCA2/ZCA4 THEN DEACTIVATE
      SELECT SINGLE * FROM konv INTO ls_konv
       WHERE knumv EQ lv_knumv
         AND kposn EQ lv_posnr
         AND kschl EQ lv_cond_type_alt.
      IF sy-subrc EQ 0.
        ls_condition-itm_number  = lv_posnr.
        ls_conditionx-itm_number = lv_posnr.
        ls_condition-cond_st_no  = ls_konv-stunr.
        ls_condition-cond_count  = ls_konv-zaehk.
        ls_conditionx-cond_st_no = ls_konv-stunr.
        ls_conditionx-cond_count = ls_konv-zaehk.
        ls_conditionx-updateflag = 'U'.
        ls_condition-cond_type   = lv_cond_type_alt.
        ls_conditionx-cond_type  = lv_cond_type_alt.
        ls_condition-cond_value  = 0.
        ls_conditionx-cond_value = 'X'.
        APPEND ls_condition TO lt_condition.
        CLEAR: ls_condition.
        APPEND ls_conditionx TO lt_conditionx.
        CLEAR: ls_conditionx.
      ENDIF.
    ENDIF.

*   Z FIELDS
    DATA: ls_bape_vbap   TYPE bape_vbap,
          ls_bape_vbapx  TYPE bape_vbapx,
          lt_extensionin TYPE TABLE OF bapiparex,
          lt_extensionex TYPE TABLE OF bapiparex,
          ls_extensionin TYPE bapiparex,
          ls_extensionex TYPE bapiparex,
          lv_string      TYPE string,
          lv_count       TYPE i.
    IF ls_orderitem-zzcommbatchalloc IS NOT INITIAL.
      ls_bape_vbap-vbeln       = lv_vbeln.
      ls_bape_vbap-posnr       = lv_posnr.
      ls_bape_vbap-zzalloccom  = ls_orderitem-zzcommbatchalloc.
      ls_bape_vbapx-vbeln      = lv_vbeln.
      ls_bape_vbapx-posnr      = lv_posnr.
      ls_bape_vbapx-zzalloccom = 'X'.
    ENDIF.
    IF ls_orderitem-zzsamplewship IS NOT INITIAL.
      DATA:
        number TYPE i.

      TRY .

          IF NOT ls_orderitem-zzsamplewship CO '0123456789 '.
            RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
          ENDIF.

* If the sample number is not an actual number,
* this will throw a catchable exception
* Waiting and using it with the IFs, ABAP will
* produce an uncatchable exception in case it is
* not a number
          number = ls_orderitem-zzsamplewship.

          IF number < 1.
            RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
          ENDIF.
          IF number > 99.
            RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
          ENDIF.

          IF strlen( ls_orderitem-zzsamplewship ) EQ 1.
            CONCATENATE space ls_orderitem-zzsamplewship INTO ls_orderitem-zzsamplewship
             RESPECTING BLANKS.
          ENDIF.
          ls_bape_vbap-vbeln        = lv_vbeln.
          ls_bape_vbap-posnr        = lv_posnr.
          ls_bape_vbap-zzkvgr_pos3  = ls_orderitem-zzsamplewship.
          ls_bape_vbapx-vbeln       = lv_vbeln.
          ls_bape_vbapx-posnr       = lv_posnr.
          ls_bape_vbapx-zzkvgr_pos3 = 'X'.

        CATCH cx_sy_conversion_no_number.

          log_to_header(
            type = 'E'
            id = 'ZWOT'
            number = '006'
            v1 = ls_orderitem-zzsamplewship
            field = 'SampleWShip' ).
          RETURN.

      ENDTRY.

    ELSE.
      SELECT SINGLE zzkvgr_pos3 FROM knvv INTO ls_bape_vbap-zzkvgr_pos3
       WHERE kunnr EQ lv_kunnr.
      IF sy-subrc EQ 0.
        IF strlen( ls_bape_vbap-zzkvgr_pos3 ) EQ 1.
          CONCATENATE space ls_bape_vbap-zzkvgr_pos3 INTO ls_bape_vbap-zzkvgr_pos3
           RESPECTING BLANKS.
        ENDIF.
        ls_bape_vbap-vbeln        = lv_vbeln.
        ls_bape_vbap-posnr        = lv_posnr.
        ls_bape_vbapx-vbeln       = lv_vbeln.
        ls_bape_vbapx-posnr       = lv_posnr.
        ls_bape_vbapx-zzkvgr_pos3 = 'X'.
      ENDIF.
    ENDIF.
    IF ls_orderitem-zzsp IS NOT INITIAL.
      ls_bape_vbap-vbeln            = lv_vbeln.
      ls_bape_vbap-posnr            = lv_posnr.
      ls_bape_vbap-z00v_kvgr_item8  = ls_orderitem-zzsp.
      ls_bape_vbapx-vbeln           = lv_vbeln.
      ls_bape_vbapx-posnr           = lv_posnr.
      ls_bape_vbapx-z00v_kvgr_item8 = 'X'.
    ENDIF.
    IF ls_orderitem-zzshelflifereq IS NOT INITIAL.
      ls_bape_vbap-vbeln             = lv_vbeln.
      ls_bape_vbap-posnr             = lv_posnr.
      ls_bape_vbap-zzkvgr_shelf_reg  = ls_orderitem-zzshelflifereq.
      ls_bape_vbapx-vbeln            = lv_vbeln.
      ls_bape_vbapx-posnr            = lv_posnr.
      ls_bape_vbapx-zzkvgr_shelf_reg = 'X'.
    ENDIF.
    IF ls_orderitem-zzshelflifeperind IS NOT INITIAL.
      ls_bape_vbap-vbeln             = lv_vbeln.
      ls_bape_vbap-posnr             = lv_posnr.
      ls_bape_vbap-zzkvgr_shelf_ind  = ls_orderitem-zzshelflifeperind.
      ls_bape_vbapx-vbeln            = lv_vbeln.
      ls_bape_vbapx-posnr            = lv_posnr.
      ls_bape_vbapx-zzkvgr_shelf_ind = 'X'.
    ENDIF.
    IF ls_bape_vbap IS NOT INITIAL.
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
    ENDIF.

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
        conditions_in    = lt_condition
        conditions_inx   = lt_conditionx
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
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    ENDIF.

  ENDMETHOD.