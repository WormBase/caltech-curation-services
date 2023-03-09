
window.onload = function() {					// by default hide all spans that contain expanded arrow 
    document.getElementById("containerFreeGeneAutoComplete").className = 'displayNone';
    document.getElementById("containerFreePhenontAutoComplete").className = 'displayNone';
} 

function onItemHighlight(oSelf , elItem) {		// if an item is highlighted from arrows or mouseover, populate obo
    var field = 'Phenont';
    var freeField = "containerFree" + field + "AutoComplete";
    var forcedField = "containerForced" + field + "AutoComplete";
    var freeInput = "free" + field + "Input";
    var forcedInput = "forced" + field + "Input";
    if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
        MatchFieldExpandTextarea('phenontObo', elItem[1].innerHTML);
//         document.getElementById("phenontObo").innerHTML = elItem[1].innerHTML;
    }
    else {
        MatchFieldExpandTextarea('phenontObo', elItem[1].innerHTML);
//         document.getElementById("phenontObo").innerHTML = elItem[1].innerHTML;
    }
}

function onItemSelect(oSelf , elItem , oData) {		// if an item is chose, populate obo and add to list
// from http://74.125.155.132/search?q=cache:1X4UPeX9TkAJ:extjs.com/forum/showthread.php%3Ft%3D1202+yui+itemselectevent&cd=5&hl=en&ct=clnk&gl=us
    var field = 'Phenont';
    var freeField = "containerFree" + field + "AutoComplete";
    var forcedField = "containerForced" + field + "AutoComplete";
    var freeInput = "free" + field + "Input";
    var forcedInput = "forced" + field + "Input";
    if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
        PopulatePhenontObo('Phenont', 'forced');
        PopulateSelectFromObo('Phenont');
    }
    else {
        PopulatePhenontObo('Phenont', 'free');
        PopulateSelectFromObo('Phenont');
    }
}


function ToggleFreeForced(field) {		
    var freeField = "containerFree" + field + "AutoComplete";
    var forcedField = "containerForced" + field + "AutoComplete";
    var freeInput = "free" + field + "Input";
    var forcedInput = "forced" + field + "Input";
    if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
        document.getElementById(freeInput).value = document.getElementById(forcedInput).value; 
        document.getElementById(freeField).className = ''; 			// show freeField
        document.getElementById(forcedField).className = 'displayNone'; }	// hide forcedField
    else { 
        document.getElementById(forcedInput).value = document.getElementById(freeInput).value; 
        document.getElementById(freeField).className = 'displayNone'; 
        document.getElementById(forcedField).className = ''; }
}



function PopulatePhenontObo(field, type) {		// based on free input, forced input, or selected (from select) value, display .obo data
    if (type == 'free') {
        var text = document.getElementById("free" + field + "Input").value;    // get data from textarea
        MatchFieldExpandTextarea('phenontObo', text);
    }
    else if (type == 'forced') {
        var text = document.getElementById("forced" + field + "Input").value;    // get data from textarea
        MatchFieldExpandTextarea('phenontObo', text);
    }
    else if (type == 'select') {
        var elSel = document.getElementById('select' + field);
        var text = elSel.options[elSel.selectedIndex].text;  
        MatchFieldExpandTextarea('phenontObo', text);
    }
}

function RemoveSelected(field) {			// remove selected values from the select field and resize
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

function PopulateSelectFromInput(field) {		// append to select field based on input value
    var text = '';
    var freeField = "containerFree" + field + "AutoComplete";
    var forcedField = "containerForced" + field + "AutoComplete";
    var freeInput = "free" + field + "Input";
    var forcedInput = "forced" + field + "Input";
    if ( document.getElementById(forcedField).className == '' ) {		// forcedField showing
        text = document.getElementById(forcedInput).value; 
//         document.getElementById("phenontObo").innerHTML = "here " + text; 
    }
    else {
        text = document.getElementById(freeInput).value; 
//         document.getElementById("phenontObo").innerHTML = "free " + text; 
    }
    var match = text.match(/name: (.*?)\n/); 		// capture the field from the name
    if (match != null) { 
        var result_text = match[1]; 				// if there's a match, grab the name
        match = text.match(/id: (.*?)\n/); 		// capture the field from the id
        if (match != null) { text = result_text + " (" + match[1] + ")"; }		// if there's a match, append the WBPhenotype:\d+
    }
    if ( (text != undefined) && (text != null) ) { 	// add to selected list only if there is a value
        PopulateSelect(field, text); }
}

function PopulateSelectFromObo(field) {			// append to select field based on obo value
//     var text = document.getElementById("phenontObo").innerHTML;	// from div
    var text = document.getElementById("phenontObo").value;		// from textarea
    var match = text.match(/name: (.*?)\n/); 	// capture the field from the tr id
    if (match != null) { 
        var result_text = match[1]; 				// if there's a match, grab the name
        match = text.match(/id: (.*?)\n/); 		// capture the field from the id
        if (match != null) { text = result_text + " (" + match[1] + ")"; }		// if there's a match, append the WBPhenotype:\d+
    }
    PopulateSelect(field, text);
}

function PopulateSelect(field, text) {			// append to select field based on passed text value
    var elSel = document.getElementById('select' + field);
    var elOptNew = document.createElement('option');
    elSel.size++;			// make the select bigger
    elOptNew.text = text;
    elOptNew.value = text;
    try { elSel.add(elOptNew, null); }	// standards compliant; doesn't work in IE
    catch(ex) { elSel.add(elOptNew); }	// IE only
}

// document.getElementById("freePersonContainer").innerHTML=url; // show stuff in person div

function MatchFieldExpandTextarea(field, text) {	// get_phenont_obo.cgi request to get .obo data from postgres
    if (text.length==0) {                               // if there's no data, make the div blank
        document.getElementById(field).innerHTML = "";
        return;
    }
    xmlHttp=GetXmlHttpObject();                         // make a new ajax xmlHttp object
    if (xmlHttp==null) {
        alert ("Your browser does not support AJAX!");
        return;
    }
    var words = text.split(/\s/);                       // get the words
    var url="http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/autocomplete/get_phenont_obo.cgi";
    text = text.replace(/\n/g, ' ');                    // newlines break the get call
//     url=url+"?type=" + type;                            // the table name
//     url=url+"&sid="+Math.random();                      // random to prevent browser using a cached page
    url=url+"?sid="+Math.random();                      // random to prevent browser using a cached page
    url=url+"&all="+text;                               // the text to send in
    xmlHttp.onreadystatechange = function() { stateChanged(field); }
      // need an anonymous function to pass a variable, otherwise it will get the return value of the function call (undefined)
    xmlHttp.open("GET",url,true);
    xmlHttp.send(null);
}

function GetXmlHttpObject() {           // create Ajax xmlHttp object
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
    if (xmlHttp.readyState==4) {        // if state changed to 4 (complete)
//         document.getElementById(field).innerHTML=xmlHttp.responseText; // set the div to the return value
        document.getElementById(field).value=xmlHttp.responseText; // set the div to the return value
    }
}


