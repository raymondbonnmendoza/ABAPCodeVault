class ZCL_ROOTFUNCT definition
  public
  final
  create public
  shared memory enabled .

public section.

  interfaces IF_SHM_BUILD_INSTANCE .

  data MATNR type MATNR .

  methods SET_DATA
    importing
      value(IM_MATNR) type MATNR .
  methods GET_DATA
    returning
      value(RE_MATNR) type MATNR .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ROOTFUNCT IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ROOTFUNCT->GET_DATA
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RE_MATNR                       TYPE        MATNR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_DATA.

    re_matnr = matnr.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_ROOTFUNCT=>IF_SHM_BUILD_INSTANCE~BUILD
* +-------------------------------------------------------------------------------------------------+
* | [--->] INST_NAME                      TYPE        SHM_INST_NAME (default =CL_SHM_AREA=>DEFAULT_INSTANCE)
* | [--->] INVOCATION_MODE                TYPE        SHM_CONSTR_INVOCATION_MODE (default =CL_SHM_AREA=>INVOCATION_MODE_EXPLICIT)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD IF_SHM_BUILD_INSTANCE~BUILD.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ROOTFUNCT->SET_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IM_MATNR                       TYPE        MATNR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method SET_DATA.

    matnr = im_matnr.

  endmethod.
ENDCLASS.
