class ZCL_TRELLO_API definition
  public
  final
  create public .

public section.

  interfaces ZIF_TRELLO_CLIENT .

  methods CONSTRUCTOR .
  class-methods CLASS_CONSTRUCTOR .
  methods GET_BOARDS
    returning
      value(RO_BOARDS) type ref to ZCL_TRELLO_BOARDS .
  PROTECTED SECTION.
private section.

  data MO_BOARDS type ref to ZCL_TRELLO_BOARDS .
ENDCLASS.



CLASS ZCL_TRELLO_API IMPLEMENTATION.


  METHOD class_constructor.

    CALL FUNCTION 'UACC_CHECK_RFC_DEST_EXISTS' "Check if RFC Destination exists
      EXPORTING
        iv_rfc_dest    = 'ZTRELLOAPI' " rfcdest       Logical destination (specified in function call)
      EXCEPTIONS
        rfcdest_exists = 1.          "               RFC Destination exists
    IF sy-subrc <> 0.
*     todo error handling
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    CALL METHOD cl_http_client=>create_by_destination
      EXPORTING
        destination              = 'ZTRELLOAPI' " Logical destination (specified in function call)
      IMPORTING
        client                   = zif_trello_client~mo_client
      EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6.
    IF sy-subrc <> 0.
*  MESSAGE e000(z_xyz) WITH 'Error during URL creation'.
*  TODO
    ENDIF.

  ENDMETHOD.


  METHOD get_boards.

    DATA: lt_boards TYPE zif_trello_client~mtty_boards.

    zif_trello_client~mo_client->request->set_method( if_http_request=>co_request_method_get ).

    cl_http_utility=>set_request_uri(
      EXPORTING
        request =     zif_trello_client~mo_client->request
        uri     =     |members/kinghr_tsapnw@king-ict.hr/boards?fields=id,name&{ zif_trello_client~co_key_token }| ).

* Send the HTTP request
    CALL METHOD zif_trello_client~mo_client->send
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        OTHERS                     = 5.
    IF sy-subrc <> 0.
      MESSAGE e000(z_xyz) WITH 'Error during HTTP send'.
*     TODO raise exception
    ENDIF.

* HTTP call receive
    CALL METHOD zif_trello_client~mo_client->receive
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      MESSAGE e000(z_xyz) WITH 'Error during HTTP receive'.
*     TODO raise exception
    ENDIF.

    DATA(lo_rest_client) = NEW cl_rest_http_client( io_http_client = zif_trello_client~mo_client ).
    DATA(lo_response) = lo_rest_client->if_rest_client~get_response_entity( ).
    DATA(response) = lo_response->get_string_data( ).

    CALL METHOD cl_fdt_json=>json_to_data
      EXPORTING
        iv_json = response
      CHANGING
        ca_data = lt_boards.

    ro_boards = NEW zcl_trello_boards( io_trello_client = zif_trello_client~mo_client
                                       it_boards = lt_boards ).

  ENDMETHOD.
ENDCLASS.
