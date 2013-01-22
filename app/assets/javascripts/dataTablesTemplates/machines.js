// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
    },
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "2%"},
        { "sWidth": "12%"},
        { "sWidth": "8%"},
        { "sWidth": "14%"},
        { "sWidth": "5%"},
        { "sWidth": "10%"},
        { "sWidth": "175px"},
        null,
        { "sWidth": "6%"},
        { "sWidth": "10%"},
        { "sWidth": "70px"}
    ],
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToMachines(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery(document).on("click", '.terminate', function(){
    var answer = confirm("You are going to mark machine down. Are you sure you want to do this?");
    if (!answer) {
      return false;
    }
    var id = jQuery(this).attr('id');
    var url = '/job_system/machines/' + id;
    jQuery.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      data: { "machine[marked_down]": 1, "terminate": true, "_method": "put" },
      success:function (data) {
          if (data.success) {
              jQuery("<p id='notice'>Machine was marked down!</p>").
                  appendTo('#flash_message').slideDown().delay(5000).slideUp();
              jQuery('#datatable').dataTable().fnDraw();
          }
      }
    });
  });
});

function addLinkToMachines(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/machines/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}