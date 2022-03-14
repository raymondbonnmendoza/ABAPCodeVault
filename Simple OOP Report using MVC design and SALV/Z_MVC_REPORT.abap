REPORT z_mvc_report.

TABLES: scarr.

SELECT-OPTIONS: s_carrid FOR  scarr-carrid NO INTERVALS NO-EXTENSION.
PARAMETERS:     p_layout TYPE slis_vari.

INCLUDE z_mvc_report_def.
INCLUDE z_mvc_report_imp.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout.
  p_layout = lcl_f4_layout=>f4_layout_display_list( ).

START-OF-SELECTION.

  DATA: go_controller TYPE REF TO lcl_controller ##NEEDED.

  CREATE OBJECT go_controller.
  go_controller->execute( ).
