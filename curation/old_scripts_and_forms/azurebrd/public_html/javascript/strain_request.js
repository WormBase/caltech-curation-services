// http://yui.github.io/yui2/docs/yui_2.7.0/docs/YAHOO.widget.AutoComplete.html
// http://yui.github.io/yui2/docs/yui_2.9.0_full/examples/autocomplete/ac_xhr_customrequest.html
// http://yui.github.io/yui2/docs/yui_2.9.0_full/examples/autocomplete/ac_itemselect.html

// adapted for strain_request.cgi  a lot of this code might be unnecessary  2023 02 21


// javascript for form at ~azurebrd/public_html/cgi-bin/forms/strain_request.cgi
var cgiUrl = 'strain_request.cgi';

var myFields   = new Array();                     // the data fields, for some reason the elements get replaced by objects when datatable gets created
var fieldsData = new Object();

window.onscroll = function () {
//   delay(function(){
    var termInfoBox = document.getElementById("term_info_box");
    var bodyTop     = window.pageYOffset;		// vertical offset of window
    if (bodyTop > 20) { 			// scrolled more than 20
        var setTop  = 95 - bodyTop;		// from default 95 minus the offset, move it
        if (setTop < 20) { setTop = 20; }	// move no less than 20px from the top
        termInfoBox.style.top = setTop + 'px';
      }
      else { 
        termInfoBox.style.top = '95px';		// if window not scrolled much, set to default 95px
      }
//   }, 5 );
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
    if (inputs[i].className === "fields") {                                              // if the class is fields
      var field = inputs[i].value;
      this.myFields.push(field);                                                        // add to myFields array
      fieldsData[field] = new Object();                                                 // new hash for this field
      if (document.getElementById("data_" + field) ) {                                  // get data from html
        var arrData = document.getElementById("data_" + field).value.split(" -DIVIDER- ");       // split by comma into array
        for (var j in arrData) {                                                        // for each pair
          var match = arrData[j].match(/'(.*?)' : '(.*?)'/);                            // get the key and value
// if (!match) { alert('no match -- ' + arrData[j]); }
          var tag = match[1]; var tagValue = match[2];
//           toAlert += 'field ' + field + ' tag ' + tag + ' tagValue ' + tagValue + ' end\n';
          fieldsData[field][tag] = tagValue;                                            // set into fieldsData[field]
          var tagValueText = tagValue.match(/\[ (.*?) \]/);
          if (tagValueText !== null) {
            var groupArray = tagValueText[1].split(" ");                                            // set into fieldsData[field]
            fieldsData[field][tag] = groupArray;
//             for (var x in fieldsData[field][tag]) { toAlert += 'groupArray has ' + fieldsData[field][tag][x] + ' end\n'; }
          }
    } } }
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
//     var group   = fieldsData[field]["group"];
    var elMatch = elLI.innerHTML.match(/\>\( (.*?) \)\</); 
    var wbid    = elMatch[1];
//     asyncTermInfo(group, field, wbid);
    asyncTermInfo(field, wbid, 'itemHighlight');
  }
//   document.getElementById("term_info").innerHTML      = elLI.innerHTML;
// There is no aData for itemMouseOverEvent nor itemArrowFromEvent
// http://yui.github.io/yui2/docs/yui_2.7.0/docs/YAHOO.widget.AutoComplete.html
//   var oData = aArgs[2]; // object literal of selected item's result data 
//   if (oData === undefined) { document.getElementById("term_info").innerHTML      = document.getElementById("term_info").innerHTML + ' NOW undefined';   }
//   if (oData !== undefined) { document.getElementById("term_info").innerHTML      = oData[1]; }
} // function onAutocompleteItemHighlight(sType, aArgs)

