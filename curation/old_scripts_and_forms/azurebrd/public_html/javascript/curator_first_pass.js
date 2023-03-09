// changed for curator_first_pass.cgi from first_pass.cgi  2009 03 04
//
// changed ToggleHideTd, which hid the whole cell into ToggleHideSpan, which allows showing of the cell 
// and toggling of an image from an arrow right (expanded) to an arrow down (collapsed).  By default 
// hide all the arrow downs (since the cell is not collapsed by default)   2009 03 05
//
// added MergeIntoCurator(field, type) to take a field and type, and merge its data into the curator 
// textarea, if it's not already in there.  2009 03 06
//
// resize textareas based on data in case someone queried a paper with data.  2009 03 14
//
// fixed a lot of regexp stuff for MergeIntoCurator.
// grey out and erase the span on textpresso and author data if there is no data.  2009 03 15
//
// added ToggleHideRowSpans(field) for curators to toggle hiding of spans by field 
// onload run through all trs, get the field names from the id, for those with neither author
// nor textpresso data, ToggleHideRowSpans   2009 03 17
//
// added ajax call to 
// http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/ajax/gethint.cgi
// to get lab or wbgene based off of data typed in a textarea matching a gene, locus, or sequence.
// 2009 03 19
//
// added validation of curator and paper when clicking any submit button
// created GetPgTables and GetPgCats to get arrays of pgtable fields and categories
// rewrote onload to use the pgtables array
// rewrote ToggleHideSpan(field) into ToggleHideColSpans(colType), with more explicitly name for
// the spans, and pgtables and pgcats, allows hiding of spans if either the row or the column is
// hidden.   2009 03 21
//
// flipped all the arrows  2009 03 26



window.onload = function() {					// by default hide all spans that contain expanded arrow 
    var toAlert = '';
    var patt1 = new RegExp("^span_.*_arrow_right");			// spans that contain expanded arrow should be hidden
    var activeForm = document.getElementById("typeOneForm");		// select elements only from the active form
    var eleTableSpans = activeForm.getElementsByTagName("span");	// get all spans
    for (var i = 0; i < eleTableSpans.length; i++)  {  			// loop through trs
        if (patt1.test( eleTableSpans[i].id ) ) {			// if they match regexp
             eleTableSpans[i].className = 'displayNone';		// set style to displayNone
        }
    }
    var patt2 = new RegExp("^curator_");             // span that have textareas have ids beginning with "curator_"
    var eleTableTextareas = document.getElementsByTagName("textarea");	// get all textareas
    for (var i = 0; i < eleTableTextareas.length; i++)  {               // loop through textareas
        if (patt2.test( eleTableTextareas[i].id ) ) {                   // if they match regexp
             if (eleTableTextareas[i].value) { ExpandTextarea(eleTableTextareas[i].id); }	// resize them to data
        }
    }
    var patt3 = new RegExp("^hidden_textpresso");	// input that have ids beginning with "hidden_textpresso"
    var patt4 = new RegExp("^hidden_author");		// input that have ids beginning with "hidden_author"
    var patt5 = new RegExp("^hidden_email");		// input that have ids beginning with "hidden_email"
    var eleTableInputs = document.getElementsByTagName("input");   	// get all input fields
    for (var i = 0; i < eleTableInputs.length; i++)  {                  // loop through inputs
        if ( ( eleTableInputs[i].type == 'hidden' ) && 			// if it is a hidden input field
             ( (patt5.test( eleTableInputs[i].id ) ) || 
               (patt4.test( eleTableInputs[i].id ) ) || 
               (patt3.test( eleTableInputs[i].id ) ) ) &&		// matches either pattern
             (! eleTableInputs[i].value) ) { 				// and does not have a value
                    eleTableInputs[i].parentNode.style.backgroundColor = '#F0F0F0'; 	// set color to grey
 	              // erase the first element of the parentNode (the span_type_data)
                    eleTableInputs[i].parentNode.childNodes.item(0).innerHTML = '';
        } 
    }
    var pgtables = GetPgTables();
    for (var i = 0; i < pgtables.length; i++) {				// for all the pgtable fields
        field = pgtables[i];
        if ( !( document.getElementById("hidden_textpresso_" + field).value ) &&	// if neither textpresso 
             !( document.getElementById("hidden_author_" + field).value ) && 		// nor author have a value
             !( document.getElementById("curator_" + field).innerHTML ) ) {		// nor curator have a value
            ToggleHideRowSpans(field);					// hide the spans in that row
        }
        if ( document.getElementById("curator_" + field).innerHTML ) {			// curator has data
            document.getElementById("curator_checked_" + field).checked = false; 	// turn of email checkbox
        }
    }
//     alert(toAlert);
}

