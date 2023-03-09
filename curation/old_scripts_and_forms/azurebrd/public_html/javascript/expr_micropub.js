// http://yui.github.io/yui2/docs/yui_2.7.0/docs/YAHOO.widget.AutoComplete.html
// http://yui.github.io/yui2/docs/yui_2.9.0_full/examples/autocomplete/ac_xhr_customrequest.html
// http://yui.github.io/yui2/docs/yui_2.9.0_full/examples/autocomplete/ac_itemselect.html

// javascript for form at ~azurebrd/public_html/cgi-bin/forms/expr_micropub.cgi
var cgiUrl = 'expr_micropub.cgi';

var myFields   = new Array();                     // the data fields, for some reason the elements get replaced by objects when datatable gets created
var fieldsData = new Object();

window.onscroll = function () {
    var termInfoBox = document.getElementById("term_info_box");
    var bodyTop     = window.pageYOffset;               // vertical offset of window
    if (bodyTop > 20) {                         // scrolled more than 20
        var setTop  = 95 - bodyTop;             // from default 95 minus the offset, move it
        if (setTop < 20) { setTop = 20; }       // move no less than 20px from the top
        termInfoBox.style.top = setTop + 'px';
      }
      else {
        termInfoBox.style.top = '95px';         // if window not scrolled much, set to default 95px
      }
};


YAHOO.util.Event.addListener(window, "load", function() {          // on load assign listeners
    populateMyFields();                                                                           // populate myFields array
    setAutocompleteListeners();                                    // add listener for gene, species, pmids
    setInputListeners();
    checkRadioState();
}); // YAHOO.util.Event.addListener(window, "load", function() 

function populateMyFields() {                                                           // populate myFields array based on input fields
  this.myFields = [ ];
  var toAlert = '';
  var inputs = document.getElementsByTagName("input");                                  // get all input fields
  for (var i = 0; i < inputs.length; i++ ) {                                            // loop through them
    if (inputs[i].className == "fields") {                                              // if the class is fields
      var field = inputs[i].value;
      this.myFields.push(field);                                                        // add to myFields array
      fieldsData[field] = new Object();                                                 // new hash for this field
      if (document.getElementById("data_" + field) ) {                                  // get data from html
        var arrData = document.getElementById("data_" + field).value.split(", ");       // split by comma into array
        for (var j in arrData) {                                                        // for each pair
          var match = arrData[j].match(/'(.*?)' : '(.*?)'/);                            // get the key and value
// if (!match) { alert('no match -- ' + arrData[j]); }
//           toAlert += " field " + field + " arrData[j] " + arrData[j] + " m1 " + match[1] + " m2 " + match[2] + "\n";
          toAlert += " field " + field + " m1 " + match[1] + " m2 " + match[2] + "\n";
          fieldsData[field][match[1]] = match[2]; } } }                                   // set into fieldsData[field]
  } // for (var i = 0; i < myFields.length; i++ )
//   alert(toAlert);
} // function populateMyFields()


// function fnFieldKeyup(e, objToPass) {
//   var tdTerminfoId    =     objToPass.tdTerminfoId   ;
//   var fieldElementId  =     objToPass.fieldElementId ;
// //   document.getElementById("term_info").innerHTML      = document.getElementById(fieldElementId).value;
// //   document.getElementById(tdTerminfoId).innerHTML     = fieldElementId;
// //   document.getElementById(tdTerminfoId).innerHTML     = document.getElementById(fieldElementId).value;
// //   document.getElementById(tdTerminfoId).style.display = "";
// }
// 
// function fnFieldBlur(e, objToPass) {
//   var tdTerminfoId    =     objToPass.tdTerminfoId   ;
// //   var fieldElementId  =     objToPass.fieldElementId ;
// //   document.getElementById(tdTerminfoId).style.display = "none";
// }

