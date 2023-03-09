// first independent .js file   2009 02 28


// this is tied to first_pass.cgi, if this .js file is made generic, moved this into a separate .js file for first_pass.cgi
// window.onload = function() {		// hide all textareas by default
//     for (i = 0; i < document.typeTwoForm.elements.length; i++) {
//         if (document.typeTwoForm.elements[i].type == "textarea") {
//             document.typeTwoForm.elements[i].className = 'displayNone';
// } } }


function ToggleHideTr(field) {		// this might belong in first_pass.js instead of here
    var trfield = "tr" + field;
    if ( document.getElementById("tr" + field).className == '' ) { 
        document.getElementById("tr" + field).className = 'displayNone'; }
    else { 
        document.getElementById("tr" + field).className = '';
        document.getElementById(field).focus(); }
}

function ToggleHideElement(field) {
    if ( document.getElementById(field).className == '' ) { document.getElementById(field).className = 'displayNone'; }
    else { document.getElementById(field).className = ''; }
}

function ShowElement(field) {		// unhide an element and focus on it
    document.getElementById(field).className = '';
    document.getElementById(field).focus(); 
}
function HideElement(field){		// hide an element
    document.getElementById(field).className = 'displayNone';
}

function CountLines(strtocount, cols) {	// count the lines in a textarea
    var hard_lines = 1;
    var last = 0;
    while ( true ) {
        last = strtocount.indexOf("\n", last+1);
        hard_lines ++;
        if ( last == -1 ) break;
    }
    var soft_lines = Math.round(strtocount.length / (cols-1));
    var hard = eval("hard_lines  " + unescape("%3e") + "soft_lines;");
    if ( hard ) soft_lines = hard_lines;
    return soft_lines;
}
function ExpandTextarea(field) {	// expand a textarea when someone types into it
    document.getElementById(field).rows = CountLines(document.getElementById(field).value, document.getElementById(field).cols) - 1;
}


// window.onload = function() {
// 	document.getElementById('txtArea').className = 'displayNone';
// }

// function hide(f,hideWhich){
// 	var toHide,toShow;
// 
// 	if(hideWhich == 1){
// 		toHide = 'txtToHide';
// 		toShow = 'txtArea';
// 	}else{
// 		toHide = 'txtArea';
// 		toShow = 'txtToHide';
// 	}
// 
// 	document.getElementById(toHide).className = 'displayNone';
// 	document.getElementById(toShow).className = '';
// 	document.getElementById(toShow).value = document.getElementById(toHide).value;
// 	if(hideWhich == 1){ document.getElementById(toShow).focus(); }
// }

