

var myFields = new Array();			// the data fields, for some reason the elements get replaced by objects when datatable gets created
var fieldsData = new Object();
var cgiUrl = "lab_editor.cgi";


YAHOO.util.Event.addListener(window, "load", function() { 			// on load get fields, assign listeners
  populateMyFields();								// populate myFields array
  var fields = myFields.join('","')
  setFieldListeners();								// for each ontology field, add autocomplete listener

  var whichPage = document.getElementById("which_page").value;
  if (whichPage === 'createNewLab') {						// add a redirect to page of newly created person after trying to create it
    if (document.getElementById('redirect_to').value) {
      window.location = document.getElementById('redirect_to').value; }
  }

}); // YAHOO.util.Event.addListener(window, "load", function() 


function populateMyFields() {							// populate myFields array based on input fields
  this.myFields = [ ];
  var inputs = document.getElementsByTagName("input");				// get all input fields
  for (var i = 0; i < inputs.length; i++ ) {					// loop through them
    if (inputs[i].className == "fields") { 					// if the class is fields
      var field = inputs[i].value;
      this.myFields.push(field); 						// add to myFields array
      fieldsData[field] = new Object(); }					// new hash for this field
} } // function populateMyFields()


function updatePostgresTableField(field, joinkey, order, newValue) {
    var callbacks = { 
        success : function (o) {				// Successful XHR response handler 
//             if (o.responseText === 'OK') { window.location.reload(false); } 		// reload page if successful, but it's a problem that selecting autocomplete blurs the field before loading the autocomplete value
            if (o.responseText === 'OK') { } 			// it's ok, don't say anything
            else { alert("ERROR not OK response for newValue " + newValue + " did not update for joinkey " + joinkey + " and " + field + " " + o.responseText); }
        },
        failure:function(o) {
            alert("ERROR newValue " + newValue + " did not update for joinkey " + joinkey + " and " + field + "<br>" + o.statusText);
        },
    }; 
    var curatorTwo = document.getElementById('curator_two').value;
    newValue = convertDisplayToUrlFormat(newValue); 		// convert <newValue> to URL format by escaping characters
    var sUrl = cgiUrl + "?action=updatePostgresTableField&joinkey="+joinkey+"&field="+field+"&newValue="+escape(newValue)+"&order="+order+"&curator_two="+curatorTwo;
    YAHOO.util.Connect.asyncRequest('GET', sUrl, callbacks);	// Make the call to the server to update postgres
} // function updatePostgresTableField(field, joinkey, order, newValue)

function convertDisplayToUrlFormat(value) {
    if (value !== undefined) {							// if there is a display value replace stuff
        if (value.match(/\+/)) { value = value.replace(/\+/g, "%2B"); }		// replace + with escaped +
        if (value.match(/\#/)) { value = value.replace(/\#/g, "%23"); }		// replace # with escaped #
    }
    return value;								// return value in format for URL
} // function convertDisplayToUrlFormat(value)


function editorInputBlurListener(e) {                           // editor input blurred, update corresponding values of selected rows
    var fieldstuff = e.target.id.match(/input_(.*)_(.*)/);           // this is event (button click)
    var field = fieldstuff[1];                                  // get the field name from the event id
    var order = fieldstuff[2];                                  // get the field name from the event id
    var newValue = e.target.value;                              // the new value from the editor input field
    editorFieldBlur(field, order, newValue);                           // call editorFieldBlur to do all the actions
} // function editorInputBlurListener(e)

function editorFieldBlur(field, order, newValue) {
  var joinkey = document.getElementById("person_joinkey").value;
  updatePostgresTableField(field, joinkey, order, newValue);
//   console.log("field " + field + " order " + order + " joinkey " + joinkey + " newValue " + newValue + " end");	// do not uncomment this, the alert will pop before the selected autocomplete value goes into the input field, which makes the newValue be the partially typed entry
} // function editorFieldBlur(field)


function setFieldListeners() {				// for each ontology field, add autocomplete listener
  var toAlert;

  for (var i = 0; i < myFields.length; i++ ) { 			// for each field
    var field = myFields[i];
    if (document.getElementById("type_input_" + field) === null) { alert( "no type_input " + field ); }
    var typeInput = document.getElementById("type_input_" + field).value;
    if (document.getElementById("highest_order_" + field) === null) { alert( "no highest_order " + field ); }
    var highestOrder = document.getElementById("highest_order_" + field).value;
// toAlert += "field " + field + " highestOrder " + highestOrder + " " + " typeInput " + typeInput + " ";
    for (var order = 1; order < parseInt(highestOrder) + 1; order++ ) { 	// for each order
      var inputElement = document.getElementById("input_" + field + "_" + order);
      if (inputElement === null) { continue; }

        // Editor Blur Listener
      if ( document.getElementById("which_page").value === 'displayLabEditor' ) {
        var oElement = document.getElementById("input_" + myFields[i] + "_" + order);
// toAlert += "field " + field + " order " + order + "\n";
        if (typeInput === 'input') {
            YAHOO.util.Event.addListener(oElement, "blur", editorInputBlurListener ); }	// add the listener function
      } // if ( document.getElementById("which_page").value === 'displayPersonEditor' )

        // Autocomplete Listener
      if (typeInput === 'input') {				// input fields have autocomplete
        settingAutocompleteListeners = function() {
// toAlert += "SAL field " + field + " order " + order + " ";
          var sUrl = cgiUrl + "?action=autocompleteXHR&field=" + field + "&order=" + order + "&";	// ajax calls need curator and datatype
          var oDS = new YAHOO.util.XHRDataSource(sUrl);		// Use an XHRDataSource
          oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;	// Set the responseType
          oDS.responseSchema = {					// Define the schema of the delimited results
              recordDelim: "\n",
              fieldDelim: "\t"
          };
          oDS.maxCacheEntries = 5;				// Enable caching
          var forcedOrFree = "free";
          var inputElement = document.getElementById("input_" + field + "_" + order);
          var containerElement = document.getElementById(forcedOrFree + field + order + "Container");
          var forcedOAC = new YAHOO.widget.AutoComplete(inputElement, containerElement, oDS);
          forcedOAC.queryQuestionMark = false;			// don't add a ? to the sUrl query since it's been built with some other values
          forcedOAC.maxResultsDisplayed = 500;
          forcedOAC.forceSelection = false;
//           toAlert += "field " + field + " order " + order + " ";
          forcedOAC.itemSelectEvent.subscribe(onAutocompleteItemSelect);
          return {
              oDS: oDS,
              forcedOAC: forcedOAC
          }
        }();
      } // if (typeInput === 'input')
    } // for (var order = 0; order < highestOrder; order++ )
  } // for (var i = 0; i < myFields.length; i++ ) 		// for each field
//   alert(toAlert);
} // function setFieldListeners()

function onAutocompleteItemSelect(oSelf, elItem) {		// if an autocomplete item is selected 
  var match = elItem[0]._sName.match(/input_(.*)_(.*)/);		// get the field
  var field = match[1];						// get the field name from the event id
  var order = match[2];						// get the field name from the event id
  document.getElementById('input_' + field + '_' + order).focus();		// focus to trigger editorInputBlurListener
  document.getElementById('input_' + field + '_' + order).blur();		// blur to trigger editorInputBlurListener
//   alert("field " + field + " order " + order + " end");	
} // function onAutocompleteItemSelect(oSelf , elItem) 

