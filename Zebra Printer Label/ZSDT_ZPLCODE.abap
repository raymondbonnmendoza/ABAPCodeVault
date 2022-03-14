REPORT zsdt_zplcode.
*************************************************************************
* PROGRAM ID           : ZSDT_ZPLCODE (Git Hub)
* PROGRAM TITLE      : Zebra Printer Label Code Demo
* AUTHOR                   : Katrina Eunice R. Rabor (RABOR_K700)
* DATE                        : 05/20/2019
* DESCRIPTION           : This program shows how Zebra commands are
*                                    used in ABAP programs.
*========================================================================
* COPIED FROM          :
* TITLE                :
* OTHER RELATED OBJ    :
*
*=======================================================================
*----------------------------------------------------------------------*
*       DECLARATIONS                                                   *
*----------------------------------------------------------------------*
  DATA:
    g_mblnr   TYPE mkpf-mblnr,
    r_mblnr   TYPE RANGE OF mkpf-mblnr,
    lwa_mblnr LIKE LINE OF r_mblnr,
    g_print   TYPE xfeld.

*----------------------------------------------------------------------*
*        INCLUDES                                                      *
*----------------------------------------------------------------------*
  INCLUDE zsdt_zpl_cld.
  INCLUDE zsdt_zpl_sel.
  INCLUDE zsdt_zpl_cli.

*-----------------------------------------------------------------------*
*        INITIALIZATION                                                 *
*-----------------------------------------------------------------------*
  INITIALIZATION.
    DATA:
      g_settings TYPE zpm175_settings.

    SELECT SINGLE * INTO g_settings
      FROM zpm175_settings
      WHERE uname = sy-uname.

    p_dest = g_settings-zebra.

*-----------------------------------------------------------------------*
*        START-OF-SELECTION                                             *
*-----------------------------------------------------------------------*
START-OF-SELECTION.

  DATA:
    g_list TYPE REF TO lcl_bin_list.

  IF g_settings-uname IS INITIAL.
    g_settings-uname = sy-uname.
    g_settings-zebra = p_dest.
*    INSERT INTO zpm175_settings VALUES g_settings.
*    COMMIT WORK.
  ELSE.
*    UPDATE zpm175_settings
*      SET zebra = p_dest
*      WHERE uname = sy-uname.
*    COMMIT WORK.
  ENDIF.

  CREATE OBJECT g_list
    EXPORTING
      werks      = p_werks
      lgort      = p_lgort
      matnr_r    = s_matnr[]
      lgpbe_r    = s_lgpbe[]
      charg      = p_charg
      printer    = p_dest
      preview    = p_select.

AT USER-COMMAND.

  g_list->command( ).