function onAutocompleteItemSelect(sType, aArgs) {
//   document.getElementById('term_info').innerHTML += 'onAutocompleteItemSelect<br>';
  var myAC  = aArgs[0]; // reference back to the AC instance 
  var elLI  = aArgs[1]; // reference to the selected LI element 
  var oData = aArgs[2]; // object literal of selected item's result data 
  var match        = myAC._sName.match(/input_(\d+)_(.*)/);
  var count        = match[1]; count = parseInt(count);
  var field        = match[2];
  var termid_field = 'termid_' + count + '_' + field;
  var input_field  = 'input_'  + count + '_' + field;
//   var group        = fieldsData[field]["group"];
  var groupAmount  = fieldsData[field]["multi"];
//   document.getElementById("term_info").innerHTML     = termid_field; 
  document.getElementById(termid_field).value           = oData[1]; 
  document.getElementById(input_field).value            = oData[2]; 
  if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
    var countPlusOne   = count + 1;
//     var trGroupElement = 'group_' + countPlusOne + '_' + group;
    var trGroupElement = 'group_' + countPlusOne + '_' + field;
    document.getElementById(trGroupElement).style.display = "";  // only show the main value of next group, in future will need to change based on startHidden status of sub fields
  }
//   asyncTermInfo(group, field, oData[1]);
  asyncTermInfo(field, oData[1], 'itemSelect');
  var inputwarningsField = 'input_warnings_' + count + '_' + field;
  if (document.getElementById(inputwarningsField)) {
    document.getElementById(inputwarningsField).value     = ''; }		// clear the warning inputs, values selected must be correct
  var tdwarnings_field   = 'tdwarnings_' + count + '_' + field;
  if (document.getElementById(tdwarnings_field)) {
//     if (field === 'person') {					// moved this down to asyncTermInfo
//         var personId    = document.getElementById(termid_field).value;
//         var personName  = document.getElementById(input_field).value;
//         var personEmail = document.getElementById('input_1_email').value;
//         var url = cgiUrl + "?action=personPublication&personId=" + personId + "&personName=" + personName + "&personEmail=" + personEmail;
//         var urlLink = "<a href='" + url + "' target='new' style='font-weight: bold; text-decoration: underline;'>here</a>";
//         var noticeText = 'Click ' + urlLink + ' to review your publications and see which are in need of allele-sequence curation';
//         document.getElementById(inputwarningsField).value       = noticeText;
//         document.getElementById(tdwarnings_field).innerHTML     = noticeText;
//         document.getElementById(tdwarnings_field).style.display = '';	// hide the warnings, values selected must be correct
//       } else {
        document.getElementById(tdwarnings_field).innerHTML     = '';		// clear the warnings, values selected must be correct
        document.getElementById(tdwarnings_field).style.display = 'none';	// hide the warnings, values selected must be correct
//     }
  }
//   document.getElementById(input_field).blur();	// if no delay on callback from blur, might need to call blur after an item selected
//   document.getElementById('term_info').innerHTML += tdwarnings_field + '<br>';
//   document.getElementById('input_1_person').value = tdwarnings_field;
//   alert('cleared');
} // function onAutocompleteItemSelect(sType, aArgs)


// function asyncTermInfo(group, field, value)
function asyncTermInfo(field, value, actionType) {
  var callbacks = {
      success : function (o) {                                  // Successful XHR response handler
//           if (o.responseText !== undefined) { document.getElementById('term_info').innerHTML = o.responseText + "<br/> "; }
          if (o.responseText !== undefined) { 
            if (actionType === 'itemSelect') {			// if the action was selecting from ontology
//               if (field === 'person') {				// for persons, if there's an email address, populate email, otherwise clear email
//                 var match = o.responseText.match(/'mailto:(.*?)'/);
//                 var personEmail = ''; if (match !== null) { if (match[1]) { personEmail = match[1]; } }
//                 document.getElementById('input_1_email').value = personEmail; 
//                 var personId    = document.getElementById('termid_1_person').value;
//                 var personName  = document.getElementById('input_1_person').value;
//                 var url = cgiUrl + "?action=personPublication&personId=" + personId + "&personName=" + personName + "&personEmail=" + personEmail;
//                 var urlLink = "<a href='" + url + "' target='new' style='font-weight: bold; text-decoration: underline;'>here</a>";
//                 var noticeText = 'Click ' + urlLink + ' to review your publications and see which are in need of allele-sequence curation';
//                 document.getElementById('input_warnings_1_person').value       = noticeText;
//                 document.getElementById('tdwarnings_1_person').innerHTML     = noticeText;
//                 document.getElementById('tdwarnings_1_person').style.display = '';	// hide the warnings, values selected must be correct
//               }
              if (field === 'gene') {				// for persons, if there's an email address, populate email, otherwise clear email
                var match = o.responseText.match(/sequence name : <\/span> (.*)</);
                var seqName = ''; if (match !== null) { if (match[1]) { seqName = match[1]; } }
                document.getElementById('input_1_seqname').value = seqName; }
            }
            document.getElementById('term_info').innerHTML = o.responseText; } }, };
  value = convertDisplayToUrlFormat(value);                     // convert <newValue> to URL format by escaping characters
//   var sUrl = cgiUrl + "?action=asyncTermInfo&field="+field+"&termid="+value+"&group="+group;
  var sUrl = cgiUrl + "?action=asyncTermInfo&field="+field+"&termid="+value;
  document.getElementById('term_info_box').style.display = '';	// show the term info box again
  YAHOO.util.Connect.asyncRequest('GET', sUrl, callbacks);      // Make the call to the server for term info data
} // function function asyncTermInfo(field, value)