function GetPgTables() {					// get all the postgres tables
    var eleTableRows = document.getElementsByTagName("tr");   	// get all table rows
    var pgtables = new Array();
    for (var i = 0; i < eleTableRows.length; i++)  {		// loop through trs
        if (! eleTableRows[i].id ) { continue; }		// skip tr without curator fields
        if (! eleTableRows[i].id.match(/tr_field_/) ) { continue; }	// get the trs that are fields
        var match = eleTableRows[i].id.match(/tr_field_(.*)$/);	// capture the field from the tr id
        pgtables.push(match[1]);				// the first captured element is the second array return
    }
    return pgtables;
}

function GetPgCats() {						// get all the categories
    var eleTableRows = document.getElementsByTagName("tr");   	// get all table rows
    var pgcats = new Array();
    for (var i = 0; i < eleTableRows.length; i++)  {		// loop through trs
        if (! eleTableRows[i].id.match(/tr_cat_/) ) { continue; }	// get the trs that are cats
        var match = eleTableRows[i].id.match(/tr_cat_(.*)$/);	// capture the cat from the tr id
        pgcats.push(match[1]);					// the first captured element is the second array return
    }
    return pgcats;
}

function ValidateCuratorPaper() {				// onSubmit check there is a curator and paper
    if ( ValidateRequiredInput("html_value_paper", "Paper required") == false )
        { document.getElementById("html_value_paper").focus(); return false; }
    if ( ValidateRequiredSelect("html_value_curator", "Curator required") == false )
        { document.getElementById("html_value_curator").focus(); return false; }
}
function ValidateRequiredSelect(field, alerttxt) {		// check value in select
    var fieldSelect = document.getElementById(field);
    var value = fieldSelect.options[fieldSelect.selectedIndex].value;
    if (value == null || value == "") { alert(alerttxt); return false; }
    else { return true; }
}
function ValidateRequiredInput(field, alerttxt) {		// check value in input
    var value = document.getElementById(field).value;
    if (value == null || value == "") { alert(alerttxt); return false; }
    else { return true; }
}


