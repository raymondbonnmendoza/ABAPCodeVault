*************************************************************************
* PROGRAM ID            : ZSDTZEBRALABELPRINT (Git Hub)
* PROGRAM TITLE       : Zebra Printer Label Code Demo
* AUTHOR                    : Katrina Eunice R. Rabor (RABOR_K700)
* DATE                         : 05/20/2019
* DESCRIPTION           : This program shows how Zebra commands are
*                                     used in ABAP programs.
*========================================================================
* COPIED FROM          :
* TITLE                :
* OTHER RELATED OBJ    :
*
*=======================================================================
*&---------------------------------------------------------------------*
*&  Include           ZSDT_ZPL_SEL
*&---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK 1 WITH FRAME TITLE text-000.
    SELECT-OPTIONS:
      s_mblnr FOR g_mblnr.

    PARAMETERS:
      p_mjahr TYPE gjahr,
      p_matnr TYPE matnr NO-DISPLAY.

    SELECT-OPTIONS:
      s_matnr FOR p_matnr.

    PARAMETERS:
      p_charg TYPE charg_d,
      p_werks TYPE werks_d OBLIGATORY.

    PARAMETERS:
      p_lgort TYPE lgort_d OBLIGATORY,
      p_lgpbe TYPE lgpbe NO-DISPLAY.

    SELECT-OPTIONS:
      s_lgpbe FOR p_lgpbe.

  SELECTION-SCREEN END OF BLOCK 1.

  SELECTION-SCREEN BEGIN OF BLOCK 2 WITH FRAME TITLE text-001.

    PARAMETERS:
      p_dest   LIKE pri_params-pdest OBLIGATORY,
      p_num    TYPE i,
      p_select TYPE xfeld DEFAULT 'X' AS CHECKBOX.

  SELECTION-SCREEN END OF BLOCK 2.
