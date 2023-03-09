// added JS and CSS to editor frame, still hardcoding yui autocomplete.  
// Need to generalize it and deal with highlighting / selecting values. 
// Make a css class for autocomplete input fields so as not to make a css #class
// for each of them (in the CGI)
// Possibly figure out a way to have top webpage load JS for all frames, but
// that might not be possible (instead of each frame loading the same JS files)
// 2009 09 29

YAHOO.util.Event.addListener(window, "load", function() { 	// on load get fields, assign listeners
  setAutocompleteListeners();
}); // YAHOO.util.Event.addListener(window, "load", function() 

function setAutocompleteListeners() {
// YAHOO.example.BasicRemote = function() {
//     var oDS = new YAHOO.util.XHRDataSource("http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/autocomplete/phenont_autocomplete.cgi");					// Use an XHRDataSource
//     oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;	// Set the responseType
//     oDS.responseSchema = {					// Define the schema of the delimited results
//         recordDelim: "\n",
//         fieldDelim: "\t"
//     };
//     oDS.maxCacheEntries = 5;					// Enable caching
// 
//     var field = "term";
//     var forcedOrFree = "forced";
//     var inputElement = top.frames['editor'].document.getElementById("input_" + field);
//     var containerElement = top.frames['editor'].document.getElementById(forcedOrFree + field + "Container");
//     var forcedOAC = new YAHOO.widget.AutoComplete(inputElement, containerElement, oDS);
// //     var forcedOAC = new YAHOO.widget.AutoComplete("input_term", "forcedtermContainer", oDS);
//     forcedOAC.maxResultsDisplayed = 20;
//     forcedOAC.forceSelection = true;
// //     forcedOAC.itemSelectEvent.subscribe(onItemSelect);
// //     forcedOAC.itemArrowToEvent.subscribe(onItemHighlight);
// //     forcedOAC.itemMouseOverEvent.subscribe(onItemHighlight);
// 
//     return {
//         oDS: oDS,
//         forcedOAC: forcedOAC
//     };
// }();

YAHOO.example.BasicRemote = function() {
    // Use an XHRDataSource
    var oDS = new YAHOO.util.XHRDataSource("http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/autocomplete/gene_autocomplete.cgi");
    // Set the responseType
    oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;
    // Define the schema of the delimited results
    oDS.responseSchema = {
        recordDelim: "\n",
        fieldDelim: "\t"
    };
    // Enable caching
    oDS.maxCacheEntries = 5;

//     // Instantiate the AutoComplete
//     var freeOAC = new YAHOO.widget.AutoComplete("freeGeneInput", "freeGeneContainer", oDS);
//     freeOAC.maxResultsDisplayed = 20;

//     var forcedOAC = new YAHOO.widget.AutoComplete("forcedGeneInput", "forcedGeneContainer", oDS);
    var forcedOAC = new YAHOO.widget.AutoComplete("input_wbgene", "forcedwbgeneContainer", oDS);
    forcedOAC.maxResultsDisplayed = 20;
    forcedOAC.forceSelection = true;

    return {
        oDS: oDS,
        forcedOAC: forcedOAC
    };
}();

}


// NEED TO load stuff from autocomp_test.js
// function onItemHighlight(oSelf , elItem) {              // if an item is highlighted from arrows or mouseover, populate obo
//     var field = 'Phenont';
//     var freeField = "containerFree" + field + "AutoComplete";
//     var forcedField = "containerForced" + field + "AutoComplete";
//     var freeInput = "free" + field + "Input";
//     var forcedInput = "forced" + field + "Input";
//     if ( document.getElementById(forcedField).className == '' ) {               // forcedField showing
//         MatchFieldExpandTextarea('phenontObo', elItem[1].innerHTML);
// //         document.getElementById("phenontObo").innerHTML = elItem[1].innerHTML;
//     }
//     else {
//         MatchFieldExpandTextarea('phenontObo', elItem[1].innerHTML);
// //         document.getElementById("phenontObo").innerHTML = elItem[1].innerHTML;
//     }
// }
// 
// function onItemSelect(oSelf , elItem , oData) {         // if an item is chose, populate obo and add to list
// // from http://74.125.155.132/search?q=cache:1X4UPeX9TkAJ:extjs.com/forum/showthread.php%3Ft%3D1202+yui+itemselectevent&cd=5&hl=en&ct=clnk&gl=us
//     var field = 'Phenont';
//     var freeField = "containerFree" + field + "AutoComplete";
//     var forcedField = "containerForced" + field + "AutoComplete";
//     var freeInput = "free" + field + "Input";
//     var forcedInput = "forced" + field + "Input";
//     if ( document.getElementById(forcedField).className == '' ) {               // forcedField showing
//         PopulatePhenontObo('Phenont', 'forced');
//         PopulateSelectFromObo('Phenont');
//     }
//     else {
//         PopulatePhenontObo('Phenont', 'free');
//         PopulateSelectFromObo('Phenont');
//     }
// }

