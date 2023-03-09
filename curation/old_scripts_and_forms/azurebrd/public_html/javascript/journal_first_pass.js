// hide span_example and span_specify.  for span_hidden, check the textareas they contain ;  if no value hide the span,
// if there is a value resize the textarea and disable the checkbox.


window.onload = function() {		// hide all "tr"s with textareas by default
    if (!document.typeTwoForm) { return; }
// no longer hide sub-subcategories  2009 05 04
//     var patt1 = new RegExp("^tr_hidden");	// tr that have textareas have ids beginning with "tr"
//     var eleTableRows = document.typeTwoForm.getElementsByTagName("tr");	// get all trs
//     for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through trs
//         if (patt1.test( eleTableRows[i].id ) ) {			// if they match regexp
//              eleTableRows[i].className = 'displayNone';			// set style to displayNone
//         }
//     }
    var patt2 = new RegExp("^span_example");	// span that have textareas have ids beginning with "span_example"
//     var patt3 = new RegExp("^span_specify");	// span that have textareas have ids beginning with "span_specify"
//     no longer hide ``please specify your data type''  2009 05 04
    var eleTableRows = document.typeTwoForm.getElementsByTagName("span");	// get all trs
    for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through spans
//         if ( (patt3.test( eleTableRows[i].id ) ) || (patt2.test( eleTableRows[i].id ) ) ) 
        if ( patt2.test( eleTableRows[i].id ) ) {
             eleTableRows[i].className = 'displayNone';			// set style to displayNone
        }
    }
    var patt4 = new RegExp("^span_hidden");		// span that have textareas have ids beginning with "span_hidden"
    var eleTableRows = document.typeTwoForm.getElementsByTagName("textarea");	// get all trs
    for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through spans
        if (patt4.test( eleTableRows[i].parentNode.id ) ) {			// if they match regexp
             if (eleTableRows[i].value) { DisableCheckboxResizeTextarea(eleTableRows[i].id); }
             else { eleTableRows[i].parentNode.className = 'displayNone'; }			// set style to displayNone
        }
    }
//     document.getElementById("celegans_check").checked  = true; 	// default celegans checkbox checked (taken out and put into CGI since need to check if author has already sent data an possibly checked it off
    document.getElementById("span_hidden_genestudied").className = '';		// don't hide rgngene add info
//     document.getElementById("span_example_genestudied").className = '';		// don't hide ? info
//     document.getElementById("span_example_genesymbol").className = '';		// don't hide ? info
//     document.getElementById("span_example_extvariation").className = '';	// don't hide ? info
//     document.getElementById("span_example_newstrains").className = '';		// don't hide ? info
//     document.getElementById("span_example_newbalancers").className = '';	// don't hide ? info
//     document.getElementById("span_example_rnai").className = '';		// don't hide ? info
//     document.getElementById("span_example_newprotein").className = '';		// don't hide ? info
//     document.getElementById("span_example_transgene").className = '';		// don't hide ? info
//     document.getElementById("span_example_newsnp").className = '';		// don't hide ? info
//     document.getElementById("span_example_newcell").className = '';		// don't hide ? info
//     document.getElementById("span_example_authors").className = '';		// don't hide ? info
    
}

function DisableCheckboxResizeTextarea(field) {
    ExpandTextarea(field);	// both ExpandTextarea from test.js and disable or enable the checkbox  2009 03 09
    if (document.getElementById(field).value) { 
        document.getElementById(field + "_check").checked  = true; 
        document.getElementById(field + "_check").disabled = true; }
    else {
        document.getElementById(field + "_check").disabled = false; }
}

function ToggleHideSubcategories(field) {
    var fields = field.split(", ");
        // set the rowspan of the td with the checkbox to expand or contract as the other trs become hidden
    if ( document.getElementById("tr_hidden_" + fields[0]).className == '' ) {	
        document.getElementById("span_specify_" + field).className = 'displayNone'; 	// hide the ``specify'' text
        document.getElementById("td_" + field + "_check").rowSpan = 1; }
    else { 
        document.getElementById("span_specify_" + field).className = ''; 		// show the ``specify'' text
        document.getElementById("td_" + field + "_check").rowSpan = fields.length + 1; }
    for (var i = 0; i < fields.length; i++)  {  			// loop through trs
        var trfield = "tr_hidden_" + fields[i];
        if ( document.getElementById(trfield).className == '' ) { 
            document.getElementById(trfield).className = 'displayNone'; }
        else { 
            document.getElementById(trfield).className = '';
        }
    }
}


// removed again 2009 05 04
// function ToggleHideSpansExampleHidden(field) {
//     ToggleHideSpan('example', field);
//     ToggleHideSpan('hidden', field);
// }

function ToggleHideSpan(type, field) {		// this might belong in first_pass.js instead of here
    var spanField = "span_" + type + "_" + field;
    if ( document.getElementById(spanField).className == '' ) { 
        document.getElementById(spanField).className = 'displayNone'; }
    else { 
        document.getElementById(spanField).className = '';
        if (document.getElementById(field)) { document.getElementById(field).focus(); }
    }
}