function hasChecksListener(count, field) {
  var inputElement      = document.getElementById("input_" + count + '_' + field);
  var tdwarningsField = 'tdwarnings_' + count + '_' + field;
  var inputwarningsField = 'input_warnings_' + count + '_' + field;
  var termidField     = 'termid_' + count + '_' + field;
  YAHOO.util.Event.addListener( inputElement, "keyup", function() {
    // when keyup on a field that has checks, delay 1000ms and do an ajax check on the data
    // using blur has conflicts when blurring by clicking on the autocomplete dropdown, which also require a delay
    var callbacks = {
      success : function (o) {                                  // Successful XHR response handler
        if (o.responseText !== undefined) { 
          if (o.responseText === 'ok') {
//               document.getElementById('term_info').innerHTML += 'haschecks callbacks ok<br>';
              document.getElementById(inputwarningsField).value      = '';		// clear warning on input field for preview
              document.getElementById(tdwarningsField).style.display = 'none'; }
            else {
              document.getElementById(tdwarningsField).style.display = '';	// show warning element
              if (document.getElementById(termidField)) {
                document.getElementById(termidField).value = ''; }		// clear termid, not a match
//               document.getElementById('term_info').innerHTML += 'haschecks callbacks else<br>';
              document.getElementById(inputwarningsField).value  = o.responseText;	// pass on warning to input field for preview
              document.getElementById(tdwarningsField).innerHTML = o.responseText; }
    } }, };
    var match        = this.id.match(/input_(\d+)_(.*)/); 
    delay(function(){						// must delay because clicking from autocomplete dropdown will blur, choosing the typed entry before the item selection puts it in the input field.  delay lets the value go into the field for callbacks to get that value for the ajax call.
      var count        = match[1]; count = parseInt(count);
      var field        = match[2];
//       if (field === 'pmid') { asyncPmidTermInfo(); }		// pmids have terminfo on keyup as well as the checks
      asyncTermInfoFromFieldCount(field, count);		// get term info for fields with checks (this might not be the correct thing to do, needed for pmid and allele)
      inputElement     = document.getElementById("input_" + count + '_' + field);
      var value = inputElement.value;
      value = convertDisplayToUrlFormat(value);                     // convert <newValue> to URL format by escaping characters
      var sUrl = cgiUrl + "?action=asyncFieldCheck&field="+field+"&input="+value;
//       document.getElementById('term_info').innerHTML += 'prep check ' + value + '<br>';
      YAHOO.util.Connect.asyncRequest('GET', sUrl, callbacks);      // Make the call to the server for term info data
    }, 1000 );
  }); 
} // function hasChecksListener(count, field)

