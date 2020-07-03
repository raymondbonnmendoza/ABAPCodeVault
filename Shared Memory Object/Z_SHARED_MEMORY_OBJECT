    DATA:
      lo_area  TYPE REF TO zcl_sharefunct,
      lo_root  TYPE REF TO zcl_rootfunct,
      lv_matnr TYPE mara-matnr,
      ls_mara  TYPE mara.

*   IMPORT FROM SHARED MEMORY OBJECT
    TRY.
        lo_area = zcl_sharefunct=>attach_for_read( ).
      CATCH cx_shm_no_active_version.
      CATCH cx_shm_inconsistent.
    ENDTRY.
    IF lo_area IS NOT INITIAL.
      lv_matnr = lo_area->root->get_data( ).
      lo_area->detach( ).
    ENDIF.

*   EXPORT TO SHARED MEMORY OBJECT
    IF lv_matnr IS INITIAL.
      SELECT SINGLE * FROM mara INTO ls_mara.

*     Get a pointer to shared area
      lo_area = zcl_sharefunct=>attach_for_write( ).

*     Create an instance of the root
      CREATE OBJECT lo_root AREA HANDLE lo_area.

      lo_root->set_data( ls_mara-matnr ).

      lo_area->set_root( lo_root ).
      lo_area->detach_commit( ).
    ELSE.
      lo_area->free_area( ).
      WRITE: lv_matnr.
    ENDIF.
