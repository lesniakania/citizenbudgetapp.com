//= require active_admin/base
//= require bootstrap
//= require swfobject
//= require jquery.clippy
//= require i18n

$ ->
  $('[rel="tooltip"]').tooltip()

  # URL with token.
  $(document).on 'mouseup', '.url-with-token', ->
    $(this).select()

  $('.clippy').each ->
    $this = $ this
    $this.clippy
      clippy_path: '/assets/clippy.swf'
      flashvars:
        args: $this.data 'tooltip'

  window.clippyCopiedCallback = (args) ->
    $('#' + args).attr('data-original-title', t('copied_hint')).tooltip('show').attr('data-original-title', t('copy_hint'))

  # Sortable sections and questions.
  $('.sortable').sortable
    axis: 'y'
    cursor: 'move'
    handle: 'i'
    update: (event, ui) ->
      $target = $ event.target
      $.ajax
        type: 'POST'
        url: location.href + '/sort'
        data: $target.sortable 'serialize'
      .done (request) ->
        $target.effect 'highlight'

  # Display the appropriate options for the selected widget.
  setup_fieldset = (i) ->
    widget = $("#section_questions_attributes_#{i}_widget")

    # @todo default_value should be rendered as a checkbox if widget is onoff or checkbox

    toggle_options = ->
      $("#section_questions_attributes_#{i}_options_as_list_input"
      ).toggle(widget.val() in ['checkboxes', 'radio', 'select'])

      $("#section_questions_attributes_#{i}_default_value_input,
         #section_questions_attributes_#{i}_unit_amount_input"
      ).toggle(widget.val() in ['checkbox', 'onoff', 'slider'])

      $("#section_questions_attributes_#{i}_minimum_units_input,
         #section_questions_attributes_#{i}_maximum_units_input,
         #section_questions_attributes_#{i}_step_input,
         #section_questions_attributes_#{i}_unit_name_input"
      ).toggle(widget.val() == 'slider')

    widget.change toggle_options
    toggle_options()

  $('.has_many.questions .button:last').click ->
    setup_fieldset $('.has_many.questions fieldset:last [id]').attr('id').match(/\d+/)[0]

  $('.has_many.questions fieldset').each setup_fieldset

# Dashboard charts.
window.draw = (chart_type, id, headers, rows, options) ->
  google.setOnLoadCallback ->
    data = new google.visualization.DataTable()
    data.addColumn if chart_type is 'LineChart' then 'date' else 'string'
    data.addColumn('number', header) for header in headers
    data.addRows(rows)
    new google.visualization[chart_type](document.getElementById(id)).draw data,
      $.extend
        backgroundColor: '#f4f4f4'
        gridlineColor: '#f4f4f4'
      , options
