*&---------------------------------------------------------------------*
*&  Include           Z_MVC_REPORT_DEF
*&---------------------------------------------------------------------*
CLASS lcl_model      DEFINITION DEFERRED.
CLASS lcl_view_alv   DEFINITION DEFERRED.
CLASS lcl_controller DEFINITION DEFERRED.
CLASS lcl_f4_layout  DEFINITION DEFERRED.

CLASS lcl_model DEFINITION.

  PUBLIC SECTION.
    METHODS:
      process_entry,
      get_report RETURNING VALUE(re_report) TYPE z_tt_scarr. "Table type with scarr as line type

  PRIVATE SECTION.
    DATA:
      ct_report TYPE z_tt_scarr.

ENDCLASS.

CLASS lcl_view_alv DEFINITION.

  PUBLIC SECTION.
    METHODS:
      execute IMPORTING im_model TYPE REF TO lcl_model,

      activate_functions IMPORTING im_activate TYPE xfeld,

      set_layout IMPORTING im_layout TYPE slis_vari,

      set_display IMPORTING im_title   TYPE lvc_title
                            im_striped TYPE xfeld,

      set_columns IMPORTING im_optimized TYPE xfeld
                            im_key_fix   TYPE xfeld.

  PRIVATE SECTION.
    DATA:
      co_table TYPE REF TO cl_salv_table.

ENDCLASS.

CLASS lcl_controller DEFINITION.

  PUBLIC SECTION.
    METHODS:
      execute.

  PRIVATE SECTION.
    DATA:
      co_model TYPE REF TO lcl_model.

ENDCLASS.


CLASS lcl_f4_layout DEFINITION.

  PUBLIC SECTION.
    CLASS-METHODS:
      f4_layout_display_list RETURNING value(re_layout) TYPE slis_vari.

    CLASS-DATA:
      co_table TYPE REF TO cl_salv_table.

ENDCLASS.