function onAutocompleteItemHighlight(sType, aArgs) {
  var myAC  = aArgs[0]; // reference back to the AC instance 
  var elLI  = aArgs[1]; // reference to the selected LI element 
  if (elLI.innerHTML.match(/\( (.*?) \)/) ) {						// match wb id in span and parenthesis
    match       = myAC._sName.match(/input_(\d+)_(.*)/);
    var count   = match[1]; count = parseInt(count);
    var field   = match[2];
    var group   = fieldsData[field]["group"];
    var elMatch = elLI.innerHTML.match(/\>\( (.*?) \)\</); 
    var wbid    = elMatch[1];
    asyncTermInfo(group, field, wbid);
  }
//   document.getElementById("term_info").innerHTML      = elLI.innerHTML;
// There is no aData for itemMouseOverEvent nor itemArrowFromEvent
// http://yui.github.io/yui2/docs/yui_2.7.0/docs/YAHOO.widget.AutoComplete.html
//   var oData = aArgs[2]; // object literal of selected item's result data 
//   if (oData === undefined) { document.getElementById("term_info").innerHTML      = document.getElementById("term_info").innerHTML + ' NOW undefined';   }
//   if (oData !== undefined) { document.getElementById("term_info").innerHTML      = oData[1]; }
} // function onAutocompleteItemHighlight(sType, aArgs)

function onAutocompleteItemSelect(sType, aArgs) {
  var myAC  = aArgs[0]; // reference back to the AC instance 
  var elLI  = aArgs[1]; // reference to the selected LI element 
  var oData = aArgs[2]; // object literal of selected item's result data 
//   var blah  = 'myAC ' + myAC + '<br/>elLI ' + elLI + '<br/>oData ' + oData[1];
  // update hidden form field with the selected item's ID 
//   document.getElementById("term_info").innerHTML      = oData[1]; 
  var match        = myAC._sName.match(/input_(\d+)_(.*)/);
  var count        = match[1]; count = parseInt(count);
  var field        = match[2];
  var termid_field = 'termid_' + count + '_' + field;
  var input_field  = 'input_'  + count + '_' + field;
  var group        = fieldsData[field]["group"];
  var groupAmount  = fieldsData[field]["multi"];
//   document.getElementById("term_info").innerHTML     = termid_field; 
  document.getElementById(termid_field).value           = oData[1]; 
  document.getElementById(input_field).value            = oData[2]; 
  if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
    var countPlusOne   = count + 1;
    var trGroupElement = 'group_' + countPlusOne + '_' + group;
    document.getElementById(trGroupElement).style.display = ""; }
  asyncTermInfo(group, field, oData[1]);
} // function onAutocompleteItemSelect(sType, aArgs)


function asyncTermInfo(group, field, value) {
  var callbacks = {
      success : function (o) {                                  // Successful XHR response handler
          if (o.responseText !== undefined) { document.getElementById('term_info').innerHTML = o.responseText + "<br/> "; } }, };
  value = convertDisplayToUrlFormat(value);                     // convert <newValue> to URL format by escaping characters
  var sUrl = cgiUrl + "?action=asyncTermInfo&field="+field+"&termid="+value+"&group="+group;
  document.getElementById('term_info_box').style.display = '';  // show the term info box again
  YAHOO.util.Connect.asyncRequest('GET', sUrl, callbacks);      // Make the call to the server for term info data
} // function function asyncTermInfo(field, value)

