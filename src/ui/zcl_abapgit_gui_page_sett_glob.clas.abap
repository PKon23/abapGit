CLASS zcl_abapgit_gui_page_sett_glob DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_gui_component
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    INTERFACES zif_abapgit_gui_event_handler.
    INTERFACES zif_abapgit_gui_renderable.

    CLASS-METHODS create
      RETURNING
        VALUE(ri_page) TYPE REF TO zif_abapgit_gui_renderable
      RAISING
        zcx_abapgit_exception.
    METHODS constructor
      RAISING
        zcx_abapgit_exception.
  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_id,
        proxy_settings           TYPE string VALUE 'proxy_settings',
        proxy_url                TYPE string VALUE 'proxy_url',
        proxy_port               TYPE string VALUE 'proxy_port',
        proxy_auth               TYPE string VALUE 'proxy_auth',
        proxy_bypass             TYPE string VALUE 'proxy_bypass',
        commit_settings          TYPE string VALUE 'commit_settings',
        commitmsg_comment_length TYPE string VALUE 'commitmsg_comment_length',
        commitmsg_comment_deflt  TYPE string VALUE 'commitmsg_comment_deflt',
        commitmsg_body_size      TYPE string VALUE 'commitmsg_body_size',
        devint_settings          TYPE string VALUE 'devint_settings',
        run_critical_tests       TYPE string VALUE 'run_critical_tests',
        experimental_features    TYPE string VALUE 'experimental_features',
        activate_wo_popup        TYPE string VALUE 'activate_wo_popup',
      END OF c_id.
    CONSTANTS:
      BEGIN OF c_event,
        go_back      TYPE string VALUE 'go-back',
        proxy_bypass TYPE string VALUE 'proxy_bypass',
        save         TYPE string VALUE 'save',
      END OF c_event.
    DATA mo_settings TYPE REF TO zcl_abapgit_settings.
    DATA mo_validation_log TYPE REF TO zcl_abapgit_string_map.
    DATA mo_form_data TYPE REF TO zcl_abapgit_string_map.
    DATA mo_form TYPE REF TO zcl_abapgit_html_form.

    METHODS validate_form
      IMPORTING
        !io_form_data            TYPE REF TO zcl_abapgit_string_map
      RETURNING
        VALUE(ro_validation_log) TYPE REF TO zcl_abapgit_string_map
      RAISING
        zcx_abapgit_exception.
    METHODS get_form_schema
      RETURNING
        VALUE(ro_form) TYPE REF TO zcl_abapgit_html_form.
    METHODS read_settings
      RAISING
        zcx_abapgit_exception.
    METHODS save_settings
      RAISING
        zcx_abapgit_exception.
    METHODS read_proxy_bypass
      RAISING
        zcx_abapgit_exception.
    METHODS save_proxy_bypass
      RAISING
        zcx_abapgit_exception.
ENDCLASS.