function setInputListeners() {
  var toAlert = '';
  for (var i = 0; i < myFields.length; i++ ) {                  // for each field type
    var field  = myFields[i];
//     toAlert += " " + field + "\n";
    var amount       = fieldsData[field]["multi"];
    for (var j = 1; j <= amount; j++ ) {				// for each specific number of that field
      if ( fieldsData[myFields[i]]["type"] === "text" ) {		// if it's a text field
        oElement = document.getElementById("input_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener(oElement, "keyup", function() {	// when typing in a text input element unhide next multi field
          var match        = this.id.match(/input_(\d+)_(.*)/); 
          var count        = match[1]; count = parseInt(count);
          var field        = match[2];
//           var group        = fieldsData[field]["group"];
          var groupAmount  = fieldsData[field]["multi"];		// keyup of text groups, show rows of next group
          if ( document.getElementById("input_" + count + '_' + field).value !== '' ) {
            if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
              var countPlusOne     = count + 1;
              var groupFieldsArray = fieldsData[field]["grouphas"];	// fields in this group including main field
              for (var groupField in groupFieldsArray) {		// foreach field in the group, get the next tr element and display it
                var trGroupElement   = 'group_' + countPlusOne + '_' + groupFieldsArray[groupField];
                document.getElementById(trGroupElement).style.display = ""; } } }
        });
      } // if ( fieldsData[myFields[i]]["type"] === "text" )

      if ( fieldsData[myFields[i]]["type"] === "ontology" ) {			// ontology values load term info when input is field is clicked
        inputElement  = document.getElementById("input_"  + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener(inputElement, "keyup", function(e) {	// when typing in an ontology field
          var match     = this.id.match(/input_(\d+)_(.*)/); 
          var count     = match[1]; count = parseInt(count);
          var field     = match[2];
          termidElement = document.getElementById("termid_" + count + '_' + field); 
          if ( (e.keyCode !== 9) && (e.keyCode !== 13) ) {	 	// unless selecting term by pressing 'enter key' with keycode 13 or tabbing through with 9
            termidElement.value = ''; }					// clear the corresponding termid, in case they choose an invalid value
          if (field === 'person') {					// person id clear the notice linking to their publications
            var inputwarningsField = 'input_warnings_' + count + '_' + field;
            var tdwarnings_field   = 'tdwarnings_' + count + '_' + field;
            document.getElementById(inputwarningsField).value       = '';
            document.getElementById(tdwarnings_field).innerHTML     = ''; 
          } // if (field === 'person')
            // keyup of ontology groups, show hidden fields in group
          var groupFieldsArray = fieldsData[field]["grouphas"];         // fields in this group including main field
          for (var groupField in groupFieldsArray) {	                // foreach field in the group, get the next tr element and display it
            var trGroupElement   = 'group_' + count + '_' + groupFieldsArray[groupField];
            document.getElementById(trGroupElement).style.display = ""; }
        });
        YAHOO.util.Event.addListener(inputElement, "focus", function() {	// when focusing an ontology input element, async term info
          var match = this.id.match(/input_(\d+)_(.*)/); 
          var count        = match[1]; count = parseInt(count);
          var field        = match[2];
          termidElement = document.getElementById("termid_" + count + '_' + field);
          if (termidElement.value) {					// only if there's a value try to get term info
            asyncTermInfo(field, termidElement.value, 'focus'); }
        }); 
      }

      if (fieldsData[myFields[i]]["haschecks"]) { hasChecksListener(j, myFields[i]); }

      if ( fieldsData[myFields[i]]["type"] === "bigtext" ) {                                 // if it's a bigtext field
        oElement = document.getElementById("input_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener(oElement, "focus", function() {			// when clicking a bigtext input element, hide input, load data into textarea, show textarea
            var match = this.id.match(/input_(.*)/); var count_field = match[1];	// get the count_field from the id
            document.getElementById("input_" + count_field).style.display = "none";
            document.getElementById("textarea_bigtext_" + count_field).style.display = "";
            if (document.getElementById("textarea_bigtext_" + count_field).value === '') {	// only transfer value if already empty
                document.getElementById("textarea_bigtext_" + count_field).value = document.getElementById("input_" + count_field).value; }
            document.getElementById("textarea_bigtext_" + count_field).focus();
        });
        var bigtextElement = document.getElementById("textarea_bigtext_" + j + '_' + myFields[i]);
        YAHOO.util.Event.addListener( bigtextElement, "blur", function() {		// when blurring a bigtext textarea element, hide textarea, load data into input, show input
            var match = this.id.match(/textarea_bigtext_(.*)/); var count_field = match[1];	// get the count_field from the id
            document.getElementById("textarea_bigtext_" + count_field).style.display = "none";
            document.getElementById("input_" + count_field).style.display = "";
            document.getElementById("input_" + count_field).value = document.getElementById("textarea_bigtext_" + count_field).value;       // switch value from textarea to input, regardless of whether noteditable or not
        }); 
// not sure I need this in strain_request.cgi since bigtext fields don't trigger showing rows.  2015 05 14
//         YAHOO.util.Event.addListener(bigtextElement, "keyup", function() {		// when typing in a bigtext textarea element unhide next multi field
//           var match        = this.id.match(/textarea_bigtext_(\d+)_(.*)/); 
//           var count        = match[1]; count = parseInt(count);
//           var field        = match[2];
//           var group        = fieldsData[field]["group"];
//           var groupAmount  = fieldsData[field]["multi"];
//           if ( document.getElementById("textarea_bigtext_" + count + '_' + field).value !== '' ) {
//             if ( (groupAmount > 1) && (count < groupAmount) ) {		// multivalue field not at max amount has data, so show next field
//               var countPlusOne   = count + 1;
//               var trGroupElement = 'group_' + countPlusOne + '_' + group;
//               document.getElementById(trGroupElement).style.display = ""; } } 
//         }); 
      } // if ( fieldsData[myFields[i]]["type"] === "bigtext" )

//       if ( fieldsData[myFields[i]]["type"] === "radio" ) {		// if it's a radio field
//         var arrRadioValues = fieldsData[myFields[i]]["radio"].split(" ");
//         for (var k = 0; k < arrRadioValues.length; k++ ) {				// for each specific number of that field
//           var radioValue = arrRadioValues[k];   
//           oElement = document.getElementById("radio_" + j + '_' + myFields[i] + '_' + radioValue);
//           YAHOO.util.Event.addListener(oElement, "click", checkRadioStateListener);
// 
//         } // for (var k = 0; k < arrRadioValues.length; k++ )
//       } // if ( fieldsData[myFields[i]]["type"] === "radio" )

    } // for (var j = 1; j <= amount; j++ )
  } // for (var i = 0; i < myFields.length; i++ )

  var oElement = document.getElementById("input_1_pmid");	// this might need its own type later on if used more (like 'terminfo' instead of 'ontology')
  YAHOO.util.Event.addListener(oElement, "focus", function() {	// when focusing the pmid input element, async term info
    asyncTermInfoFromFieldCount('pmid', '1');
//     asyncPmidTermInfo(); 
  });
