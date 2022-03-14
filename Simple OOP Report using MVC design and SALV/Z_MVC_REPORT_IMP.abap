*&---------------------------------------------------------------------*
*&  Include           Z_MVC_REPORT_IMP
*&---------------------------------------------------------------------*
CLASS lcl_f4_layout IMPLEMENTATION.

  METHOD f4_layout_display_list.

    DATA: ls_layout      TYPE salv_s_layout,
          ls_layout_key  TYPE salv_s_layout_key,
          lt_layout_info TYPE salv_t_layout_info ##NEEDED,
          lt_report      TYPE z_tt_scarr,
          lo_layout      TYPE REF TO cl_salv_layout.

    IF co_table IS NOT BOUND.
      TRY.
          CALL METHOD cl_salv_table=>factory
            EXPORTING
              list_display = abap_false
            IMPORTING
              r_salv_table = co_table
            CHANGING
              t_table      = lt_report.
        CATCH cx_salv_msg .
          MESSAGE 'Error generating ALV Grid'(001) TYPE 'E'.
      ENDTRY.
    ENDIF.

    IF co_table IS NOT INITIAL.
      MOVE sy-repid TO ls_layout_key-report.      "Set Layout Key as Report ID"
      lo_layout = co_table->get_layout( ).        "Get Layout of the Table"
      lo_layout->set_key( ls_layout_key ).        "Set Layout key to Layout"
      lt_layout_info = lo_layout->get_layouts( ). "Get the Layouts of report"
      ls_layout = lo_layout->f4_layouts( ).       "Activate F4 Help for Layouts"
      IF ls_layout IS NOT INITIAL.
        MOVE ls_layout-layout TO re_layout.
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_controller IMPLEMENTATION.

  METHOD execute.

    DATA: lo_display_alv TYPE REF TO lcl_view_alv.

    CREATE OBJECT co_model.
    co_model->process_entry( ).

    IF co_model->get_report( ) IS NOT INITIAL.
      CREATE OBJECT lo_display_alv.
      lo_display_alv->execute( co_model ).
    ELSE.
      MESSAGE 'No data found for selection'(002) TYPE 'S'.
    ENDIF.

  ENDMETHOD.

ENDCLASS.               "lcl_controller


CLASS lcl_model IMPLEMENTATION.

  METHOD process_entry.
    SELECT * FROM scarr INTO CORRESPONDING FIELDS OF TABLE ct_report
     WHERE carrid IN s_carrid.
  ENDMETHOD.

  METHOD get_report.
    re_report = ct_report.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_view_alv IMPLEMENTATION.

  METHOD execute.

    DATA: lt_report TYPE z_tt_scarr.

    lt_report = im_model->get_report( ).
    TRY.
        CALL METHOD cl_salv_table=>factory
          EXPORTING
            list_display = abap_false
          IMPORTING
            r_salv_table = co_table
          CHANGING
            t_table      = lt_report.
      CATCH cx_salv_msg.
        MESSAGE 'Error Creating ALV Grid'(003) TYPE 'I' DISPLAY LIKE 'E'.
    ENDTRY.
    IF co_table IS INITIAL.
      MESSAGE 'Error Creating ALV Grid'(003) TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    activate_functions( im_activate = abap_true ).

    set_layout( p_layout ).

    set_display( im_title   = 'Sample MVC Report'(004)
                 im_striped = abap_true ).

    set_columns( im_optimized = abap_true
                 im_key_fix   = abap_true ).

    CALL METHOD co_table->display.

  ENDMETHOD.

  METHOD activate_functions.

    DATA: lo_functions TYPE REF TO cl_salv_functions_list.

*   Get functions details
    lo_functions = co_table->get_functions( ).

*   Activate All Buttons in Tool Bar
    lo_functions->set_all( im_activate ).

  ENDMETHOD.

  METHOD set_layout.

    DATA: lo_layout     TYPE REF TO cl_salv_layout,
          ls_layout_key TYPE salv_s_layout_key.

*   Layout Settings
    MOVE sy-repid TO ls_layout_key-report.                              "Set Report ID as Layout Key"

    lo_layout = co_table->get_layout( ).                                "Get Layout of Table"
    lo_layout->set_key( ls_layout_key ).                                "Set Report Id to Layout"
    lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ). "No Restriction to Save Layout"
    IF im_layout IS INITIAL.
      lo_layout->set_default( abap_true ).                              "Set Default Variant"
    ELSE.
      lo_layout->set_initial_layout( im_layout ).                       "Set the Selected Variant as Initial"
    ENDIF.

  ENDMETHOD.

  METHOD set_display.

    DATA: lo_display TYPE REF TO cl_salv_display_settings.

*   Global Display Settings
    lo_display = co_table->get_display_settings( ).  "Global Display settings"
    lo_display->set_striped_pattern( im_striped ).   "Activate Strip Pattern"
    lo_display->set_list_header( im_title ).         "Report Header"

  ENDMETHOD.

  METHOD set_columns.

    DATA: lo_columns TYPE REF TO cl_salv_columns_table.

*   Get the columns from ALV Table
    lo_columns = co_table->get_columns( ).

*   Get columns properties
    lo_columns->set_optimize( im_optimized ).
    lo_columns->set_key_fixation( im_key_fix ).

  ENDMETHOD.

ENDCLASS.