CLASS ZCL_ABAPGIT_GUI_PAGE_SETT_GLOB IMPLEMENTATION.


  METHOD constructor.

    super->constructor( ).
    CREATE OBJECT mo_validation_log.
    CREATE OBJECT mo_form_data.
    mo_form = get_form_schema( ).

  ENDMETHOD.


  METHOD create.

    DATA lo_component TYPE REF TO zcl_abapgit_gui_page_sett_glob.

    CREATE OBJECT lo_component.

    ri_page = zcl_abapgit_gui_page_hoc=>create(
      iv_page_title      = 'Global Settings'
      io_page_menu       = zcl_abapgit_gui_chunk_lib=>settings_toolbar(
                             zif_abapgit_definitions=>c_action-go_settings )
      ii_child_component = lo_component ).

  ENDMETHOD.


  METHOD get_form_schema.

    CONSTANTS lc_abapgit_prog TYPE progname VALUE `ZABAPGIT`.

    ro_form = zcl_abapgit_html_form=>create(
      iv_form_id   = 'global-setting-form'
      iv_help_page = 'https://docs.abapgit.org/guide-settings-global.html' ).

    ro_form->start_group(
      iv_name        = c_id-proxy_settings
      iv_label       = 'Proxy Settings'
    )->text(
      iv_name        = c_id-proxy_url
      iv_label       = 'Proxy Host'
      iv_hint        = 'Hostname or IP of proxy required to access the Internet (do not enter http://)'
      iv_placeholder = 'Hostname or IP without http://'
    )->number(
      iv_name        = c_id-proxy_port
      iv_label       = 'Proxy Port'
      iv_hint        = 'Port of proxy required to access the Internet'
      iv_min         = 0
      iv_max         = 65535
    )->checkbox(
      iv_name        = c_id-proxy_auth
      iv_label       = 'Proxy Authentication'
      iv_hint        = 'Check, if proxy requires you to login'
    )->textarea(
      iv_name        = c_id-proxy_bypass
      iv_label       = 'Proxy Bypass'
      iv_hint        = 'List of hosts/domains for which to bypass using proxy'
    )->start_group(
      iv_name        = c_id-commit_settings
      iv_label       = 'Commit Message Settings'
    )->number(
      iv_name        = c_id-commitmsg_comment_length
      iv_required    = abap_true
      iv_label       = 'Maximum Length of Comment'
      iv_hint        = |At least { zcl_abapgit_settings=>c_commitmsg_comment_length_dft } characters|
      iv_min         = zcl_abapgit_settings=>c_commitmsg_comment_length_dft
    )->text(
      iv_name        = c_id-commitmsg_comment_deflt
      iv_label       = 'Default Text For Comment'
      iv_hint        = 'You can use $OBJECT or $FILE to include the number of objects/files'
    )->number(
      iv_name        = c_id-commitmsg_body_size
      iv_required    = abap_true
      iv_label       = 'Maximum Line Size of Body'
      iv_hint        = |At least { zcl_abapgit_settings=>c_commitmsg_body_size_dft } characters|
      iv_min         = zcl_abapgit_settings=>c_commitmsg_body_size_dft ).

    IF zcl_abapgit_services_abapgit=>is_installed( ) = abap_true AND sy-cprog = lc_abapgit_prog.
      ro_form->start_group(
        iv_name        = c_id-devint_settings
        iv_label       = 'Development Internal Settings'
      )->checkbox(
        iv_name        = c_id-run_critical_tests
        iv_label       = 'Enable Critical Unit Tests'
      )->checkbox(
        iv_name        = c_id-experimental_features
        iv_label       = 'Enable Experimental Features' ).
    ENDIF.

    ro_form->command(
      iv_label       = 'Save Settings'
      iv_is_main     = abap_true
      iv_action      = c_event-save
    )->command(
      iv_label       = 'Back'
      iv_action      = c_event-go_back ).

  ENDMETHOD.


  METHOD read_proxy_bypass.

    DATA:
      lt_proxy_bypass TYPE zif_abapgit_definitions=>ty_range_proxy_bypass_url,
      ls_proxy_bypass LIKE LINE OF lt_proxy_bypass,
      lv_val          TYPE string.

    lt_proxy_bypass = mo_settings->get_proxy_bypass( ).
    LOOP AT lt_proxy_bypass INTO ls_proxy_bypass.
      lv_val = lv_val && ls_proxy_bypass-low && zif_abapgit_definitions=>c_crlf.
    ENDLOOP.

    mo_form_data->set(
      iv_key = c_id-proxy_bypass
      iv_val = lv_val ).

  ENDMETHOD.


  METHOD read_settings.

    " Get settings from DB
    mo_settings = zcl_abapgit_persist_settings=>get_instance( )->read( ).

    " Proxy
    mo_form_data->set(
      iv_key = c_id-proxy_url
      iv_val = mo_settings->get_proxy_url( ) ).
    mo_form_data->set(
      iv_key = c_id-proxy_port
      iv_val = mo_settings->get_proxy_port( ) ).
    mo_form_data->set(
      iv_key = c_id-proxy_auth
      iv_val = mo_settings->get_proxy_authentication( ) ).

    read_proxy_bypass( ).

    " Commit Message
    mo_form_data->set(
      iv_key = c_id-commitmsg_comment_length
      iv_val = |{ mo_settings->get_commitmsg_comment_length( ) }| ).
    mo_form_data->set(
      iv_key = c_id-commitmsg_comment_deflt
      iv_val = mo_settings->get_commitmsg_comment_default( ) ).
    mo_form_data->set(
      iv_key = c_id-commitmsg_body_size
      iv_val = |{ mo_settings->get_commitmsg_body_size( ) }| ).

    " Dev Internal
    mo_form_data->set(
      iv_key = c_id-run_critical_tests
      iv_val = |{ mo_settings->get_run_critical_tests( ) }| ).
    mo_form_data->set(
      iv_key = c_id-experimental_features
      iv_val = |{ mo_settings->get_experimental_features( ) }| ).

  ENDMETHOD.


  METHOD save_proxy_bypass.

    DATA:
      lt_textarea     TYPE TABLE OF string,
      lt_proxy_bypass TYPE zif_abapgit_definitions=>ty_range_proxy_bypass_url,
      ls_proxy_bypass LIKE LINE OF lt_proxy_bypass.

    lt_textarea = zcl_abapgit_convert=>split_string( mo_form_data->get( c_id-proxy_bypass ) ).

    ls_proxy_bypass-sign = 'I'.
    ls_proxy_bypass-option = 'EQ'.
    LOOP AT lt_textarea INTO ls_proxy_bypass-low WHERE table_line IS NOT INITIAL.
      APPEND ls_proxy_bypass TO lt_proxy_bypass.
    ENDLOOP.

    mo_settings->set_proxy_bypass( lt_proxy_bypass ).

  ENDMETHOD.


  METHOD save_settings.

    DATA:
      lo_persistence TYPE REF TO zcl_abapgit_persist_settings,
      lv_value       TYPE i.

    " Proxy
    mo_settings->set_proxy_url( mo_form_data->get( c_id-proxy_url ) ).
    mo_settings->set_proxy_port( mo_form_data->get( c_id-proxy_port ) ).
    mo_settings->set_proxy_authentication( boolc( mo_form_data->get( c_id-proxy_auth ) = abap_true ) ).

    save_proxy_bypass( ).

    " Commit Message
    lv_value = mo_form_data->get( c_id-commitmsg_comment_length ).
    mo_settings->set_commitmsg_comment_length( lv_value ).
    mo_settings->set_commitmsg_comment_default( mo_form_data->get( c_id-commitmsg_comment_deflt ) ).
    lv_value = mo_form_data->get( c_id-commitmsg_body_size ).
    mo_settings->set_commitmsg_body_size( lv_value ).

    " Dev Internal
    mo_settings->set_run_critical_tests( boolc( mo_form_data->get( c_id-run_critical_tests ) = abap_true ) ).
    mo_settings->set_experimental_features( boolc( mo_form_data->get( c_id-experimental_features ) = abap_true ) ).

    " Store in DB
    lo_persistence = zcl_abapgit_persist_settings=>get_instance( ).
    lo_persistence->modify( mo_settings ).

    MESSAGE 'Settings succesfully saved' TYPE 'S'.

  ENDMETHOD.


  METHOD validate_form.

    ro_validation_log = mo_form->validate_required_fields( io_form_data ).

    IF io_form_data->get( c_id-proxy_url ) IS NOT INITIAL AND io_form_data->get( c_id-proxy_port ) IS INITIAL OR
       io_form_data->get( c_id-proxy_url ) IS INITIAL AND io_form_data->get( c_id-proxy_port ) IS NOT INITIAL.
      ro_validation_log->set(
        iv_key = c_id-proxy_url
        iv_val = |If you specify a proxy, you have to specify host and port| ).
    ENDIF.

    IF ( io_form_data->get( c_id-proxy_url ) IS INITIAL OR io_form_data->get( c_id-proxy_port ) IS INITIAL ) AND
       io_form_data->get( c_id-proxy_auth ) = abap_true.
      ro_validation_log->set(
        iv_key = c_id-proxy_auth
        iv_val = |To turn on authentication, you have to specify host and port| ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.

    mo_form_data = mo_form->normalize_form_data( ii_event->form_data( ) ).

    CASE ii_event->mv_action.
      WHEN c_event-go_back.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-go_back.

      WHEN c_event-save.
        " Validate all form entries
        mo_validation_log = validate_form( mo_form_data ).

        IF mo_validation_log->is_empty( ) = abap_true.
          save_settings( ).

          rs_handled-state = zcl_abapgit_gui=>c_event_state-go_back.
        ELSE.
          rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render. " Display errors
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD zif_abapgit_gui_renderable~render.

    gui_services( )->register_event_handler( me ).

    read_settings( ).

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    ri_html->add( mo_form->render(
      iv_form_class     = 'dialog w600px m-em5-sides margin-v1'
      io_values         = mo_form_data
      io_validation_log = mo_validation_log ) ).

  ENDMETHOD.
ENDCLASS.