// this delay is clashing with the hasChecksListener which also happens on keyup, so just tacking something on there for pmid
//   YAHOO.util.Event.addListener(oElement, "keyup", function() {	// on keyup lookup the pmid into term info after a 1000ms delay
//     delay(function(){
//       asyncPmidTermInfo();
//     }, 1000 );
//   });

//   alert(toAlert);
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
            for (t = 0; t < arrTdsShow.length; t++) { arrTdsShow[t].innerHTML = '<span style="color:red">M</span>'; }
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
    for (var j = 1; j <= amount; j++ ) {				// for each specific number of that field
      var fieldElementId = "input_" + j + "_" + field;
      toAlert += " " + fieldElementId + " j " + j + " amount " + amount;

      if ( fieldsData[myFields[i]]["type"] === "ontology" ) {                                     // ontology values load term info when input is field is clicked
        settingAutocompleteListeners = function() {
          var sUrl = cgiUrl + "?action=autocompleteXHR&field=" + field + "&";   // ajax calls need curator and datatype
          var oDS = new YAHOO.util.XHRDataSource(sUrl);          // Use an XHRDataSource
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
          var forceSelection            = true;
          if ( fieldsData[myFields[i]]["freeForced"] === "free" ) { forcedOrFree = "free"; forceSelection = false; }
          var inputElement              = document.getElementById("input_" + j + '_' + field);
          var containerElement          = document.getElementById(forcedOrFree + j + field + "Container");
          var forcedOAC                 = new YAHOO.widget.AutoComplete(inputElement, containerElement, oDS);
          forcedOAC.queryQuestionMark   = false;                   // don't add a ? to the sUrl query since it's been built with some other values
          forcedOAC.maxResultsDisplayed = 500;
          forcedOAC.forceSelection      = forceSelection;
          forcedOAC.itemSelectEvent.subscribe(onAutocompleteItemSelect);
          forcedOAC.selectionEnforceEvent.subscribe(onAutocompleteSelectionEnforce);	// pre-loaded data is not from AC and gets forced out, reload it if unchanged
          forcedOAC.itemArrowToEvent.subscribe(onAutocompleteItemHighlight);
          forcedOAC.itemMouseOverEvent.subscribe(onAutocompleteItemHighlight);
          return {
              oDS: oDS,
              forcedOAC: forcedOAC
          }
        }();
      } // if ( fieldsData[myFields[i]]["type"] === "ontology" )

    } // for (var j = 1; j <= amount; j++ )
  } // for (var i = 0; i < myFields.length; i++ )

