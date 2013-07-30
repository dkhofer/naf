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
        { "sWidth": "4%"},              // Id
        { "sWidth": "7%"},              // Server
        { "sWidth": "4%"},              // Pid
        { "sWidth": "14%"},             // Queued Time
        { "sWidth": "25%"},             // Title
        null,                           // Started At
        null,                           // Finished At
        null,                           // Run Time
        null,                           // Affinities
        null,                           // Tags
        { "asSorting": [ "desc" ] },    // Status
        null,                           // Application URL
        { "sWidth": "6%"}               // Actions
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
      return nRow;
    }
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
    var url = '/job_system/historical_jobs/' + id;
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
});

function addLinkToJob(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/historical_jobs/' + id + '">' + id + '</a>' );
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