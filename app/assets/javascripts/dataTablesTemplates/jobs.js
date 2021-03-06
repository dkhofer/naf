// When document is ready
jQuery(document).ready(function() {
  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "aaSorting": [[10, 'desc']],
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [1, 4, 7, 8, 9, 11, 12] },  // turn off sorting
      { "bVisible": false, "aTargets": [11] },                      // turn off visibility
      { "sClass": "center", "aTargets": [12] }
    ],
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "3%"},                              // Id
        { "sWidth": "7%"},                              // Server
        { "sWidth": "4%"},                              // Pid
        { "sWidth": "12%"},                             // Queued Time
        { "sWidth": "25%"},                             // Title
        { "sWidth": "11%"},                             // Started At
        { "sWidth": "11%"},                             // Finished At
        { "sWidth": "7%"},                              // Run Time
        { "sWidth": "12%"},                             // Affinities
        { "sWidth": "8%"},                              // Tags
        { "asSorting": [ "desc" ], "sWidth": "6%" },    // Status
        null,                                           // Application URL
        { "sWidth": "6%"}                               // Actions
    ],
    "fnInitComplete" : function() {
      initPageSelect();
      setPageOrder();
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
        addTitles();
      });
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToJob(nRow, aData);
      addLinkToTitle(nRow, aData);
      alignmentButtons(nRow, aData);
      colorizationStatus(nRow, aData);
      checkTimeFormat(nRow, aData);
      return nRow;
    },
    "sDom": "Rlfrtip"
  };

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  // Action: Terminate Job
  jQuery(document).delegate('.terminate', "click", function(){
    var answer = confirm("You are terminating this job. Are you sure you want to do this?");
    if (!answer) {
      return false;
    }
    var id = jQuery(this).attr('id');
    var url = 'job_system/historical_jobs/' + id;
    jQuery.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      data: { "historical_job[request_to_terminate]": 1, "historical_job_id": id, "_method": "put" },
      success:function (data) {
        if (data.success) {
          var title = data.title ? data.title : data.command
          jQuery("<p id='notice'>A Job " + title + " was terminated!</p>").
          appendTo('#flash_message').slideDown().delay(5000).slideUp();
          jQuery('#datatable').dataTable().fnDraw();
        }
      }
    });
  });

  jQuery(document).delegate('.re-enqueue', "click", function(){
    var url = jQuery(this).attr('content');
    var new_params = { data: jQuery(this).attr('data') };
    new_params['job_id'] = jQuery(this).attr('id');

    if (jQuery(this).attr('app_id')) {
      new_params['app_id'] = jQuery(this).attr('app_id');
    }
    
    if (jQuery(this).attr('link')) {
      new_params['link'] = jQuery(this).attr('link');
    }
    
    if (jQuery(this).attr('title_name')) {
      new_params['title_name'] = jQuery(this).attr('title_name');
    }
    
    var answer = confirm("Would you like to enqueue this job?");
    
    if (!answer) {
      return false;
    }
    jQuery.post(url, new_params, function (data) {
      if (data.success) {
        jQuery("<p id='notice'>Congratulations, a Job " + data.title + " was added!</p>").
        appendTo('#flash_message').slideDown().delay(5000).slideUp();
        setTimeout('window.location.reload()', 5600);
      }
      else {
        jQuery("<div class='error'>Sorry, \'" +  data.title +
          "\' cannot add a Job to the queue right now!</div>").
          appendTo('#flash_message').slideDown().delay(5000).slideUp();
        jQuery('#datatable').dataTable().fnDraw();
      }
    });
  });
});

function addLinkToJob(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="job_system/historical_jobs/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function addLinkToTitle(nRow, aData) {
  var link = aData[11];
  var title = aData[4];
  if ( link != "" ) {
    var row = jQuery('<a href="' + link + '">' + title + '</a>' );
    jQuery('td:nth-child(5)', nRow).empty().append(row);
  }
}

function checkTimeFormat(nRow, aData) {
  var start_array = aData[5].split(',');
  var finish_array = aData[6].split(',');
  var run_time_array = aData[7].split(',');
  var started_at;
  var finished_at;
  var run_time;
  if(jQuery('#time_format').val() == 'lexically') {
    started_at = start_array[0];
    finished_at = finish_array[0];
    run_time = run_time_array[0];
  } else {
    started_at = start_array[1];
    finished_at = finish_array[1];
    run_time = run_time_array[1];
  }

  jQuery('td:nth-child(6)', nRow).empty().append(started_at);
  jQuery('td:nth-child(7)', nRow).empty().append(finished_at);
  jQuery('td:nth-child(8)', nRow).empty().append(run_time);
}

function alignmentButtons(nRow, aData) {
  // Action buttons
  var data = aData[12];
  var row;
  if (aData[10] != "Canceled") {
      row = "<div style='text-align:left;width:50px;display: inline;'>" + data + "</div>";
  } else {
      row = "<div style='text-align:left;width:50px;display: inline;padding-right: 16px;'>" + data + "</div>";
  }
  jQuery('td:nth-child(12)', nRow).empty().append(row);
}

// Function that changes the color of the job status
function colorizationStatus(nRow, aData) {
  jQuery('td:nth-child(11)', nRow).wrapInner('<div class="">');
  switch(aData[10]) {
    case 'Running':
      jQuery('td:nth-child(11) div', nRow).addClass('script-running');
      break;
    case 'Queued':
      jQuery('td:nth-child(11) div', nRow).addClass('script-queued');
      break;
    case 'Waiting':
      jQuery('td:nth-child(11) div', nRow).addClass('script-queued');
      break;
    case 'Canceled':
      break;
    case 'Finished':
      jQuery('td:nth-child(11) div', nRow).addClass('script-finished');
      break;
    default:
      jQuery('td:nth-child(11) div', nRow).addClass('script-error');
      break;
  }
}

function setPageOrder(){
  var status = jQuery("#search_status").val();
  if (status == 'finished' || status == 'errored') {
    jQuery('#datatable').dataTableSettings[0].aoColumns[10].bSortable = false;
    jQuery('#datatable thead tr th:nth-child(11) div span').css("display", "none");
    jQuery('#datatable').dataTable().fnSort([ [6,'desc'] ]);
  } else {
    jQuery('#datatable').dataTableSettings[0].aoColumns[10].bSortable = true;
    jQuery('#datatable').dataTable().fnSort([ [10,'desc'] ]);
    jQuery('#datatable thead tr th:nth-child(11) div span').css("display", "block");
  }
}