function MergeIntoCurator(field, type) {			// take data from a field and type and merge into that field's curator textarea
//     alert( document.getElementById("hidden_" + type + "_" + field).value );
      // escape [ for regexp
    var mergingTestValue = document.getElementById("hidden_" + type + "_" + field).value.replace(/\[/g, '\\[');
    mergingTestValue = mergingTestValue.replace(/\(/g, '\\(');	// this is for the regex to test, need to escape special chars
    mergingTestValue = mergingTestValue.replace(/\)/g, '\\)');
    mergingTestValue = mergingTestValue.replace(/\r\n/g, '\n'); // data to test should have normal newlines, not \r\n
      // data to merge should have normal newlines, not \r\n
    var mergingValue = document.getElementById("hidden_" + type + "_" + field).value.replace(/\r\n/g, '\n');
    var patt1 = new RegExp( mergingTestValue, "m" );			// pattern is data in field to merge
      // if data in curator field does not match data in field to merge
    if (! (patt1.test( document.getElementById("curator_" + field).value ) ) ) {
        if ( document.getElementById("curator_" + field).value ) { 	// add a newline only if there is already curator data
            document.getElementById("curator_" + field).value += "\n"; }
	  // append data
        document.getElementById("curator_" + field).value += mergingValue;
        ExpandTextarea("curator_" + field);			// resize textarea box
    }
}



function ToggleHideRowSpans(field) {		// for a given field take the textpresso, author, curator spans and toggle their hide status
    var Tds = document.getElementById("td_description_data_" + field).parentNode.cells;
    var hide = false;				// if hide is true, clicking hides the fields
    if (document.getElementById("span_description_" + field + "_arrow_right").className == 'displayNone') { hide = true; }
    for (var i = 1; i < Tds.length; i++) {	// skip description, toggle textpresso author and curator
        if (hide) { Tds[i].childNodes[0].className = 'displayNone'; }
        else {      Tds[i].childNodes[0].className = ''; }
    }
   if (hide) {					// hiding data, show arrow right, hide arrow down
       document.getElementById("span_description_" + field + "_arrow_right" ).className = '' ;
       document.getElementById("span_description_" + field + "_arrow_down").className = 'displayNone'; }
   else {					// showing data, hide arrow right, show arrow down
       document.getElementById("span_description_" + field + "_arrow_right" ).className = 'displayNone'; 
       document.getElementById("span_description_" + field + "_arrow_down").className = ''; }
}


function ToggleHideColSpans(colType) {		// the fields are : textpresso, author, curator, email
    var toAlert = '';
    var colHide = false;
    if (document.getElementById("span_" + colType + "_spe_arrow_right").className == 'displayNone') { colHide = true; }
    var pgtables = GetPgTables();
    for (var i = 0; i < pgtables.length; i++) {
        field = pgtables[i];
        var hide = colHide
        if (document.getElementById("span_description_" + field + "_arrow_down").className == 'displayNone') { hide = true; }
          // hiding data, set style to displayNone
        if (hide) { document.getElementById("span_" + colType + "_" + field + "_data").className = 'displayNone'; }	
            else { document.getElementById("span_" + colType + "_" + field + "_data").className = ''; }	// show it
    }
    var pgcats = GetPgCats();
    for (var i = 0; i < pgcats.length; i++) {
        cat = pgcats[i];
        if (colHide) { 					// hiding data, show arrow right, hide arrow down
            document.getElementById("span_" + colType + "_" + cat + "_arrow_down").className = 'displayNone'; 	// hide down arrow
            document.getElementById("span_" + colType + "_" + cat + "_arrow_right").className = ''; }		// show right arrow
        else { 						// if showing
            document.getElementById("span_" + colType + "_" + cat + "_arrow_down").className = '';		// show down arrow
            document.getElementById("span_" + colType + "_" + cat + "_arrow_right").className = 'displayNone'; }	// hide right arrow
    }
//     var patt1 = new RegExp("^span_" + field);	// span that have those fields have ids beginning with "span_field"
//     var activeForm = document.getElementById("typeOneForm");	// select elements only from the active form
//     var eleTableRows = activeForm.getElementsByTagName("span");	// get all spans in the activeForm
//     for (var i = 0; i < eleTableRows.length; i++)  {  		// loop through spans
//         if (patt1.test( eleTableRows[i].id ) ) {		// if they match regexp
//              if (eleTableRows[i].className == 'displayNone') { 	// if hidden
//                  eleTableRows[i].className = ''; }		// show it
//              else { 						// if showing
//                  eleTableRows[i].className = 'displayNone'; }	// set style to displayNone
//         }
//     }
//     if (hide) { 					// hiding data, show arrow right, hide arrow down
//         document.getElementById("span_" + field + "_arrow_right").className == ''; 
//     }
    var colsHidden = 1; var minCols = 40;
    if (document.getElementById("span_curator_spe_arrow_down").className     == 'displayNone') { colsHidden++; }
    if (document.getElementById("span_author_spe_arrow_down").className      == 'displayNone') { colsHidden++; }
    if (document.getElementById("span_textpresso_spe_arrow_down").className  == 'displayNone') { colsHidden++; }
//     if (document.getElementById("span_email_spe_arrow_down").className       == 'displayNone') { colsHidden++; }
    if (document.getElementById("span_description_spe_arrow_down").className == 'displayNone') { colsHidden++; }
    var eleTableRows = document.getElementsByTagName("textarea");	// get all textareas
    for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through textareas
        eleTableRows[i].cols = minCols * colsHidden;			// set cols / width
    }
//     alert(toAlert);
}




function GetXmlHttpObject() {		// create Ajax xmlHttp object
    var xmlHttp=null;
    try {               // Firefox, Opera 8.0+, Safari
       xmlHttp=new XMLHttpRequest();
    }
    catch (e) {         // Internet Explorer
        try { xmlHttp=new ActiveXObject("Msxml2.XMLHTTP"); }
        catch (e) { xmlHttp=new ActiveXObject("Microsoft.XMLHTTP"); }
    }
    return xmlHttp;
}

function stateChanged(field) {
    if (xmlHttp.readyState==4) {	// if state changed to 4 (complete)
        document.getElementById("div_" + field).innerHTML=xmlHttp.responseText;	// set the div to the return value
    }
}

