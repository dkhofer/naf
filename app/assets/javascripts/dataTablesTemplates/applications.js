// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
      jQuery("#datatable").css("width","100%");
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToApplication(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
    jQuery('#datatable').addDataTable(dataTableOptions);
});

function addLinkToApplication(nRow, aData) {
  var title = aData[0];
  var id = aData[7];
  var row = jQuery('<a href="/job_system/applications/' + id + '">' + title + '</a>' );
  jQuery('td:nth-child(8)', nRow).empty();
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

