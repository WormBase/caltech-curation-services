      
// This is a variable which defines the path to the ajax request processing script
// This can be changed and should point to the scipt which processes the Ajax queries
//var url  = '/usr/local/lib/apache/apache-tomcat-5.5.15/webapps/ROOT/ajax/scripts/phenote-ontology.cgi';
//var url  = '/phenote-ontology.cgi';
// term info not yet implemented in PhenoteServlet - todo...
// this should be a relative link - need to get servlets code in/close with scripts?
//var url = '/servlet/PhenoteStub'; 
//var url = '/servlet/Phenote'; // tomcat - not jboss
var url = '/phenote/Phenote/'; // jboss
      

// getTermInfo should be called by the above url (at least for dichty it does)
// renaming this getTermInfo... from set_ontology,
// ontologyid -> termId


// ontologyName is the name of the ontology (not a term name!)
function getTermInfo(term) {
  phenoteState.updateTermInfo(term);
}


function useTermInfo() {
  phenoteState.useTermInfo();
}

