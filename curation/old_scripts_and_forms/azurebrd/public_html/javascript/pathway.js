

window.onload = function() {					// by default hide all spans that contain expanded arrow 
  YAHOO.example.BasicRemote = function() {
    // Use an XHRDataSource
//     var oDS = new YAHOO.util.XHRDataSource("http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/autocomplete/phenont_autocomplete.cgi");
    var oDS = new YAHOO.util.XHRDataSource("pathway.cgi?action=autocompleteXHR&field=Process&");

    // Set the responseType
    oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;
    // Define the schema of the delimited results
    oDS.responseSchema = {
        recordDelim: "\n",
        fieldDelim: "\t"
    };
    oDS.maxCacheEntries = 5;            // Enable caching

    // Instantiate the AutoComplete
    var forcedOAC = new YAHOO.widget.AutoComplete("forcedProcessInput", "forcedProcessContainer", oDS);
    forcedOAC.maxResultsDisplayed = 20;
    forcedOAC.forceSelection = true;
    forcedOAC.itemSelectEvent.subscribe(onItemSelect);
//     forcedOAC.itemArrowToEvent.subscribe(onItemHighlight);
//     forcedOAC.itemMouseOverEvent.subscribe(onItemHighlight);
    return {
        oDS: oDS,
        forcedOAC: forcedOAC
    };
  }();
} 

function RemoveSelected(field) {                        // remove selected values from the select field and resize
    var elSel = document.getElementById('select' + field);
    var size = document.getElementById('select' + field).size;
    var i;
    for (i = elSel.length - 1; i>=0; i--) {
        if (elSel.options[i].selected) {
            elSel.remove(i);
            size--;
        }
    }
    document.getElementById('select' + field).size = size;
}

function onItemSelect(oSelf , elItem , oData) {		// if an item is chose, populate obo and add to list
// from http://74.125.155.132/search?q=cache:1X4UPeX9TkAJ:extjs.com/forum/showthread.php%3Ft%3D1202+yui+itemselectevent&cd=5&hl=en&ct=clnk&gl=us
    var field = 'Process';
    var freeField = "containerFree" + field + "AutoComplete";
    var forcedField = "containerForced" + field + "AutoComplete";
    var freeInput = "free" + field + "Input";
    var forcedInput = "forced" + field + "Input";
    if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
        PopulateSelectFromObo('Process', forcedInput);
    }
    else {
        PopulateSelectFromObo('Process', freeInput);
    }
    document.getElementById(forcedInput).value = '';
}

function PopulateSelectFromObo(field, inputField) {                     // append to select field based on obo value
    var text = document.getElementById(inputField).value;               // from input
    var match = text.match(/name: (.*?)\n/);    // capture the field from the tr id
    if (match != null) {
        var result_text = match[1];                             // if there's a match, grab the name
        match = text.match(/id: (.*?)\n/);              // capture the field from the id
        if (match != null) { text = result_text + " (" + match[1] + ")"; }              // if there's a match, append the WBPhenotype:\d+
    }
    PopulateSelect(field, text);
}

function PopulateSelect(field, text) {                  // append to select field based on passed text value
    var elSel = document.getElementById('select' + field);
    var elOptNew = document.createElement('option');
    if (elSel.size < 6) { elSel.size++; }               // make the select bigger until it gets to six  2009 06 14
    elOptNew.text = text;
    elOptNew.value = text;
    try { elSel.add(elOptNew, null); }  // standards compliant; doesn't work in IE
    catch(ex) { elSel.add(elOptNew); }  // IE only
}

function populateSelectFields() {                       // select fields cannot be passed to cgi, populate hidden fields based on them
    var associatedprocess = '';
    var elSel = document.getElementById('selectProcess');
    var i;
    for (i = elSel.length - 1; i>=0; i--) {
        if (elSel.options[i].text) { associatedprocess += elSel.options[i].text + "|"; }
    }
    document.getElementById("associatedprocess").value = associatedprocess;
}


// function onItemHighlight(oSelf , elItem) {		// if an item is highlighted from arrows or mouseover, populate obo
//     var field = 'Process';
//     var freeField = "containerFree" + field + "AutoComplete";
//     var forcedField = "containerForced" + field + "AutoComplete";
//     var freeInput = "free" + field + "Input";
//     var forcedInput = "forced" + field + "Input";
//     if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
//         MatchFieldExpandTextarea('processObo', elItem[1].innerHTML);
//     }
//     else {
//         MatchFieldExpandTextarea('processObo', elItem[1].innerHTML);
//     }
// }