function MatchFieldExpandTextarea(field, type) {
    ExpandTextarea(field);				// resize textarea box
    var text = document.getElementById(field).value;	// get data from textarea
    if (text.length==0) {				// if there's no data, make the div blank
        document.getElementById("div_" + field).innerHTML = "";
        return;
    }
    xmlHttp=GetXmlHttpObject();				// make a new ajax xmlHttp object
    if (xmlHttp==null) {
        alert ("Your browser does not support AJAX!");
        return;
    }
    var words = text.split(/\s/);			// get the words
    var url="http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/ajax/gethint.cgi";
    text = text.replace(/\n/g, ' ');			// newlines break the get call
    url=url+"?type=" + type;				// the table name
    url=url+"&sid="+Math.random();			// random to prevent browser using a cached page
    url=url+"&all="+text;				// the text to send in
    xmlHttp.onreadystatechange = function() { stateChanged(field); }	
      // need an anonymous function to pass a variable, otherwise it will get the return value of the function call (undefined)
    xmlHttp.open("GET",url,true);
    xmlHttp.send(null);
}




// function ToggleHideTd(field) {		// the fields are : textpresso, author, curator
//     var patt1 = new RegExp("^td_" + field);	// td that have those fields have ids beginning with "td_field"
//     var activeForm = document.getElementById("typeOneForm");	// select elements only from the active form
//     var eleTableRows = activeForm.getElementsByTagName("td");	// get all tds in the activeForm
//     for (var i = 0; i < eleTableRows.length; i++)  {  		// loop through tds
//         if (patt1.test( eleTableRows[i].id ) ) {		// if they match regexp
//              if (eleTableRows[i].className == 'displayNone') { 	// if hidden
//                  eleTableRows[i].className = ''; }		// show it
//              else { 						// if showing
//                  eleTableRows[i].className = 'displayNone'; }	// set style to displayNone
//         }
//     }
// //     var curCols = document.getElementById("curator_genesymbol").cols;
// //     alert("curCols : "+curCols);
//     var minCols = 40;
//     var colsHidden = 1;
//     if (document.getElementById("td_curator_top").className    == 'displayNone') { colsHidden++; }
//     if (document.getElementById("td_author_top").className     == 'displayNone') { colsHidden++; }
//     if (document.getElementById("td_textpresso_top").className == 'displayNone') { colsHidden++; }
// //     alert("colsHidden : " + colsHidden + ", minCols " + minCols);
// //     document.getElementById("curator_genesymbol").cols = minCols * colsHidden;
//     var eleTableRows = document.getElementsByTagName("textarea");	// get all textareas
//     for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through textareas
//         eleTableRows[i].cols = minCols * colsHidden;			// set cols / width
//     }
// }

// function ToggleHideTr(field) {		// this might belong in first_pass.js instead of here
//     var trfield = "tr" + field;
//     if ( document.getElementById("tr" + field).className == '' ) { 
//         document.getElementById("tr" + field).className = 'displayNone'; }
//     else { 
//         document.getElementById("tr" + field).className = '';
//         document.getElementById(field).focus(); }
// }


// window.onload = function() {		// hide all "tr"s with textareas by default
//     var patt1 = new RegExp("^tr");	// tr that have textareas have ids beginning with "tr"
//     var eleTableRows = document.typeTwoForm.getElementsByTagName("tr");	// get all trs
//     for (var i = 0; i < eleTableRows.length; i++)  {  			// loop through trs
//         if (patt1.test( eleTableRows[i].id ) ) {			// if they match regexp
//              if ( eleTableRows[i].id == "trcomment" ) { continue; }	// don't hide comment
//              eleTableRows[i].className = 'displayNone';			// set style to displayNone
//         }
//     }
// }


// window.onload = function() {		// hide all textareas by default
//     var data = '';
//     for (i = 0; i < document.typeTwoForm.elements.length; i++) {
// //         if (document.typeTwoForm.elements[i].type == "textarea") { continue; }
// //         data += " " + i + " " + document.typeTwoForm.elements[i].type + " " + document.typeTwoForm.elements[i].id  + "\n";
//         if ( (document.typeTwoForm.elements[i].type == "tr") &&  
//              (document.typeTwoForm.elements[i].id == "trgenesymbol") )  {
//              var row = document.typeTwoForm.elements[i];
//              row.style.display = 'none';
// //              alert("hiding");
// //             document.typeTwoForm.elements[i].className = 'displayNone';
// } }
// // alert (data);
//  }