function setInputListeners() {
  var toAlert = '';
  for (var i = 0; i < myFields.length; i++ ) {                  // for each field type
    var field  = myFields[i];
    toAlert += " " + field + "\n";
    var amount       = fieldsData[field]["multi"];
    for (var j = 1; j <= amount; j++ ) {				// for each specific number of that field
      if ( fieldsData[myFields[i]]["type"] === "text" ) {		// if it's a text field
        oElement = document.getElementById("input_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener(oElement, "keyup", function() {	// when typing in a text input element unhide next multi field
          var match        = this.id.match(/input_(\d+)_(.*)/); 
          var count        = match[1]; count = parseInt(count);
          var field        = match[2];
          var group        = fieldsData[field]["group"];
          var groupAmount  = fieldsData[field]["multi"];
          if ( document.getElementById("input_" + count + '_' + field).value !== '' ) {
            if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
              var countPlusOne   = count + 1;
              var trGroupElement = 'group_' + countPlusOne + '_' + group;
              document.getElementById(trGroupElement).style.display = ""; } } 
        });
      } // if ( fieldsData[myFields[i]]["type"] === "text" )

      if ( fieldsData[myFields[i]]["type"] === "bigtext" ) {                                 // if it's a bigtext field
        oElement = document.getElementById("input_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener(oElement, "focus", function() {			// when clicking a bigtext input element, hide input, load data into textarea, show textarea
            var match = this.id.match(/input_(.*)/); var count_field = match[1];	// get the count_field from the id
            document.getElementById("input_" + count_field).style.display = "none";
            document.getElementById("textarea_bigtext_" + count_field).style.display = "";
            document.getElementById("textarea_bigtext_" + count_field).value = document.getElementById("input_" + count_field).value;
            document.getElementById("textarea_bigtext_" + count_field).focus();
        });
        var bigtextElement = document.getElementById("textarea_bigtext_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener( bigtextElement, "blur", function() {		// when blurring a bigtext textarea element, hide textarea, load data into input, show input
            var match = this.id.match(/textarea_bigtext_(.*)/); var count_field = match[1];	// get the count_field from the id
            document.getElementById("textarea_bigtext_" + count_field).style.display = "none";
            document.getElementById("input_" + count_field).style.display = "";
            document.getElementById("input_" + count_field).value = document.getElementById("textarea_bigtext_" + count_field).value;       // switch value from textarea to input, regardless of whether noteditable or not
        }); 
        YAHOO.util.Event.addListener(bigtextElement, "keyup", function() {		// when typing in a bigtext textarea element unhide next multi field
          var match        = this.id.match(/textarea_bigtext_(\d+)_(.*)/); 
          var count        = match[1]; count = parseInt(count);
          var field        = match[2];
          var group        = fieldsData[field]["group"];
          var groupAmount  = fieldsData[field]["multi"];
          if ( document.getElementById("textarea_bigtext_" + count + '_' + field).value !== '' ) {
            if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
              var countPlusOne   = count + 1;
              var trGroupElement = 'group_' + countPlusOne + '_' + group;
              document.getElementById(trGroupElement).style.display = ""; } } 
        }); 
      } // if ( fieldsData[myFields[i]]["type"] === "bigtext" )

      if ( fieldsData[myFields[i]]["type"] === "radio" ) {		// if it's a radio field
        var arrRadioValues = fieldsData[myFields[i]]["radio"].split(" ");
        for (var k = 0; k < arrRadioValues.length; k++ ) {				// for each specific number of that field
          var radioValue = arrRadioValues[k];   
          oElement = document.getElementById("radio_" + j + '_' + myFields[i] + '_' + radioValue);
          YAHOO.util.Event.addListener(oElement, "click", checkRadioStateListener);
//           YAHOO.util.Event.addListener(oElement, "click", function() {	// when typing in a text input element unhide next multi field
//             var match        = this.id.match(/radio_(\d+)_(.*)_(.*)/); 
//             var count        = match[1]; count = parseInt(count);
//             var field        = match[2];
//             var radioValue   = match[3];
//             var classHide    = 'mandatory_' + field;
//             var classShow    = 'mandatory_' + field + '_' + radioValue;
//             var arrTdsHide   = YAHOO.util.Dom.getElementsByClassName(classHide, 'td');
//             for (t = 0; t < arrTdsHide.length; t++) { arrTdsHide[t].innerHTML = ''; }
//             var arrTdsShow   = YAHOO.util.Dom.getElementsByClassName(classShow, 'td');
//             for (t = 0; t < arrTdsShow.length; t++) { arrTdsShow[t].innerHTML = '<span style="color:red">*</span>'; }
// 
// //             var arrTrsHide   = YAHOO.util.Dom.getElementsByClassName(classHide, 'tr');
// //             for (t = 0; t < arrTrsHide.length; t++) { 
// // // alert('hide ' + arrTrsHide[t].id);
// // arrTrsHide[t].style.display = "none"; 
// // }
// //             var arrTrsShow   = YAHOO.util.Dom.getElementsByClassName(classShow, 'tr');
// //             for (t = 0; t < arrTrsShow.length; t++) { 
// // // alert('show ' + arrTrsShow[t].id);
// // arrTrsShow[t].style.display = ""; 
// // }
// //   alert('field ' + field + ' radioValue ' + radioValue + ' E');
//           });

        } // for (var k = 0; k < arrRadioValues.length; k++ )
      } // if ( fieldsData[myFields[i]]["type"] === "radio" )

    } // for (var j = 1; j <= amount; j++ )
  } // for (var i = 0; i < myFields.length; i++ )
} // function setInputListeners()

