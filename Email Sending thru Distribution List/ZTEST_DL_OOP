*&---------------------------------------------------------------------*
*& Report ZTEST_DL_OOP
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTEST_DL_OOP.

data :  i_error      TYPE TABLE OF solisti1 WITH HEADER LINE.
DATA: send_request       TYPE REF TO cl_bcs.
DATA: subject            TYPE so_obj_des.
DATA: att_type           TYPE soodk-objtp.
DATA: i_text             TYPE bcsy_text WITH HEADER LINE.
DATA: wa_text            TYPE soli.
DATA: document           TYPE REF TO cl_document_bcs.
DATA: sender             TYPE REF TO cl_sapuser_bcs.
DATA: recipient          TYPE REF TO if_recipient_bcs.
DATA: bcs_exception      TYPE REF TO cx_bcs.
DATA: sent_to_all        TYPE os_boolean.
DATA: i_lenght           TYPE so_obj_len.
DATA: n10                TYPE i.
CONSTANTS : ca_x type c value 'X',
            ca_raw(3) type c value 'RAW'.

PARAMETER : p_recp(50) type c.      "Distribution List which is setup in SO23

*Suppose you want to send the contents of the internal table i_error in the attchment to the group/ID
i_error-LINE = 'This is error Log'.
Append i_error.
perform f_send_mail.
*&---------------------------------------------------------------------*
*&      Form  F_SEND_MAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form F_SEND_MAIL .

  DATA lv_mlrec TYPE so_obj_nam.
*Assign the group_id name to the parameter lv_mlrec
  lv_mlrec = p_recp.

  TRY.

      send_request = cl_bcs=>create_persistent( ).

      PERFORM f_head_cont.
      PERFORM f_raw_att.

      CALL METHOD send_request->set_document( document ).

      sender = cl_sapuser_bcs=>create( sy-uname ).
      CALL METHOD send_request->set_sender
        EXPORTING
          i_sender = sender.

      recipient = cl_distributionlist_bcs=>getu_persistent(
         i_dliname = lv_mlrec
         i_private = space ).


      CALL METHOD send_request->add_recipient
        EXPORTING
          i_recipient = recipient
          i_express   = ca_x.

      CALL METHOD send_request->send(
        EXPORTING
          i_with_error_screen = ca_x
        RECEIVING
          result              = sent_to_all ).
      COMMIT WORK.

    CATCH cx_bcs INTO bcs_exception.
      WRITE: text-040.
      WRITE: text-041, bcs_exception->error_type.
*      EXIT.
  ENDTRY.

endform.

  FORM f_head_cont.
  CLEAR: i_text[], wa_text, subject.
  att_type = ca_raw.
  subject = 'SUBJECT'.
  wa_text = 'TEXT'.
  APPEND wa_text TO i_text.
  DESCRIBE TABLE i_text LINES n10.
  n10 = ( n10 - 1 ) * 255 + STRLEN( i_text ).
  i_lenght = n10.
  TRY.
      document = cl_document_bcs=>create_document(
                i_type    = att_type
                i_text    = i_text[]
                i_length  = i_lenght
                i_subject = subject ).
    CATCH cx_bcs INTO bcs_exception.
      WRITE: text-040.
      WRITE: text-041, bcs_exception->error_type.
      EXIT.

  ENDTRY.
ENDFORM.                    "HEAD_CONT


FORM f_raw_att.
  DATA : lw_error LIKE LINE OF i_error.

  CLEAR: i_text[], wa_text, subject.
  att_type = ca_raw.
  subject = text-050.
* Lenght of Att_Text
  DESCRIBE TABLE i_error LINES n10.
  READ TABLE i_error INTO lw_error INDEX n10.
  n10 = ( n10 - 1 ) * 255 + STRLEN( i_error ).
  i_lenght = n10.
  TRY.
      CALL METHOD document->add_attachment
        EXPORTING
          i_attachment_type    = att_type
          i_att_content_text   = i_error[]
          i_attachment_size    = i_lenght
          i_attachment_subject = subject.
*Error Message
    CATCH cx_bcs INTO bcs_exception.
      WRITE: text-040.
      WRITE: text-041, bcs_exception->error_type.
      EXIT.

  ENDTRY.
ENDFORM.                    "ATT_RAW
