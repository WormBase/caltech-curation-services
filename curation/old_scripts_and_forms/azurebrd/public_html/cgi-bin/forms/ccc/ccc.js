
// load autocomplete listeners for goterms calling the cgi with action autocompleteJQ, giving a type and by default a term

function toggleShowHide(element) {
    document.getElementById(element).style.display = (document.getElementById(element).style.display == "none") ? "" : "none";
    return false;
}


window.onload = function() {                                    // by default hide all spans that contain expanded arrow
  var toAlert = '';

  $(function() {
    if (document.getElementById("searchGoTermName")) {		// autocomplete on search of go term to get just the go term name from ccc_component_go_index
      $('#searchGoTermName').autocomplete({
        source: "ccc.cgi?action=autocompleteJQ&type=searchGoTermName",	// format is [{"item":"mylabe1","value":"myvalu1"},...]
        minLength: 2,
      });
    }
    if (document.getElementById("sentenceCounter")) {		// if there are a lot of sentence, for each of them autocomplete on each annotation row's goterm_ input element from obo_name_goid
      var snum = document.getElementById("sentenceCounter").value;
      var maxAnnotPerSent = document.getElementById("maxAnnotationsPerSentence").value;
//       alert(snum + " sentences");
//       alert(maxAnnotPerSent + " maxAnnotationsPerSentence");
      for (var i = 0; i <= snum; i++) {
        for (var j = 1; j <= maxAnnotPerSent; j++) {
          var trId = 'tr_' + i + '_' + j;
          if (j > 1) {
            if (document.getElementById(trId)) {
              document.getElementById(trId).style.display = 'none'; } }

// this didn't work because the function has i and j variables, and all listeners are loaded, then activating uses final i and j values instead of that row's
//           var geneprodId = 'geneprod_' + i + '_' + j;
//           var jPlusOne = j + 1;
//           var nextTrId = 'tr_' + i + '_' + jPlusOne;
//           if (document.getElementById(geneprodId)) { 
//             document.getElementById(geneprodId).onclick = function() { 
// alert("toggle " + nextTrId + " on");
//                 document.getElementById(nextTrId).style.display = ''; } }
        
          var id = '#goterm_' + i + '_' + j;
          $( id ).autocomplete({
            source: "ccc.cgi?action=autocompleteJQ&type=goterm",	// format is [{"item":"mylabe1","value":"myvalu1"},...]
            minLength: 2,
//   http://jqueryui.com/autocomplete/#remote
//             select: function( event, ui ) {		// need log function code for this to work, but we don't need it
//               log( ui.item ?
//               "Selected: " + ui.item.value + " aka " + ui.item.id :
//               "Nothing selected, input was " + this.value );
//             }
          });
        } // for (var j = 1; j <= maxAnnotPerSent; j++)
      } // for (var i = 0; i <= snum; i++)
    } // if (document.getElementById("sentenceCounter"))
  });

  if (toAlert) { alert(toAlert); }
} // window.onload = function() 


// http://jqueryui.com/autocomplete/#default
// $(function() {
//   var availableTags = [
//     "ActionScript",
//     "AppleScript",
//     "Asp",
//     "BASIC",
//     "C",
//     "C++",
//     "Clojure",
//     "COBOL",
//     "ColdFusion",
//     "Erlang",
//     "Fortran",
//     "Groovy",
//     "Haskell",
//     "Java",
//     "JavaScript",
//     "Lisp",
//     "Perl",
//     "PHP",
//     "Python",
//     "Ruby",
//     "Scala",
//     "Scheme"
//   ];
//   $( "#tags" ).autocomplete({
//     source: availableTags
//   });
// });