function checkRadioStateListener(e) { checkRadioState(); }
function checkRadioState() {					// check all radio buttons and set other fields/values accordingly
  var toAlert = '';
  for (var i = 0; i < myFields.length; i++ ) {                  // for each field type
    var field  = myFields[i];
    toAlert += " " + field + "\n";
    var amount       = fieldsData[field]["multi"];
    for (var j = 1; j <= amount; j++ ) {				// for each specific number of that field
      if ( fieldsData[myFields[i]]["type"] === "radio" ) {		// if it's a radio field
        var arrRadioValues = fieldsData[myFields[i]]["radio"].split(" ");
        for (var k = 0; k < arrRadioValues.length; k++ ) {				// for each specific number of that field
          var radioValue = arrRadioValues[k];   
          oElement = document.getElementById("radio_" + j + '_' + myFields[i] + '_' + radioValue);
          if (oElement.checked) {
            var classHide    = 'mandatory_' + field;
            var classShow    = 'mandatory_' + field + '_' + radioValue;
            var arrTdsHide   = YAHOO.util.Dom.getElementsByClassName(classHide, 'td');
            for (t = 0; t < arrTdsHide.length; t++) { arrTdsHide[t].innerHTML = ''; }
            var arrTdsShow   = YAHOO.util.Dom.getElementsByClassName(classShow, 'td');
            for (t = 0; t < arrTdsShow.length; t++) { arrTdsShow[t].innerHTML = '<span style="color:red">*</span>'; }
            var classDisable     = 'field_' + field;
            var classEnable      = 'field_' + field + '_' + radioValue;
            var arrTdsDisable    = YAHOO.util.Dom.getElementsByClassName(classDisable, 'td');
            for (t = 0; t < arrTdsDisable.length; t++) {    arrTdsDisable[t].style       = 'color: grey';  }
            var arrTdsEnable     = YAHOO.util.Dom.getElementsByClassName(classEnable, 'td');
            for (t = 0; t < arrTdsEnable.length; t++) {     arrTdsEnable[t].style        = 'color: black'; }
            var arrInputsDisable = YAHOO.util.Dom.getElementsByClassName(classDisable, 'input');
            for (t = 0; t < arrInputsDisable.length; t++) { arrInputsDisable[t].disabled = true;           }
            var arrInputsEnable  = YAHOO.util.Dom.getElementsByClassName(classEnable, 'input');
            for (t = 0; t < arrInputsEnable.length; t++) {  arrInputsEnable[t].disabled  = false;          }
          } // if (oElement.checked)
        } // for (var k = 0; k < arrRadioValues.length; k++ )
      } // if ( fieldsData[myFields[i]]["type"] === "radio" )
    } // for (var j = 1; j <= amount; j++ )
  } // for (var i = 0; i < myFields.length; i++ )
} // function checkRadioState()

