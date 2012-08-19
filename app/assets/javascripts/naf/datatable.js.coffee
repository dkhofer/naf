jQuery ->

  # Some lengthy helper functions to search jobs, and create/enqueue them


  # Job Search Function
  #   Make GET request to jobs/
  #   read JSON response, render the results

  perform_job_search = (search_form) ->
     url = search_form.attr('action')
     $.ajax({
       type: "GET"
       dataType: 'json'
       url: url,
       data: search_form.serialize(),
       success: (data) ->
         setTimeout (-> 
           job_root_url = data.job_root_url
           $('table#datatable tbody').text('')
           if data.jobs.length == 0
             $('a#page_forward').hide()
             $('span#result_numbers').text('')
           else
             $('a#page_forward').show()
             offset = parseInt($('input#search_offset').val())
             limit = parseInt($('select#search_limit').val())
             lower = offset*limit + 1
             upper = lower + data.jobs.length - 1
             $('span#result_numbers').text('Results ' + lower + ' - ' + upper)
           for job in data.jobs
             class_label = job.status
             row = '<tr class=\"'+ class_label + '\" id=\"' + job.id + '\"' + ' data-url=\"' + data.job_root_url + '/' + job.id +  '\">' 
             for col in data.cols
               value = if job[col] == null then "" else job[col]
               row += "<td>" + value + "</td>"
             row += '<td id=\"action\">'
             row += '<a href=\"http://www.papertrailapp.com\"><img alt=\"Application_view_list\" class=\"action\" src=\"/assets/application_view_list.png\" title=\"View Log in Papertrail\" /></a>'
             row += "</td>"
             row += "</tr>"
             row_object = $(row)
             row_object.hide().appendTo('table#datatable tbody').slideDown(1000)
           $.unblockUI();
         ), 500;
     })
  
  # Create Job Function
  #   Make POST request to jobs/
  #   read JSON response
  #   render link to job on successful creation
  #   or ActiveRecord validation error messages

  create_job = (form) ->
    url = form.attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: form.serialize(),
      success: (data) ->
        setTimeout (-> 
          $.unblockUI();
          addedMessage = ' was added to the job queue'
          if data.saved
            $('td#main div#status').prepend('<p>' + '<a href=\"' + data.job_url + '\">' + data.post_source + '</a>'  + addedMessage + '</p>');
          else
            for msg in data.errors
              $('td#main div#status').prepend('<p style="color: red">' + msg + '</p>');
        ), 500; 
    })

  # Show Loading Message

  show_loading_message = (message) ->
    output = '<h5>'
    output += message
    output += '</h5>'
    output += '<img alt=\"Loading\" src=\"/assets/loading.gif\" />'
    output += '<br />'
    output += '<br />'
    $.blockUI({ message: output});



  # --------------------------------------------------
  # Naf System UI Event Handlers


  # Mostly just adding .jTPS class, may remove soon
 
  $('#datatable').jTPS()

 
  # Place modal views of messages/forms at the top of the screen
 
  $.blockUI.defaults.css.top = '10%'


  # Upon Page Loaded (really Jquery loaded),
  # If we are on the job page, run empty job search
  # to populate the jobs table 

  if $('p#on_job_page').text() == 'true'
    $('a#page_forward').show()
    show_loading_message('Loading Jobs')
    perform_job_search($('form#job_search'))


  # Provide modal view of Job Search form

  $('a.job_search').live 'click', (event) ->
    offset_element = $('input#search_offset')
    offset_element.val(0)
    $('a#page_back').hide()
    $.blockUI({ message: $('form#job_search') })

  
  # Exit from the Job Search form

  $('form#job_search input#cancel').click ->
    $.unblockUI();


  # Run the Job Search

  $('form#job_search').submit (event) ->
    event.preventDefault()
    show_loading_message('Applying your searches and filters to find jobs...')
    perform_job_search($(this))

  # Go to next page, rerun job search, ++offset
  $('a#page_forward').live 'click', (event) ->
    limit = $('select#search_limit').val()
    offset_element = $('input#search_offset')
    offset = parseInt(offset_element.val()) + 1
    if offset > 0
      $('a#page_back').show()
    offset_element.val(offset)
    show_loading_message('Loading the next ' + limit + ' jobs')
    perform_job_search($('form#job_search'))


  # Go to the previous page, rerun job search, --offset
  $('a#page_back').live 'click', (event) ->
    limit = $('select#search_limit').val()
    offset_element = $('input#search_offset')
    offset = parseInt(offset_element.val()) - 1
    if offset < 1
      $(this).hide()
    offset_element.val(offset)
    show_loading_message('Loading the previous ' + limit + ' jobs')
    perform_job_search($('form#job_search'))
    


  # On index action view of resources, make the table row a link
  # to show a specific resource

  $('.jTPS tbody tr td:not(#action)').live 'click', (event) ->
    window.location = $(this).parent().data('url');


  # Provide modal view of Job adding form

  $('a.add_job').click ->
    $.blockUI( { message: $('form#add_job') } )

  
  # Exit out from Job adding form

  $('form#add_job input#cancel').click ->
    $.unblockUI();


  # Add the job to the job queue

  $('form#add_job').submit (event) ->
    event.preventDefault()
    show_loading_message('Adding job to the job queue')
    create_job($(this))


  # Request confirmation that you want to enqueue the application as a job

  $('a.enqueue').click ->
    application_id = $(this).attr('id');
    $('form#enqueue_form input#application_id').val(application_id);
    $.blockUI({ message: $('#enqueue_confirm'), css: { left: '30%', width: '700px' } });


  # Yes you want to enqueue

  $('div#enqueue_confirm #yes').click ->
    $.blockUI({ message: $('#enqueue_form') }); 
     

  # No you don't want to enqueue

  $('div#enqueue_confirm #no').click ->
    $.unblockUI(); 
    return false;


  # Cancel out from enqueuing form

  $('div#enqueue_form #cancel').click ->
    $.unblockUI();
    return false;


  # Enqueue an application as a job, on the job queue

  $('form#enqueue_form').submit (event) ->
    event.preventDefault()
    show_loading_message('Adding application as a job on the queue')    
    create_job($(this))




  


 