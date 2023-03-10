
function Term(termid, termname, ontologyname) {
  this.termId = termid;
  this.termName = termname;
  this.ontology = ontologyname;

  this.params = 'termId='+this.termId+'&ontologyName='+this.ontology;
}

var phenoteState = {

  activeField : {},  
  currentTermInfoTerm : {}, 
  termInfoUrl : {},

  setTermInfoUrl : function (url) {
    this.termInfoUrl = url;
  },

  setActiveField : function (field) {
    this.activeField = field;
  },

  getActiveField : function () {
    return this.activeField;
  },

  setCurrentTermInfoTerm : function (term) {
    this.currentTermInfoTerm = term;
  },

  getCurrentTermInfoTerm : function () {
    return this.currentTermInfoTerm;
  },

  updateTermInfo : function (term) {
    var pars = term.params;
    var myAjax = new Ajax.Updater('termInfo', this.termInfoUrl, {method: 'get', parameters: pars } );
    this.setCurrentTermInfoTerm(term);
  },

  useTermInfo : function () {
    this.getActiveField().value = this.currentTermInfoTerm.termName;
  }
  
}