function setAutocompleteListeners() {
  var toAlert = '';
  for (var i = 0; i < myFields.length; i++ ) {                  // for each field type
    var field  = myFields[i];
    toAlert += " " + field + "\n";
    var amount = fieldsData[field]["multi"];
    var group  = fieldsData[field]["group"];
    for (var j = 1; j <= amount; j++ ) {				// for each specific number of that field
//       var tdTerminfoId   = j + "_terminfo_" + group;
      var fieldElementId = "input_" + j + "_" + field;
//       document.getElementById(fieldElementId).value = fieldElementId;
//       document.getElementById(fieldElementId).value = tdTerminfoId;
      toAlert += " " + fieldElementId + " j " + j + " amount " + amount;
//       var objToPass = new Object();
// //       objToPass.tdTerminfoId   = tdTerminfoId;
//       objToPass.fieldElementId = fieldElementId;
// //       YAHOO.util.Event.addListener(fieldElementId, "keyup", fnFieldKeyup, objToPass);
// //       YAHOO.util.Event.addListener(fieldElementId, "blur",  fnFieldBlur,  objToPass);

      if ( fieldsData[myFields[i]]["type"] === "ontology" ) {                                     // ontology values load term info when input is field is clicked
        settingAutocompleteListeners = function() {
          var sUrl = cgiUrl + "?action=autocompleteXHR&field=" + field + "&group=" + group + "&";   // ajax calls need curator and datatype
          var oDS = new YAHOO.util.XHRDataSource(sUrl);          // Use an XHRDataSource
//           oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT; // Set the responseType
          oDS.responseSchema = {                                  // Define the schema of the delimited results
              recordDelim: "\n",
              fieldDelim: "\t"
          };
          oDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON;  // Set the responseType
          oDS.responseSchema = { 
              resultsList : "results", 
              fields : ["eltext", "id", "name"] 
          }; 
          oDS.maxCacheEntries = 5;                               // Enable caching

          var forcedOrFree              = "forced";
          var inputElement              = document.getElementById("input_" + j + '_' + field);
          var containerElement          = document.getElementById(forcedOrFree + j + field + "Container");
          var forcedOAC                 = new YAHOO.widget.AutoComplete(inputElement, containerElement, oDS);
          forcedOAC.queryQuestionMark   = false;                   // don't add a ? to the sUrl query since it's been built with some other values
          forcedOAC.maxResultsDisplayed = 500;
          forcedOAC.forceSelection      = true;
          forcedOAC.itemSelectEvent.subscribe(onAutocompleteItemSelect);
          forcedOAC.selectionEnforceEvent.subscribe(onAutocompleteSelectionEnforce);
          forcedOAC.itemArrowToEvent.subscribe(onAutocompleteItemHighlight);
          forcedOAC.itemMouseOverEvent.subscribe(onAutocompleteItemHighlight);
          return {
              oDS: oDS,
              forcedOAC: forcedOAC
          }
        }();
//         YAHOO.util.Event.addListener(fieldElementId, "click", function() {                              // when clicking an ontology input element, async term info
//           var match = this.id.match(/input_(.*)/); var field = match[1];                          // get the field from the id
//           if (this.value) {                                                                       // only if there's a value try to get term info
//             asyncTermInfo(field, this.value); } }); 
      } // if ( fieldsData[myFields[i]]["type"] === "ontology" )

    } // for (var j = 1; j <= amount; j++ )
  } // for (var i = 0; i < myFields.length; i++ )
//   alert(toAlert);
} // function setAutocompleteListeners()

function onAutocompleteSelectionEnforce(oSelf, sClearedValue) {         // pre-loaded data is not from AC and gets forced out, reload it if unchanged
  var myAC         = sClearedValue[0];          // reference back to the AC instance
  var previousText = sClearedValue[1];          // text that got cleared
  var match        = myAC._sName.match(/input_(\d+)_(.*)/);
  var count        = match[1]; count = parseInt(count);
  var field        = match[2];
  if (document.getElementById('loaded_' + count + '_' + field).value ) {                        // the preloaded value
    if (document.getElementById('loaded_' + count + '_' + field).value === previousText) {      // if preloaded value same as cleared text
      document.getElementById('input_' + count + '_' + field).value = previousText; } }         // put back in input field
//   alert("count " + count + " field " + field + " myAC " + myAC + " pT " + previousText + " oSelf " + oSelf + " cleared " + sClearedValue + " end");
} // function onAutocompleteSelectionEnforce(oSelf, sClearedValue)

function convertDisplayToUrlFormat(value) {
    if (value !== undefined) {                                                  // if there is a display value replace stuff
        if (value.match(/\n/)) { value = value.replace(/\n/g, " "); }           // replace linebreaks with <space>
        if (value.match(/\+/)) { value = value.replace(/\+/g, "%2B"); }         // replace + with escaped +
        if (value.match(/\#/)) { value = value.replace(/\#/g, "%23"); }         // replace # with escaped #
    }
    return value;                                                               // return value in format for URL
} // function convertDisplayToUrlFormat(value)