//   alert(toAlert);
} // function setAutocompleteListeners()

function onAutocompleteSelectionEnforce(oSelf, sClearedValue) {		// pre-loaded data is not from AC and gets forced out, reload it if unchanged
  var myAC         = sClearedValue[0];		// reference back to the AC instance 
  var previousText = sClearedValue[1];		// text that got cleared
  var match        = myAC._sName.match(/input_(\d+)_(.*)/); 
  var count        = match[1]; count = parseInt(count);
  var field        = match[2];
  if (document.getElementById('loaded_' + count + '_' + field).value ) {			// the preloaded value
    if (document.getElementById('loaded_' + count + '_' + field).value === previousText) {	// if preloaded value same as cleared text
      document.getElementById('input_' + count + '_' + field).value = previousText; } }		// put back in input field
//   alert("count " + count + " field " + field + " myAC " + myAC + " pT " + previousText + " oSelf " + oSelf + " cleared " + sClearedValue + " end");
} // function onAutocompleteSelectionEnforce(oSelf, sClearedValue)

function asyncTermInfoFromFieldCount(field, count) {
  var value = document.getElementById('input_' + count + '_' + field).value
  asyncTermInfo(field, value, '');
} // asyncTermInfoFromField(field)

// function asyncPmidTermInfo() {					// load the term info for the pmid in the only pmid field
//   var field = 'pmid';
//   var value = document.getElementById('input_1_' + field).value
//   asyncTermInfo(field, value, '');

// //   var pmidTitles = document.getElementById("term_info").value;
// //   var pmids      = document.getElementById("input_1_pmid").value;
// //   var callbacks = {
// //     success : function (o) {                                  // Successful XHR response handler
// //       if (o.responseText !== undefined) { document.getElementById('term_info').innerHTML = o.responseText; } }, };
// //   pmids = convertDisplayToUrlFormat(pmids);                     // convert <newValue> to URL format by escaping characters
// //   pmidTitles = convertDisplayToUrlFormat(pmidTitles);           // convert <newValue> to URL format by escaping characters
// //   if (pmids) {							// if there are pmids, do a lookup
// //     var sUrl = cgiUrl + "?action=pmidToTitle&pmids="+pmids+"&pmidTitles="+pmidTitles;	// this form only uses one pmid, does not need to send existing matches, but leaving just in case
// //     document.getElementById('term_info_box').style.display = '';	// show the term info box again
// //     YAHOO.util.Connect.asyncRequest('GET', sUrl, callbacks);		// Make the call to the server for term info data
// //   }
// } // function asyncPmidTermInfo()


function convertDisplayToUrlFormat(value) {
    if (value !== undefined) {                                                  // if there is a display value replace stuff
        if (value.match(/\n/)) { value = value.replace(/\n/g, " "); }           // replace linebreaks with <space>
        if (value.match(/\+/)) { value = value.replace(/\+/g, "%2B"); }         // replace + with escaped +
        if (value.match(/\#/)) { value = value.replace(/\#/g, "%23"); }         // replace # with escaped #
    }
    return value;                                                               // return value in format for URL
} // function convertDisplayToUrlFormat(value)

var delay = (function(){                                            // delay executing a function until user has stopped typing for a timeout amount
    var timer = 0;
    return function(callback, ms){
        clearTimeout (timer);
        timer = setTimeout(callback, ms);
    };
})();


