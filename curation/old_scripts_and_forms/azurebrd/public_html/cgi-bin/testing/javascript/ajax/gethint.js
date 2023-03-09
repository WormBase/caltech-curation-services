function GetXmlHttpObject() {
    var xmlHttp=null;
    try {		// Firefox, Opera 8.0+, Safari
       xmlHttp=new XMLHttpRequest();
    }
    catch (e) {		// Internet Explorer
        try { xmlHttp=new ActiveXObject("Msxml2.XMLHTTP"); }
        catch (e) { xmlHttp=new ActiveXObject("Microsoft.XMLHTTP"); }
    }
    return xmlHttp;
}

function stateChanged() { 
    if (xmlHttp.readyState==4) { 
        document.getElementById("txtHint").innerHTML=xmlHttp.responseText;
    }
}

function showHint(text) {
    if (text.length==0) { 
        document.getElementById("txtHint").innerHTML="";
        return;
    }
    xmlHttp=GetXmlHttpObject();
    if (xmlHttp==null) {
        alert ("Your browser does not support AJAX!");
        return;
    } 
    var words = text.split(/\s/);
    var str = words.pop();
//     var url="gethint.php";
    var url="gethint.cgi";
    url=url+"?q="+str;
    url=url+"&all="+text;
    url=url+"&sid="+Math.random();
    xmlHttp.onreadystatechange=stateChanged;
    xmlHttp.open("GET",url,true);
    xmlHttp.send(null);
}
