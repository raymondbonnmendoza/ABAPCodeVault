FUNCTION Z_PAYMEDIUM_EVENT_41 .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_FPAYH) LIKE  FPAYH STRUCTURE  FPAYH
*"     VALUE(I_FPAYHX) LIKE  FPAYHX STRUCTURE  FPAYHX
*"  TABLES
*"      T_FILE_OUTPUT STRUCTURE  FPM_FILE
*"  CHANGING
*"     REFERENCE(C_WAERS) LIKE  FPAYH-WAERS
*"     REFERENCE(C_SUM) LIKE  FPAYH-RWBTR
*"----------------------------------------------------------------------

  data:
    lo_proxy       type ref to if_proxy_client,
    lr_output      type ref to data,
    lv_output_type type typename,
    lv_xml_xstring type xstring,
    lo_convertor   type ref to cl_abap_conv_out_ce,
    lo_excp        type ref to cx_root,
    lo_st_excp     type ref to cx_st_error,
    lv_excp_path_c type c length 200,
    lv_proxy_name  type seoclsname,
    lv_method_name type seocpdname,
    lo_protocol    type ref to if_wsprotocol_async_messaging,
    lo_prxbasis    type ref to if_proxy_basis,
    ls_parmbind    type abap_parmbind,
    lt_parmbind    type abap_parmbind_tab,
    lv_string      type string.

  field-symbols:
    <output>      type any,
    <file_output> like line of t_file_output.

  "proposal run - log and quit
  if i_fpayh-xvorl = abap_true.
    message s002(zbcm) with i_fpayh-laufd i_fpayh-laufi i_fpayh-zbukr i_fpayh-hbkid.
    return.
  endif.

  lv_proxy_name  = 'Z_CO_SI_BANK_PAYMENT_OUT'.
  lv_method_name = 'SI_BANK_PAYMENT_OUT'.
  lv_output_type = 'Z_DOCUMENT'.

  create data lr_output type (lv_output_type).
  assign lr_output->* to <output>.

  message s000(zbcm) with i_fpayh-laufd i_fpayh-laufi i_fpayh-zbukr i_fpayh-hbkid.

  clear lv_string.
  loop at t_file_output assigning <file_output> where length > 0.
    concatenate lv_string <file_output>-line(<file_output>-length)
           into lv_string respecting blanks.
    if <file_output>-x_cr = abap_true.
      concatenate lv_string cl_abap_char_utilities=>cr_lf
             into lv_string respecting blanks.
    endif.
  endloop.

  try.
      "convert to xstring
      lo_convertor = cl_abap_conv_out_ce=>create( ).
      lo_convertor->write( exporting n = -1 data = lv_string ).
      lv_xml_xstring = lo_convertor->get_buffer( ).

      "convert XML->ABAP
      cl_proxy_xml_transform=>xml_xstring_to_abap( exporting ddic_type = lv_output_type xml = lv_xml_xstring
                                                   importing abap_data = <output> ).

      "bind the message
      ls_parmbind-name = 'OUTPUT'.
      ls_parmbind-kind = cl_abap_objectdescr=>importing.
      get reference of <output> into ls_parmbind-value.
      insert ls_parmbind into table lt_parmbind.

      "create the proxy
      create object lo_proxy type (lv_proxy_name).

      "execute
      lo_proxy->execute( exporting method_name = |{ lv_method_name }| changing parmbind_tab = lt_parmbind ).

      COMMIT WORK.

      "log processing of the event - success
      message s001(zbcm).

    catch cx_st_error into lo_st_excp.
      "display the available information and abort
      lv_excp_path_c = lo_st_excp->xml_path.
      message i004(zbcm) with lv_excp_path_c+0(50) lv_excp_path_c+50(50) lv_excp_path_c+100(50) lv_excp_path_c+150(50) display like 'E'.
      message lo_st_excp type 'A'.

    catch cx_root into lo_excp.
      "if there is a previous exception, display it first (as an info box in order not to stop the error handling)
      if lo_excp->previous is bound.
        message lo_excp->previous type 'I' display like 'E'.
      endif.

      "generic exception, abort the program (to cancel a possible update task)
      message lo_excp type 'A'.

  endtry.

ENDFUNCTION.
