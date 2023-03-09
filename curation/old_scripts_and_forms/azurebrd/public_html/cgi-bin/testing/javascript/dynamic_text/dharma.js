// http://cdn.blinkx.com/images/blinkx3/combined/combined2.php?d=6VhVNxgEVsUNhP7mfcznDm1Q3Kb6_zZQ0rmWwcNdxSbX44_CCc32vuHqk_tx5gDKPot8iaCeJNH8qr-QQjDKL80BgBS9Ii7t8IGerw5SmuxXoOvZu1NWCZuj1S7yPk7YMJjMGaESGDWR4wTRtnwed175wMgKBaTX23184xk46lcm7loDfUupC9P7VAG6_ogDucuOMNb3PJn26jkbvwDsN2Gq01yaGpIhrQmRR80OVGgCMGAJ34fO3mchfAPo2BPwwvERwwG1kJxdcrhIrw9dN0MO5wICC0jRllxRXiayFLsS-Lm8BGrZlpCBdjwjHQfoBfE3ipCRAyvc4MgWb68_8DsRXhNOQoaK9u9cR7W1AD7zhbUnu6N0Md3UnLSKVBh13YCz91Is4glJjELye_ySeK8bLw5lzdxmwXviQEeGMIJZzR2jZEhaLmDLQsVEx9gCetZ1IsPtab9p68Hi2wTVqZLTn4zEzpeaA64vytZu7LFxg3oTxq5o6wCxbEBbICankwcMVhfU7hg_nbupwfNZPA
// doesn't work with local copy

/**
 * SWFObject v1.5: Flash Player detection and embed - http://blog.deconcept.com/swfobject/
 *
 * SWFObject is (c) 2007 Geoff Stearns and is released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 *
 */
if(typeof deconcept=="undefined"){var deconcept=new Object();}if(typeof deconcept.util=="undefined"){deconcept.util=new Object();}if(typeof deconcept.SWFObjectUtil=="undefined"){deconcept.SWFObjectUtil=new Object();}deconcept.SWFObject=function(_1,id,w,h,_5,c,_7,_8,_9,_a){if(!document.getElementById){return;}this.DETECT_KEY=_a?_a:"detectflash";this.skipDetect=deconcept.util.getRequestParameter(this.DETECT_KEY);this.params=new Object();this.variables=new Object();this.attributes=new Array();if(_1){this.setAttribute("swf",_1);}if(id){this.setAttribute("id",id);}if(w){this.setAttribute("width",w);}if(h){this.setAttribute("height",h);}if(_5){this.setAttribute("version",new deconcept.PlayerVersion(_5.toString().split(".")));}this.installedVer=deconcept.SWFObjectUtil.getPlayerVersion();if(!window.opera&&document.all&&this.installedVer.major>7){deconcept.SWFObject.doPrepUnload=true;}if(c){this.addParam("bgcolor",c);}var q=_7?_7:"high";this.addParam("quality",q);this.setAttribute("useExpressInstall",false);this.setAttribute("doExpressInstall",false);var _c=(_8)?_8:window.location;this.setAttribute("xiRedirectUrl",_c);this.setAttribute("redirectUrl","");if(_9){this.setAttribute("redirectUrl",_9);}};deconcept.SWFObject.prototype={useExpressInstall:function(_d){this.xiSWFPath=!_d?"expressinstall.swf":_d;this.setAttribute("useExpressInstall",true);},setAttribute:function(_e,_f){this.attributes[_e]=_f;},getAttribute:function(_10){return this.attributes[_10];},addParam:function(_11,_12){this.params[_11]=_12;},getParams:function(){return this.params;},addVariable:function(_13,_14){this.variables[_13]=_14;},getVariable:function(_15){return this.variables[_15];},getVariables:function(){return this.variables;},getVariablePairs:function(){var _16=new Array();var key;var _18=this.getVariables();for(key in _18){_16[_16.length]=key+"="+_18[key];}return _16;},getSWFHTML:function(){var _19="";if(navigator.plugins&&navigator.mimeTypes&&navigator.mimeTypes.length){if(this.getAttribute("doExpressInstall")){this.addVariable("MMplayerType","PlugIn");this.setAttribute("swf",this.xiSWFPath);}_19="<embed type=\"application/x-shockwave-flash\" src=\""+this.getAttribute("swf")+"\" width=\""+this.getAttribute("width")+"\" height=\""+this.getAttribute("height")+"\" style=\""+this.getAttribute("style")+"\"";_19+=" id=\""+this.getAttribute("id")+"\" name=\""+this.getAttribute("id")+"\" ";var _1a=this.getParams();for(var key in _1a){_19+=[key]+"=\""+_1a[key]+"\" ";}var _1c=this.getVariablePairs().join("&");if(_1c.length>0){_19+="flashvars=\""+_1c+"\"";}_19+="/>";}else{if(this.getAttribute("doExpressInstall")){this.addVariable("MMplayerType","ActiveX");this.setAttribute("swf",this.xiSWFPath);}_19="<object id=\""+this.getAttribute("id")+"\" classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\" width=\""+this.getAttribute("width")+"\" height=\""+this.getAttribute("height")+"\" style=\""+this.getAttribute("style")+"\">";_19+="<param name=\"movie\" value=\""+this.getAttribute("swf")+"\" />";var _1d=this.getParams();for(var key in _1d){_19+="<param name=\""+key+"\" value=\""+_1d[key]+"\" />";}var _1f=this.getVariablePairs().join("&");if(_1f.length>0){_19+="<param name=\"flashvars\" value=\""+_1f+"\" />";}_19+="</object>";}return _19;},write:function(_20){if(this.getAttribute("useExpressInstall")){var _21=new deconcept.PlayerVersion([6,0,65]);if(this.installedVer.versionIsValid(_21)&&!this.installedVer.versionIsValid(this.getAttribute("version"))){this.setAttribute("doExpressInstall",true);this.addVariable("MMredirectURL",escape(this.getAttribute("xiRedirectUrl")));document.title=document.title.slice(0,47)+" - Flash Player Installation";this.addVariable("MMdoctitle",document.title);}}if(this.skipDetect||this.getAttribute("doExpressInstall")||this.installedVer.versionIsValid(this.getAttribute("version"))){var n=(typeof _20=="string")?document.getElementById(_20):_20;n.innerHTML=this.getSWFHTML();return true;}else{if(this.getAttribute("redirectUrl")!=""){document.location.replace(this.getAttribute("redirectUrl"));}}return false;}};deconcept.SWFObjectUtil.getPlayerVersion=function(){var _23=new deconcept.PlayerVersion([0,0,0]);if(navigator.plugins&&navigator.mimeTypes.length){var x=navigator.plugins["Shockwave Flash"];if(x&&x.description){_23=new deconcept.PlayerVersion(x.description.replace(/([a-zA-Z]|\s)+/,"").replace(/(\s+r|\s+b[0-9]+)/,".").split("."));}}else{if(navigator.userAgent&&navigator.userAgent.indexOf("Windows CE")>=0){var axo=1;var _26=3;while(axo){try{_26++;axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash."+_26);_23=new deconcept.PlayerVersion([_26,0,0]);}catch(e){axo=null;}}}else{try{var axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");}catch(e){try{var axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");_23=new deconcept.PlayerVersion([6,0,21]);axo.AllowScriptAccess="always";}catch(e){if(_23.major==6){return _23;}}try{axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash");}catch(e){}}if(axo!=null){_23=new deconcept.PlayerVersion(axo.GetVariable("$version").split(" ")[1].split(","));}}}return _23;};deconcept.PlayerVersion=function(_29){this.major=_29[0]!=null?parseInt(_29[0]):0;this.minor=_29[1]!=null?parseInt(_29[1]):0;this.rev=_29[2]!=null?parseInt(_29[2]):0;};deconcept.PlayerVersion.prototype.versionIsValid=function(fv){if(this.major<fv.major){return false;}if(this.major>fv.major){return true;}if(this.minor<fv.minor){return false;}if(this.minor>fv.minor){return true;}if(this.rev<fv.rev){return false;}return true;};deconcept.util={getRequestParameter:function(_2b){var q=document.location.search||document.location.hash;if(_2b==null){return q;}if(q){var _2d=q.substring(1).split("&");for(var i=0;i<_2d.length;i++){if(_2d[i].substring(0,_2d[i].indexOf("="))==_2b){return _2d[i].substring((_2d[i].indexOf("=")+1));}}}return "";}};deconcept.SWFObjectUtil.cleanupSWFs=function(){var _2f=document.getElementsByTagName("OBJECT");for(var i=_2f.length-1;i>=0;i--){_2f[i].style.display="none";for(var x in _2f[i]){if(typeof _2f[i][x]=="function"){_2f[i][x]=function(){};}}}};if(deconcept.SWFObject.doPrepUnload){if(!deconcept.unloadSet){deconcept.SWFObjectUtil.prepUnload=function(){__flash_unloadHandler=function(){};__flash_savedUnloadHandler=function(){};window.attachEvent("onunload",deconcept.SWFObjectUtil.cleanupSWFs);};window.attachEvent("onbeforeunload",deconcept.SWFObjectUtil.prepUnload);deconcept.unloadSet=true;}}if(!document.getElementById&&document.all){document.getElementById=function(id){return document.all[id];};}var getQueryParamValue=deconcept.util.getRequestParameter;var FlashObject=deconcept.SWFObject;var SWFObject=deconcept.SWFObject;var EventUtil=new Object;
EventUtil.addEventHandler=function(oTarget,sEventType,fnHandler){
	if(oTarget)
	{
		if(oTarget.addEventListener)oTarget.addEventListener(sEventType,fnHandler,false);
		else if(oTarget.attachEvent)oTarget.attachEvent("on"+sEventType,fnHandler);
		else oTarget["on"+sEventType]=fnHandler;
	}
};

EventUtil.removeEventHandler=function(oTarget,sEventType,fnHandler){
	if(oTarget)
	{
		if(oTarget.removeEventListener)oTarget.removeEventListener(sEventType,fnHandler,false);
		else if(oTarget.detachEvent)oTarget.detachEvent("on"+sEventType,fnHandler);
		else oTarget["on"+sEventType]=null;
	}
};

EventUtil.formatEvent=function(oEvent){
	if(typeof oEvent.charCode=="undefined")
	{
		oEvent.charCode=(oEvent.type=="keypress")?oEvent.keyCode:0;
		oEvent.isChar=(oEvent.charCode>0);
	}
	if(oEvent.srcElement&&!oEvent.target)
	{
		oEvent.eventPhase=2;
		oEvent.pageX=oEvent.clientX+document.body.scrollLeft;
		oEvent.pageY=oEvent.clientY+document.body.scrollTop;
		if(!oEvent.preventDefault)oEvent.preventDefault=function(){this.returnValue=false;};
		if(oEvent.type=="mouseout")oEvent.relatedTarget=oEvent.toElement;
		else if(oEvent.type=="mouseover")oEvent.relatedTarget=oEvent.fromElement;
		if(!oEvent.stopPropagation)oEvent.stopPropagation=function(){this.cancelBubble=true;};
		oEvent.target=oEvent.srcElement;
		oEvent.time=(new Date).getTime();
	}
	return oEvent;
};

EventUtil.getEvent=function(){
	if(window.event)return this.formatEvent(window.event);
	else return EventUtil.getEvent.caller.arguments[0];
};//---------------------------------------------------------Flash-----------------------------------------------------------//
//DEFINE THE REQUIRED VERSION OF FLASH FOR THE SITE
var FLASH_VERSION_MAJOR=9, FLASH_VERSION_MINOR=0, FLASH_VERSION_REVISION=28;

//Detects whether flash is the correct version
function isCorrectFlashVersionInstalled(iMajorVer,iMinorVer,iRevisionVer)
{
	var bInstalled=false;
	if(navigator.mimeTypes.length>0)
	{
		bInstalled=navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin!=null;
	}
	else if(window.ActiveXObject)
	{
		try
		{
			new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
			bInstalled=true;
		}
		catch(oError)
		{
			bInstalled=false;
		}
	}

	if(bInstalled)
	{
		bVerOk=false;
		if(window.DetectFlashVer)
		{
			bVerOk=DetectFlashVer(iMajorVer,iMinorVer,iRevisionVer);
		}
		else if(deconcept.SWFObjectUtil)
		{
			bVerOk=deconcept.SWFObjectUtil.getPlayerVersion().versionIsValid(new deconcept.PlayerVersion([FLASH_VERSION_MAJOR,FLASH_VERSION_MINOR,FLASH_VERSION_REVISION]));
		}
		return bVerOk;
	}
}

//Main method to load flash.
function showFlash(source,newId,width,height,flashvars,replaceId)
{
	if(isCorrectFlashVersionInstalled(FLASH_VERSION_MAJOR,FLASH_VERSION_MINOR,FLASH_VERSION_REVISION))
	{
		var playerMasq = new SWFObject(source, newId,width,height,FLASH_VERSION_MAJOR+"."+FLASH_VERSION_MINOR+"."+FLASH_VERSION_REVISION, "#000000");
		playerMasq.addParam("allowScriptAccess", "always");
		playerMasq.addParam("quality", "high");
		playerMasq.addParam("allowFullScreen", "true");
		playerMasq.addParam("bgcolor", "#000000");
		playerMasq.addParam("flashvars",flashvars);
		playerMasq.write(replaceId);
	}
	else
	{
		incorrectFlashVersion();
	}
}

//What to do if the flash version is incorrect
function incorrectFlashVersion()
{
	var replaceContentHtml = "<table width=\"100%\" height=\"100%\"><tr><td align=\"center\" style=\"background-color:white\">You must have at least version "+FLASH_VERSION_MAJOR+"."+FLASH_VERSION_MINOR+"."+FLASH_VERSION_REVISION+" of the Adobe Flash Player installed<br/>to view the blinkx player.<br/><br/>You can download Adobe Flash Player <a alt=\"Download Adobe Flash Player\" href=\"http://www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash\">here</a>.</td></tr></table>";
}

//Tries to switch an image to a default image - for if it fails to load
function processDefaultImage(oImg,sDefault)
{
	if(oImg && !oImg.trydefault)
	{
		try
		{
			oImg.src=sDefault;
			if(typeof g_sStorePrefix != "undefined")
			{
				oImg.onerror=function()
				{
					this.src=g_sStorePrefix+"/images/transparent.gif";
				};
			}
		}
		catch(e){}
		oImg.trydefault=true;
	}
}

//function to get cross-browser xmlhttprequest
function initXMLHttpClient()
{
	var xmlhttp;
	try
	{
		xmlhttp=new XMLHttpRequest();
		return xmlhttp;
	}
	catch(e)
	{
		var arrSignatures=['MSXML2.XMLHTTP.3.0','MSXML2.XMLHTTP','Microsoft.XMLHTTP'];
		for (var i=0,iMax=arrSignatures.length;i<iMax;i++)
		{
			try
			{
				xmlhttp=new ActiveXObject(arrSignatures[i]);
				return xmlhttp;
			}
			catch (oError)
			{
			}
		}
		throw new Error("Could not create XMLHttpObject on this system.");
	}
	return xmlhttp;
}

//Gets a request parameter from a url
//Deprecated, use gup below as in new scripts.
function getRequestParameter(url,name){return gup(name,url);}

function gup(name,url)
{
	name=name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS="[\\?&]"+name+"=([^&#]*)";
	var regex=new RegExp( regexS );
	var results=regex.exec(url?url:window.location.href);
	if(results==null) return null;
	else return results[1];
}

function addRequestParameter(sURL,sName,sValue)
{
	if(sURL && sName && sValue)
	{
		var r=new RegExp("\\?");
		if(r.test(sURL))
		{
			r=new RegExp("\\?.+");
			if(r.test(sURL)) return sURL+"&"+sName+"="+encodeURIComponent(sValue);
			else return sURL+sName+"="+encodeURIComponent(sValue);
		}
		else return sURL+"?"+sName+"="+encodeURIComponent(sValue);
	}
	return sURL;
}

//Dynamically attach an external javascript file to the page
function dynamicScriptLoad(jsurl)
{
	try
	{
		var s=document.createElement("script");
		s.src=jsurl;
		s.type="text/javascript";
		document.getElementsByTagName("head")[0].appendChild(s);
	}
	catch(e){}
}

//Quantcast function
function qs()
{
	if(typeof window.quantserve=="function")
	{
		window.quantserve=function(){
			if((typeof _qacct =="undefined")||(_qacct.length==0))return;
			if((typeof _qpixelsent !="undefined")&&(_qpixelsent==_qacct))return;
			_qpixelsent=_qacct;
			var r=_qcrnd();
			var ce=(navigator.cookieEnabled)?"1":"0";
			var sr='',qo='',qm='',url='',ref='',je='u',ns='1';
			if(typeof navigator.javaEnabled !='undefined')je=(navigator.javaEnabled())?"1":"0";
			if(typeof _qoptions !="undefined" && _qoptions!=null){for(var k in _qoptions){if(typeof(_qoptions[k])!='string')continue;qo+=';'+k+'='+_qceuc(_qoptions[k]);}_qoptions=null;}
			if(typeof _qmeta !="undefined" && _qmeta!=null){qm=';m='+_qceuc(_qmeta);_qmeta=null;}
			if(self.screen){sr=screen.width+"x"+screen.height+"x"+screen.colorDepth;}
			var d=new Date();
			var dst=_qcdst();
			var dc=_qcgc("__qca");
			var qs="http://pixel.quantserve.com";
			var fp=_qcsc(dc);
			if(window.location && window.location.href)url=_qceuc(window.location.href);
			if(window.document && window.document.referrer)ref=_qceuc("http://www.blinkx.com/?ord="+document.ord);
			/*if(self==top)*/ns='0';
			var img=new Image(1,1);
			img.alt="";
			img.src=qs+'/pixel'+';r='+r+fp+';ns='+ns+';url='+url+';ref='+ref+';ce='+ce+';je='+je+';sr='+sr+';dc='+dc+';dst='+dst+';et='+d.getTime()+';tzo='+d.getTimezoneOffset()+';a='+_qacct+qo+qm;
			img.onload=function() {_qvoid();}
		}
		window._qacct="p-39-CgIWq97RfU";
		window.quantserve();
	}
	else
	{
		setTimeout(qs,500);
	}
}
//Clean SearchString
function searchStringClean(s)
{
	if(countInstances(s,'"')%2>0) s=s.replace(/\x22/g,' ');
	if(countInstances(s,'(')!=countInstances(s,')')) s=s.replace(/[()]/g,' ');
	return s.replace(/^\s+|\s+$/g, "");
}

function countInstances(string,word)
{
	return string.split(word).length-1;
}

// search
function doSearch()
{
	var oInput=document.getElementById('id_searchtext');
	if(!oInput) oInput=document.getElementById('searchText');
	if(oInput)
	{
		var val=oInput.value;
		if(val.length>0)
		{
			var singleEncodeSearch=encodeURIComponent(searchStringClean(val));
			var doubleEncodeSearch=encodeURIComponent(singleEncodeSearch).replace(/\%2520/g,"+").replace(/\%253A/g,"%3A");
			window.location='http://www.blinkx.com/videos/'+doubleEncodeSearch;
		}
	}
	return false;
}

// wall search
function wallSearch()
{
	var oInput=document.getElementById('id_searchtext');
	if(!oInput) oInput=document.getElementById('searchText');
	if(oInput)
	{
		var val=oInput.value;
		if(val.length>0)
		{
			var singleEncodeSearch=encodeURIComponent(searchStringClean(val));
			window.location='http://www.blinkx.com/wall?query='+singleEncodeSearch;
		}
	}
	return false;
}

//Switching Background Advert
function setBackgroundAd(image,url,impressionUrl)
{
	var oBodyContainer=document.getElementById("bodyContainer");
	if(oBodyContainer)
	{
		//add cachbuster to url an impressionurl
		if(!getRequestParameter(url,"nocache"))
		{
			url=addRequestParameter(url,"nocache",parseInt(Math.random()*10000000));
		}
		if(!getRequestParameter(impressionUrl,"nocache"))
		{
			impressionUrl=addRequestParameter(impressionUrl,"nocache",parseInt(Math.random()*10000000));
		}

		//Leaves ImpressionURL
		if(impressionUrl && impressionUrl.length) leaveImpression(impressionUrl);

		//Sets the Image
		oBodyContainer.style.backgroundAttachment="fixed";
		oBodyContainer.style.backgroundImage="url("+image+")";

		//Handles clicks on backgrounds container only
		EventUtil.addEventHandler(document.body,"click",function(e)
		{
			if(!e) var e=window.event;
			if(e)
			{
				var target=(e.target)?e.target:e.srcElement;
				if(target==document.body || (target.id && target.id=="bodyContainer"))
				{
					try{blinkx_Stop();}catch(ep){};
					location.href=url;
				}
			}
		});
	}

	//alert("image: "+image+"\nurl: "+url+"\nimpressionurl: "+impressionUrl);
}

//Switching Background Advert for multiple impressions
function setBackgroundAdMultipleImp(image,url,aImpressionURLs)
{
	var oBodyContainer=document.getElementById("bodyContainer");
	if(oBodyContainer)
	{
		//add cachbuster to url an impressionurl
		if(!getRequestParameter(url,"nocache"))
		{
			url=addRequestParameter(url,"nocache",parseInt(Math.random()*10000000));
		}

		//Leaves ImpressionURLs from array if present, otherwise, use single impressionURL
		if(aImpressionURLs && aImpressionURLs.length && aImpressionURLs.length>0)
		{
			var impURL,i;
			for(i=0,iMax=aImpressionURLs.length;i<iMax;i++)
			{
				impURL=aImpressionURLs[i];
				if(!getRequestParameter(impURL,"nocache"))
				{
					impURL=addRequestParameter(impURL,"nocache",parseInt(Math.random()*10000000));
				}
				if(impURL) leaveImpression(impURL);
			}
		}

		//Sets the Image
		oBodyContainer.style.backgroundAttachment="fixed";
		oBodyContainer.style.backgroundImage="url("+image+")";

		//Handles clicks on backgrounds container only
		EventUtil.addEventHandler(document.body,"click",function(e)
		{
			if(!e) var e=window.event;
			if(e)
			{
				var target=(e.target)?e.target:e.srcElement;
				if(target==document.body || (target.id && target.id=="bodyContainer"))
				{
					try{blinkx_Stop();}catch(ep){};
					location.href=url;
				}
			}
		});
	}

	//alert("image: "+image+"\nurl: "+url+"\nimpressionurl: "+impressionUrl);
}

function lightning_sendBanner(bannerSrc, bannerClickURL,height)
{
	if(typeof handleLightningSendBanner == "function")
	{
		lightning_advertEnded();
		handleLightningSendBanner(bannerSrc, bannerClickURL,height);
	}
}

function lightning_advertEnded()
{
	if(typeof handleLightningAdvertEnded == "function")
	{
		handleLightningAdvertEnded();
	}
}

//Logs an impression URL
function leaveImpression(sURL)
{
	try
	{
		var oImg=document.getElementById("impressionURL");
		if(oImg) oImg.parentNode.removeChild(oImg);

		oImg=document.createElement("img");
		oImg.style.display="none";

		oImg.width="1";
		oImg.height="1";
		oImg.src=sURL;

		document.body.appendChild(oImg);
	}
	catch(e){}
}

function logAdError(oImg)
{
	if(oImg)
	{
		var src=oImg.src;
		var page=location.href;
		var ua=navigator.userAgent;
		leaveImpression('http://www.blinkx.com/frameadlog?bannerSrc='+encodeURIComponent(src)+'&page='+encodeURIComponent(page)+'&ua='+encodeURIComponent(ua));
	}
}
/**
 * copyright 2008 blinkx inc.
 */
function rewriteUrl() {
	var oSearch=document.getElementById('searchText');
	if(oSearch)
	{
		var val=oSearch.value;
		if(val.length)
		{
			if(typeof g_sSearchDatabaseMatch!="undefined")
			{
				val="channel:"+g_sSearchDatabaseMatch+" "+val;
			}
			window.location='http://www.blinkx.com/videos/'+encodeURIComponent(encodeURIComponent(val));
		}
	}
	return false;
}

// search
EventUtil.addEventHandler(window,"load",function(){EventUtil.addEventHandler(document.getElementById('searchForm'), 'submit', function(){return rewriteUrl();})});//MooTools, My Object Oriented Javascript Tools. Copyright (c) 2006-2007 Valerio Proietti, <http://mad4milk.net>, MIT Style License.

var MooTools={version:"1.11"};function $defined(A){return(A!=undefined);}function $type(B){if(!$defined(B)){return false;}if(B.htmlElement){return"element";
}var A=typeof B;if(A=="object"&&B.nodeName){switch(B.nodeType){case 1:return"element";case 3:return(/\S/).test(B.nodeValue)?"textnode":"whitespace";}}if(A=="object"||A=="function"){switch(B.constructor){case Array:return"array";
case RegExp:return"regexp";case Class:return"class";}if(typeof B.length=="number"){if(B.item){return"collection";}if(B.callee){return"arguments";}}}return A;
}function $merge(){var C={};for(var B=0;B<arguments.length;B++){for(var E in arguments[B]){var A=arguments[B][E];var D=C[E];if(D&&$type(A)=="object"&&$type(D)=="object"){C[E]=$merge(D,A);
}else{C[E]=A;}}}return C;}var $extend=function(){var A=arguments;if(!A[1]){A=[this,A[0]];}for(var B in A[1]){A[0][B]=A[1][B];}return A[0];};var $native=function(){for(var B=0,A=arguments.length;
B<A;B++){arguments[B].extend=function(C){for(var D in C){if(!this.prototype[D]){this.prototype[D]=C[D];}if(!this[D]){this[D]=$native.generic(D);}}};}};
$native.generic=function(A){return function(B){return this.prototype[A].apply(B,Array.prototype.slice.call(arguments,1));};};$native(Function,Array,String,Number);
function $chk(A){return !!(A||A===0);}function $pick(B,A){return $defined(B)?B:A;}function $random(B,A){return Math.floor(Math.random()*(A-B+1)+B);}function $time(){return new Date().getTime();
}function $clear(A){clearTimeout(A);clearInterval(A);return null;}var Abstract=function(A){A=A||{};A.extend=$extend;return A;};var Window=new Abstract(window);
var Document=new Abstract(document);document.head=document.getElementsByTagName("head")[0];window.xpath=!!(document.evaluate);if(window.ActiveXObject){window.ie=window[window.XMLHttpRequest?"ie7":"ie6"]=true;
}else{if(document.childNodes&&!document.all&&!navigator.taintEnabled){window.webkit=window[window.xpath?"webkit420":"webkit419"]=true;}else{if(document.getBoxObjectFor!=null){window.gecko=true;
}}}window.khtml=window.webkit;Object.extend=$extend;if(typeof HTMLElement=="undefined"){var HTMLElement=function(){};if(window.webkit){document.createElement("iframe");
}HTMLElement.prototype=(window.webkit)?window["[[DOMElement.prototype]]"]:{};}HTMLElement.prototype.htmlElement=function(){};if(window.ie6){try{document.execCommand("BackgroundImageCache",false,true);
}catch(e){}}var Class=function(B){var A=function(){return(arguments[0]!==null&&this.initialize&&$type(this.initialize)=="function")?this.initialize.apply(this,arguments):this;
};$extend(A,this);A.prototype=B;A.constructor=Class;return A;};Class.empty=function(){};Class.prototype={extend:function(B){var C=new this(null);for(var D in B){var A=C[D];
C[D]=Class.Merge(A,B[D]);}return new Class(C);},implement:function(){for(var B=0,A=arguments.length;B<A;B++){$extend(this.prototype,arguments[B]);}}};Class.Merge=function(C,D){if(C&&C!=D){var B=$type(D);
if(B!=$type(C)){return D;}switch(B){case"function":var A=function(){this.parent=arguments.callee.parent;return D.apply(this,arguments);};A.parent=C;return A;
case"object":return $merge(C,D);}}return D;};var Chain=new Class({chain:function(A){this.chains=this.chains||[];this.chains.push(A);return this;},callChain:function(){if(this.chains&&this.chains.length){this.chains.shift().delay(10,this);
}},clearChain:function(){this.chains=[];}});var Events=new Class({addEvent:function(B,A){if(A!=Class.empty){this.$events=this.$events||{};this.$events[B]=this.$events[B]||[];
this.$events[B].include(A);}return this;},fireEvent:function(C,B,A){if(this.$events&&this.$events[C]){this.$events[C].each(function(D){D.create({bind:this,delay:A,"arguments":B})();
},this);}return this;},removeEvent:function(B,A){if(this.$events&&this.$events[B]){this.$events[B].remove(A);}return this;}});var Options=new Class({setOptions:function(){this.options=$merge.apply(null,[this.options].extend(arguments));
if(this.addEvent){for(var A in this.options){if($type(this.options[A]=="function")&&(/^on[A-Z]/).test(A)){this.addEvent(A,this.options[A]);}}}return this;
}});Array.extend({forEach:function(C,D){for(var B=0,A=this.length;B<A;B++){C.call(D,this[B],B,this);}},filter:function(D,E){var C=[];for(var B=0,A=this.length;
B<A;B++){if(D.call(E,this[B],B,this)){C.push(this[B]);}}return C;},map:function(D,E){var C=[];for(var B=0,A=this.length;B<A;B++){C[B]=D.call(E,this[B],B,this);
}return C;},every:function(C,D){for(var B=0,A=this.length;B<A;B++){if(!C.call(D,this[B],B,this)){return false;}}return true;},some:function(C,D){for(var B=0,A=this.length;
B<A;B++){if(C.call(D,this[B],B,this)){return true;}}return false;},indexOf:function(C,D){var A=this.length;for(var B=(D<0)?Math.max(0,A+D):D||0;B<A;B++){if(this[B]===C){return B;
}}return -1;},copy:function(D,C){D=D||0;if(D<0){D=this.length+D;}C=C||(this.length-D);var A=[];for(var B=0;B<C;B++){A[B]=this[D++];}return A;},remove:function(C){var B=0;
var A=this.length;while(B<A){if(this[B]===C){this.splice(B,1);A--;}else{B++;}}return this;},contains:function(A,B){return this.indexOf(A,B)!=-1;},associate:function(C){var D={},B=Math.min(this.length,C.length);
for(var A=0;A<B;A++){D[C[A]]=this[A];}return D;},extend:function(C){for(var B=0,A=C.length;B<A;B++){this.push(C[B]);}return this;},merge:function(C){for(var B=0,A=C.length;
B<A;B++){this.include(C[B]);}return this;},include:function(A){if(!this.contains(A)){this.push(A);}return this;},getRandom:function(){return this[$random(0,this.length-1)]||null;
},getLast:function(){return this[this.length-1]||null;}});Array.prototype.each=Array.prototype.forEach;Array.each=Array.forEach;function $A(A){return Array.copy(A);
}function $each(C,B,D){if(C&&typeof C.length=="number"&&$type(C)!="object"){Array.forEach(C,B,D);}else{for(var A in C){B.call(D||C,C[A],A);}}}Array.prototype.test=Array.prototype.contains;
String.extend({test:function(A,B){return(($type(A)=="string")?new RegExp(A,B):A).test(this);},toInt:function(){return parseInt(this,10);},toFloat:function(){return parseFloat(this);
},camelCase:function(){return this.replace(/-\D/g,function(A){return A.charAt(1).toUpperCase();});},hyphenate:function(){return this.replace(/\w[A-Z]/g,function(A){return(A.charAt(0)+"-"+A.charAt(1).toLowerCase());
});},capitalize:function(){return this.replace(/\b[a-z]/g,function(A){return A.toUpperCase();});},trim:function(){return this.replace(/^\s+|\s+$/g,"");
},clean:function(){return this.replace(/\s{2,}/g," ").trim();},rgbToHex:function(B){var A=this.match(/\d{1,3}/g);return(A)?A.rgbToHex(B):false;},hexToRgb:function(B){var A=this.match(/^#?(\w{1,2})(\w{1,2})(\w{1,2})$/);
return(A)?A.slice(1).hexToRgb(B):false;},contains:function(A,B){return(B)?(B+this+B).indexOf(B+A+B)>-1:this.indexOf(A)>-1;},escapeRegExp:function(){return this.replace(/([.*+?^${}()|[\]\/\\])/g,"\\$1");
}});Array.extend({rgbToHex:function(D){if(this.length<3){return false;}if(this.length==4&&this[3]==0&&!D){return"transparent";}var B=[];for(var A=0;A<3;
A++){var C=(this[A]-0).toString(16);B.push((C.length==1)?"0"+C:C);}return D?B:"#"+B.join("");},hexToRgb:function(C){if(this.length!=3){return false;}var A=[];
for(var B=0;B<3;B++){A.push(parseInt((this[B].length==1)?this[B]+this[B]:this[B],16));}return C?A:"rgb("+A.join(",")+")";}});Function.extend({create:function(A){var B=this;
A=$merge({bind:B,event:false,"arguments":null,delay:false,periodical:false,attempt:false},A);if($chk(A.arguments)&&$type(A.arguments)!="array"){A.arguments=[A.arguments];
}return function(E){var C;if(A.event){E=E||window.event;C=[(A.event===true)?E:new A.event(E)];if(A.arguments){C.extend(A.arguments);}}else{C=A.arguments||arguments;
}var F=function(){return B.apply($pick(A.bind,B),C);};if(A.delay){return setTimeout(F,A.delay);}if(A.periodical){return setInterval(F,A.periodical);}if(A.attempt){try{return F();
}catch(D){return false;}}return F();};},pass:function(A,B){return this.create({"arguments":A,bind:B});},attempt:function(A,B){return this.create({"arguments":A,bind:B,attempt:true})();
},bind:function(B,A){return this.create({bind:B,"arguments":A});},bindAsEventListener:function(B,A){return this.create({bind:B,event:true,"arguments":A});
},delay:function(B,C,A){return this.create({delay:B,bind:C,"arguments":A})();},periodical:function(A,C,B){return this.create({periodical:A,bind:C,"arguments":B})();
}});Number.extend({toInt:function(){return parseInt(this);},toFloat:function(){return parseFloat(this);},limit:function(B,A){return Math.min(A,Math.max(B,this));
},round:function(A){A=Math.pow(10,A||0);return Math.round(this*A)/A;},times:function(B){for(var A=0;A<this;A++){B(A);}}});var Element=new Class({initialize:function(D,C){if($type(D)=="string"){if(window.ie&&C&&(C.name||C.type)){var A=(C.name)?' name="'+C.name+'"':"";
var B=(C.type)?' type="'+C.type+'"':"";delete C.name;delete C.type;D="<"+D+A+B+">";}D=document.createElement(D);}D=$(D);return(!C||!D)?D:D.set(C);}});var Elements=new Class({initialize:function(A){return(A)?$extend(A,this):this;
}});Elements.extend=function(A){for(var B in A){this.prototype[B]=A[B];this[B]=$native.generic(B);}};function $(B){if(!B){return null;}if(B.htmlElement){return Garbage.collect(B);
}if([window,document].contains(B)){return B;}var A=$type(B);if(A=="string"){B=document.getElementById(B);A=(B)?"element":false;}if(A!="element"){return null;
}if(B.htmlElement){return Garbage.collect(B);}if(["object","embed"].contains(B.tagName.toLowerCase())){return B;}$extend(B,Element.prototype);B.htmlElement=function(){};
return Garbage.collect(B);}document.getElementsBySelector=document.getElementsByTagName;function $$(){var D=[];for(var C=0,B=arguments.length;C<B;C++){var A=arguments[C];
switch($type(A)){case"element":D.push(A);case"boolean":break;case false:break;case"string":A=document.getElementsBySelector(A,true);default:D.extend(A);
}}return $$.unique(D);}$$.unique=function(G){var D=[];for(var C=0,A=G.length;C<A;C++){if(G[C].$included){continue;}var B=$(G[C]);if(B&&!B.$included){B.$included=true;
D.push(B);}}for(var F=0,E=D.length;F<E;F++){D[F].$included=null;}return new Elements(D);};Elements.Multi=function(A){return function(){var D=arguments;
var B=[];var G=true;for(var E=0,C=this.length,F;E<C;E++){F=this[E][A].apply(this[E],D);if($type(F)!="element"){G=false;}B.push(F);}return(G)?$$.unique(B):B;
};};Element.extend=function(A){for(var B in A){HTMLElement.prototype[B]=A[B];Element.prototype[B]=A[B];Element[B]=$native.generic(B);var C=(Array.prototype[B])?B+"Elements":B;
Elements.prototype[C]=Elements.Multi(B);}};Element.extend({set:function(A){for(var C in A){var B=A[C];switch(C){case"styles":this.setStyles(B);break;case"events":if(this.addEvents){this.addEvents(B);
}break;case"properties":this.setProperties(B);break;default:this.setProperty(C,B);}}return this;},inject:function(C,A){C=$(C);switch(A){case"before":C.parentNode.insertBefore(this,C);
break;case"after":var B=C.getNext();if(!B){C.parentNode.appendChild(this);}else{C.parentNode.insertBefore(this,B);}break;case"top":var D=C.firstChild;if(D){C.insertBefore(this,D);
break;}default:C.appendChild(this);}return this;},injectBefore:function(A){return this.inject(A,"before");},injectAfter:function(A){return this.inject(A,"after");
},injectInside:function(A){return this.inject(A,"bottom");},injectTop:function(A){return this.inject(A,"top");},adopt:function(){var A=[];$each(arguments,function(B){A=A.concat(B);
});$$(A).inject(this);return this;},remove:function(){return this.parentNode.removeChild(this);},clone:function(C){var B=$(this.cloneNode(C!==false));if(!B.$events){return B;
}B.$events={};for(var A in this.$events){B.$events[A]={keys:$A(this.$events[A].keys),values:$A(this.$events[A].values)};}return B.removeEvents();},replaceWith:function(A){A=$(A);
this.parentNode.replaceChild(A,this);return A;},appendText:function(A){this.appendChild(document.createTextNode(A));return this;},hasClass:function(A){return this.className.contains(A," ");
},addClass:function(A){if(!this.hasClass(A)){this.className=(this.className+" "+A).clean();}return this;},removeClass:function(A){this.className=this.className.replace(new RegExp("(^|\\s)"+A+"(?:\\s|$)"),"$1").clean();
return this;},toggleClass:function(A){return this.hasClass(A)?this.removeClass(A):this.addClass(A);},setStyle:function(B,A){switch(B){case"opacity":return this.setOpacity(parseFloat(A));
case"float":B=(window.ie)?"styleFloat":"cssFloat";}B=B.camelCase();switch($type(A)){case"number":if(!["zIndex","zoom"].contains(B)){A+="px";}break;case"array":A="rgb("+A.join(",")+")";
}this.style[B]=A;return this;},setStyles:function(A){switch($type(A)){case"object":Element.setMany(this,"setStyle",A);break;case"string":this.style.cssText=A;
}return this;},setOpacity:function(A){if(A==0){if(this.style.visibility!="hidden"){this.style.visibility="hidden";}}else{if(this.style.visibility!="visible"){this.style.visibility="visible";
}}if(!this.currentStyle||!this.currentStyle.hasLayout){this.style.zoom=1;}if(window.ie){this.style.filter=(A==1)?"":"alpha(opacity="+A*100+")";}this.style.opacity=this.$tmp.opacity=A;
return this;},getStyle:function(C){C=C.camelCase();var A=this.style[C];if(!$chk(A)){if(C=="opacity"){return this.$tmp.opacity;}A=[];for(var B in Element.Styles){if(C==B){Element.Styles[B].each(function(F){var E=this.getStyle(F);
A.push(parseInt(E)?E:"0px");},this);if(C=="border"){var D=A.every(function(E){return(E==A[0]);});return(D)?A[0]:false;}return A.join(" ");}}if(C.contains("border")){if(Element.Styles.border.contains(C)){return["Width","Style","Color"].map(function(E){return this.getStyle(C+E);
},this).join(" ");}else{if(Element.borderShort.contains(C)){return["Top","Right","Bottom","Left"].map(function(E){return this.getStyle("border"+E+C.replace("border",""));
},this).join(" ");}}}if(document.defaultView){A=document.defaultView.getComputedStyle(this,null).getPropertyValue(C.hyphenate());}else{if(this.currentStyle){A=this.currentStyle[C];
}}}if(window.ie){A=Element.fixStyle(C,A,this);}if(A&&C.test(/color/i)&&A.contains("rgb")){return A.split("rgb").splice(1,4).map(function(E){return E.rgbToHex();
}).join(" ");}return A;},getStyles:function(){return Element.getMany(this,"getStyle",arguments);},walk:function(A,C){A+="Sibling";var B=(C)?this[C]:this[A];
while(B&&$type(B)!="element"){B=B[A];}return $(B);},getPrevious:function(){return this.walk("previous");},getNext:function(){return this.walk("next");},getFirst:function(){return this.walk("next","firstChild");
},getLast:function(){return this.walk("previous","lastChild");},getParent:function(){return $(this.parentNode);},getChildren:function(){return $$(this.childNodes);
},hasChild:function(A){return !!$A(this.getElementsByTagName("*")).contains(A);},getProperty:function(D){var B=Element.Properties[D];if(B){return this[B];
}var A=Element.PropertiesIFlag[D]||0;if(!window.ie||A){return this.getAttribute(D,A);}var C=this.attributes[D];return(C)?C.nodeValue:null;},removeProperty:function(B){var A=Element.Properties[B];
if(A){this[A]="";}else{this.removeAttribute(B);}return this;},getProperties:function(){return Element.getMany(this,"getProperty",arguments);},setProperty:function(C,B){var A=Element.Properties[C];
if(A){this[A]=B;}else{this.setAttribute(C,B);}return this;},setProperties:function(A){return Element.setMany(this,"setProperty",A);},setHTML:function(){this.innerHTML=$A(arguments).join("");
return this;},setText:function(B){var A=this.getTag();if(["style","script"].contains(A)){if(window.ie){if(A=="style"){this.styleSheet.cssText=B;}else{if(A=="script"){this.setProperty("text",B);
}}return this;}else{this.removeChild(this.firstChild);return this.appendText(B);}}this[$defined(this.innerText)?"innerText":"textContent"]=B;return this;
},getText:function(){var A=this.getTag();if(["style","script"].contains(A)){if(window.ie){if(A=="style"){return this.styleSheet.cssText;}else{if(A=="script"){return this.getProperty("text");
}}}else{return this.innerHTML;}}return($pick(this.innerText,this.textContent));},getTag:function(){return this.tagName.toLowerCase();},empty:function(){Garbage.trash(this.getElementsByTagName("*"));
return this.setHTML("");}});Element.fixStyle=function(E,A,D){if($chk(parseInt(A))){return A;}if(["height","width"].contains(E)){var B=(E=="width")?["left","right"]:["top","bottom"];
var C=0;B.each(function(F){C+=D.getStyle("border-"+F+"-width").toInt()+D.getStyle("padding-"+F).toInt();});return D["offset"+E.capitalize()]-C+"px";}else{if(E.test(/border(.+)Width|margin|padding/)){return"0px";
}}return A;};Element.Styles={border:[],padding:[],margin:[]};["Top","Right","Bottom","Left"].each(function(B){for(var A in Element.Styles){Element.Styles[A].push(A+B);
}});Element.borderShort=["borderWidth","borderStyle","borderColor"];Element.getMany=function(B,D,C){var A={};$each(C,function(E){A[E]=B[D](E);});return A;
};Element.setMany=function(B,D,C){for(var A in C){B[D](A,C[A]);}return B;};Element.Properties=new Abstract({"class":"className","for":"htmlFor",colspan:"colSpan",rowspan:"rowSpan",accesskey:"accessKey",tabindex:"tabIndex",maxlength:"maxLength",readonly:"readOnly",frameborder:"frameBorder",value:"value",disabled:"disabled",checked:"checked",multiple:"multiple",selected:"selected"});
Element.PropertiesIFlag={href:2,src:2};Element.Methods={Listeners:{addListener:function(B,A){if(this.addEventListener){this.addEventListener(B,A,false);
}else{this.attachEvent("on"+B,A);}return this;},removeListener:function(B,A){if(this.removeEventListener){this.removeEventListener(B,A,false);}else{this.detachEvent("on"+B,A);
}return this;}}};window.extend(Element.Methods.Listeners);document.extend(Element.Methods.Listeners);Element.extend(Element.Methods.Listeners);var Garbage={elements:[],collect:function(A){if(!A.$tmp){Garbage.elements.push(A);
A.$tmp={opacity:1};}return A;},trash:function(D){for(var B=0,A=D.length,C;B<A;B++){if(!(C=D[B])||!C.$tmp){continue;}if(C.$events){C.fireEvent("trash").removeEvents();
}for(var E in C.$tmp){C.$tmp[E]=null;}for(var F in Element.prototype){C[F]=null;}Garbage.elements[Garbage.elements.indexOf(C)]=null;C.htmlElement=C.$tmp=C=null;
}Garbage.elements.remove(null);},empty:function(){Garbage.collect(window);Garbage.collect(document);Garbage.trash(Garbage.elements);}};/*window.addListener("beforeunload",function(){window.addListener("unload",Garbage.empty);
if(window.ie){window.addListener("unload",CollectGarbage);}});*/var Event=new Class({initialize:function(C){if(C&&C.$extended){return C;}this.$extended=true;
C=C||window.event;this.event=C;this.type=C.type;this.target=C.target||C.srcElement;if(this.target.nodeType==3){this.target=this.target.parentNode;}this.shift=C.shiftKey;
this.control=C.ctrlKey;this.alt=C.altKey;this.meta=C.metaKey;if(["DOMMouseScroll","mousewheel"].contains(this.type)){this.wheel=(C.wheelDelta)?C.wheelDelta/120:-(C.detail||0)/3;
}else{if(this.type.contains("key")){this.code=C.which||C.keyCode;for(var B in Event.keys){if(Event.keys[B]==this.code){this.key=B;break;}}if(this.type=="keydown"){var A=this.code-111;
if(A>0&&A<13){this.key="f"+A;}}this.key=this.key||String.fromCharCode(this.code).toLowerCase();}else{if(this.type.test(/(click|mouse|menu)/)){this.page={x:C.pageX||C.clientX+document.documentElement.scrollLeft,y:C.pageY||C.clientY+document.documentElement.scrollTop};
this.client={x:C.pageX?C.pageX-window.pageXOffset:C.clientX,y:C.pageY?C.pageY-window.pageYOffset:C.clientY};this.rightClick=(C.which==3)||(C.button==2);
switch(this.type){case"mouseover":this.relatedTarget=C.relatedTarget||C.fromElement;break;case"mouseout":this.relatedTarget=C.relatedTarget||C.toElement;
}this.fixRelatedTarget();}}}return this;},stop:function(){return this.stopPropagation().preventDefault();},stopPropagation:function(){if(this.event.stopPropagation){this.event.stopPropagation();
}else{this.event.cancelBubble=true;}return this;},preventDefault:function(){if(this.event.preventDefault){this.event.preventDefault();}else{this.event.returnValue=false;
}return this;}});Event.fix={relatedTarget:function(){if(this.relatedTarget&&this.relatedTarget.nodeType==3){this.relatedTarget=this.relatedTarget.parentNode;
}},relatedTargetGecko:function(){try{Event.fix.relatedTarget.call(this);}catch(A){this.relatedTarget=this.target;}}};Event.prototype.fixRelatedTarget=(window.gecko)?Event.fix.relatedTargetGecko:Event.fix.relatedTarget;
Event.keys=new Abstract({enter:13,up:38,down:40,left:37,right:39,esc:27,space:32,backspace:8,tab:9,"delete":46});Element.Methods.Events={addEvent:function(C,B){this.$events=this.$events||{};
this.$events[C]=this.$events[C]||{keys:[],values:[]};if(this.$events[C].keys.contains(B)){return this;}this.$events[C].keys.push(B);var A=C;var D=Element.Events[C];
if(D){if(D.add){D.add.call(this,B);}if(D.map){B=D.map;}if(D.type){A=D.type;}}if(!this.addEventListener){B=B.create({bind:this,event:true});}this.$events[C].values.push(B);
return(Element.NativeEvents.contains(A))?this.addListener(A,B):this;},removeEvent:function(C,B){if(!this.$events||!this.$events[C]){return this;}var F=this.$events[C].keys.indexOf(B);
if(F==-1){return this;}var A=this.$events[C].keys.splice(F,1)[0];var E=this.$events[C].values.splice(F,1)[0];var D=Element.Events[C];if(D){if(D.remove){D.remove.call(this,B);
}if(D.type){C=D.type;}}return(Element.NativeEvents.contains(C))?this.removeListener(C,E):this;},addEvents:function(A){return Element.setMany(this,"addEvent",A);
},removeEvents:function(A){if(!this.$events){return this;}if(!A){for(var B in this.$events){this.removeEvents(B);}this.$events=null;}else{if(this.$events[A]){this.$events[A].keys.each(function(C){this.removeEvent(A,C);
},this);this.$events[A]=null;}}return this;},fireEvent:function(C,B,A){if(this.$events&&this.$events[C]){this.$events[C].keys.each(function(D){D.create({bind:this,delay:A,"arguments":B})();
},this);}return this;},cloneEvents:function(C,A){if(!C.$events){return this;}if(!A){for(var B in C.$events){this.cloneEvents(C,B);}}else{if(C.$events[A]){C.$events[A].keys.each(function(D){this.addEvent(A,D);
},this);}}return this;}};window.extend(Element.Methods.Events);document.extend(Element.Methods.Events);Element.extend(Element.Methods.Events);Element.Events=new Abstract({mouseenter:{type:"mouseover",map:function(A){A=new Event(A);
if(A.relatedTarget!=this&&!this.hasChild(A.relatedTarget)){this.fireEvent("mouseenter",A);}}},mouseleave:{type:"mouseout",map:function(A){A=new Event(A);
if(A.relatedTarget!=this&&!this.hasChild(A.relatedTarget)){this.fireEvent("mouseleave",A);}}},mousewheel:{type:(window.gecko)?"DOMMouseScroll":"mousewheel"}});
Element.NativeEvents=["click","dblclick","mouseup","mousedown","mousewheel","DOMMouseScroll","mouseover","mouseout","mousemove","keydown","keypress","keyup","load","unload","beforeunload","resize","move","focus","blur","change","submit","reset","select","error","abort","contextmenu","scroll"];
Function.extend({bindWithEvent:function(B,A){return this.create({bind:B,"arguments":A,event:Event});}});Elements.extend({filterByTag:function(A){return new Elements(this.filter(function(B){return(Element.getTag(B)==A);
}));},filterByClass:function(A,C){var B=this.filter(function(D){return(D.className&&D.className.contains(A," "));});return(C)?B:new Elements(B);},filterById:function(C,B){var A=this.filter(function(D){return(D.id==C);
});return(B)?A:new Elements(A);},filterByAttribute:function(B,A,D,E){var C=this.filter(function(F){var G=Element.getProperty(F,B);if(!G){return false;}if(!A){return true;
}switch(A){case"=":return(G==D);case"*=":return(G.contains(D));case"^=":return(G.substr(0,D.length)==D);case"$=":return(G.substr(G.length-D.length)==D);
case"!=":return(G!=D);case"~=":return G.contains(D," ");}return false;});return(E)?C:new Elements(C);}});function $E(A,B){return($(B)||document).getElement(A);
}function $ES(A,B){return($(B)||document).getElementsBySelector(A);}$$.shared={regexp:/^(\w*|\*)(?:#([\w-]+)|\.([\w-]+))?(?:\[(\w+)(?:([!*^$]?=)["']?([^"'\]]*)["']?)?])?$/,xpath:{getParam:function(B,D,E,C){var A=[D.namespaceURI?"xhtml:":"",E[1]];
if(E[2]){A.push('[@id="',E[2],'"]');}if(E[3]){A.push('[contains(concat(" ", @class, " "), " ',E[3],' ")]');}if(E[4]){if(E[5]&&E[6]){switch(E[5]){case"*=":A.push("[contains(@",E[4],', "',E[6],'")]');
break;case"^=":A.push("[starts-with(@",E[4],', "',E[6],'")]');break;case"$=":A.push("[substring(@",E[4],", string-length(@",E[4],") - ",E[6].length,' + 1) = "',E[6],'"]');
break;case"=":A.push("[@",E[4],'="',E[6],'"]');break;case"!=":A.push("[@",E[4],'!="',E[6],'"]');}}else{A.push("[@",E[4],"]");}}B.push(A.join(""));return B;
},getItems:function(B,E,G){var F=[];var A=document.evaluate(".//"+B.join("//"),E,$$.shared.resolver,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,null);for(var D=0,C=A.snapshotLength;
D<C;D++){F.push(A.snapshotItem(D));}return(G)?F:new Elements(F.map($));}},normal:{getParam:function(A,C,E,B){if(B==0){if(E[2]){var D=C.getElementById(E[2]);
if(!D||((E[1]!="*")&&(Element.getTag(D)!=E[1]))){return false;}A=[D];}else{A=$A(C.getElementsByTagName(E[1]));}}else{A=$$.shared.getElementsByTagName(A,E[1]);
if(E[2]){A=Elements.filterById(A,E[2],true);}}if(E[3]){A=Elements.filterByClass(A,E[3],true);}if(E[4]){A=Elements.filterByAttribute(A,E[4],E[5],E[6],true);
}return A;},getItems:function(A,B,C){return(C)?A:$$.unique(A);}},resolver:function(A){return(A=="xhtml")?"http://www.w3.org/1999/xhtml":false;},getElementsByTagName:function(D,C){var E=[];
for(var B=0,A=D.length;B<A;B++){E.extend(D[B].getElementsByTagName(C));}return E;}};$$.shared.method=(window.xpath)?"xpath":"normal";Element.Methods.Dom={getElements:function(A,H){var C=[];
A=A.trim().split(" ");for(var E=0,D=A.length;E<D;E++){var F=A[E];var G=F.match($$.shared.regexp);if(!G){break;}G[1]=G[1]||"*";var B=$$.shared[$$.shared.method].getParam(C,this,G,E);
if(!B){break;}C=B;}return $$.shared[$$.shared.method].getItems(C,this,H);},getElement:function(A){return $(this.getElements(A,true)[0]||false);},getElementsBySelector:function(A,E){var D=[];
A=A.split(",");for(var C=0,B=A.length;C<B;C++){D=D.concat(this.getElements(A[C],true));}return(E)?D:$$.unique(D);}};Element.extend({getElementById:function(C){var B=document.getElementById(C);
if(!B){return false;}for(var A=B.parentNode;A!=this;A=A.parentNode){if(!A){return false;}}return B;},getElementsByClassName:function(A){return this.getElements("."+A);
}});document.extend(Element.Methods.Dom);Element.extend(Element.Methods.Dom);Element.extend({getValue:function(){switch(this.getTag()){case"select":var A=[];
$each(this.options,function(B){if(B.selected){A.push($pick(B.value,B.text));}});return(this.multiple)?A:A[0];case"input":if(!(this.checked&&["checkbox","radio"].contains(this.type))&&!["hidden","text","password"].contains(this.type)){break;
}case"textarea":return this.value;}return false;},getFormElements:function(){return $$(this.getElementsByTagName("input"),this.getElementsByTagName("select"),this.getElementsByTagName("textarea"));
},toQueryString:function(){var A=[];this.getFormElements().each(function(D){var C=D.name;var E=D.getValue();if(E===false||!C||D.disabled){return ;}var B=function(F){A.push(C+"="+encodeURIComponent(F));
};if($type(E)=="array"){E.each(B);}else{B(E);}});return A.join("&");}});Element.extend({scrollTo:function(A,B){this.scrollLeft=A;this.scrollTop=B;},getSize:function(){return{scroll:{x:this.scrollLeft,y:this.scrollTop},size:{x:this.offsetWidth,y:this.offsetHeight},scrollSize:{x:this.scrollWidth,y:this.scrollHeight}};
},getPosition:function(A){A=A||[];var B=this,D=0,C=0;do{D+=B.offsetLeft||0;C+=B.offsetTop||0;B=B.offsetParent;}while(B);A.each(function(E){D-=E.scrollLeft||0;
C-=E.scrollTop||0;});return{x:D,y:C};},getTop:function(A){return this.getPosition(A).y;},getLeft:function(A){return this.getPosition(A).x;},getCoordinates:function(B){var A=this.getPosition(B);
var C={width:this.offsetWidth,height:this.offsetHeight,left:A.x,top:A.y};C.right=C.left+C.width;C.bottom=C.top+C.height;return C;}});Element.Events.domready={add:function(B){if(window.loaded){B.call(this);
return ;}var A=function(){if(window.loaded){return ;}window.loaded=true;window.timer=$clear(window.timer);this.fireEvent("domready");}.bind(this);if(document.readyState&&window.webkit){window.timer=function(){if(["loaded","complete"].contains(document.readyState)){A();
}}.periodical(50);}else{if(document.readyState&&window.ie){if(!$("ie_ready")){var C=(window.location.protocol=="https:")?"://0":"javascript:void(0)";document.write('<script id="ie_ready" defer src="'+C+'"><\/script>');
$("ie_ready").onreadystatechange=function(){if(this.readyState=="complete"){A();}};}}else{window.addListener("load",A);document.addListener("DOMContentLoaded",A);
}}}};window.onDomReady=function(A){return this.addEvent("domready",A);};window.extend({getWidth:function(){if(this.webkit419){return this.innerWidth;}if(this.opera){return document.body.clientWidth;
}return document.documentElement.clientWidth;},getHeight:function(){if(this.webkit419){return this.innerHeight;}if(this.opera){return document.body.clientHeight;
}return document.documentElement.clientHeight;},getScrollWidth:function(){if(this.ie){return Math.max(document.documentElement.offsetWidth,document.documentElement.scrollWidth);
}if(this.webkit){return document.body.scrollWidth;}return document.documentElement.scrollWidth;},getScrollHeight:function(){if(this.ie){return Math.max(document.documentElement.offsetHeight,document.documentElement.scrollHeight);
}if(this.webkit){return document.body.scrollHeight;}return document.documentElement.scrollHeight;},getScrollLeft:function(){return this.pageXOffset||document.documentElement.scrollLeft;
},getScrollTop:function(){return this.pageYOffset||document.documentElement.scrollTop;},getSize:function(){return{size:{x:this.getWidth(),y:this.getHeight()},scrollSize:{x:this.getScrollWidth(),y:this.getScrollHeight()},scroll:{x:this.getScrollLeft(),y:this.getScrollTop()}};
},getPosition:function(){return{x:0,y:0};}});var Fx={};Fx.Base=new Class({options:{onStart:Class.empty,onComplete:Class.empty,onCancel:Class.empty,transition:function(A){return -(Math.cos(Math.PI*A)-1)/2;
},duration:500,unit:"px",wait:true,fps:50},initialize:function(A){this.element=this.element||null;this.setOptions(A);if(this.options.initialize){this.options.initialize.call(this);
}},step:function(){var A=$time();if(A<this.time+this.options.duration){this.delta=this.options.transition((A-this.time)/this.options.duration);this.setNow();
this.increase();}else{this.stop(true);this.set(this.to);this.fireEvent("onComplete",this.element,10);this.callChain();}},set:function(A){this.now=A;this.increase();
return this;},setNow:function(){this.now=this.compute(this.from,this.to);},compute:function(B,A){return(A-B)*this.delta+B;},start:function(B,A){if(!this.options.wait){this.stop();
}else{if(this.timer){return this;}}this.from=B;this.to=A;this.change=this.to-this.from;this.time=$time();this.timer=this.step.periodical(Math.round(1000/this.options.fps),this);
this.fireEvent("onStart",this.element);return this;},stop:function(A){if(!this.timer){return this;}this.timer=$clear(this.timer);if(!A){this.fireEvent("onCancel",this.element);
}return this;},custom:function(B,A){return this.start(B,A);},clearTimer:function(A){return this.stop(A);}});Fx.Base.implement(new Chain,new Events,new Options);
Fx.CSS={select:function(B,C){if(B.test(/color/i)){return this.Color;}var A=$type(C);if((A=="array")||(A=="string"&&C.contains(" "))){return this.Multi;
}return this.Single;},parse:function(C,D,A){if(!A.push){A=[A];}var F=A[0],E=A[1];if(!$chk(E)){E=F;F=C.getStyle(D);}var B=this.select(D,E);return{from:B.parse(F),to:B.parse(E),css:B};
}};Fx.CSS.Single={parse:function(A){return parseFloat(A);},getNow:function(C,B,A){return A.compute(C,B);},getValue:function(C,A,B){if(A=="px"&&B!="opacity"){C=Math.round(C);
}return C+A;}};Fx.CSS.Multi={parse:function(A){return A.push?A:A.split(" ").map(function(B){return parseFloat(B);});},getNow:function(E,D,C){var A=[];for(var B=0;
B<E.length;B++){A[B]=C.compute(E[B],D[B]);}return A;},getValue:function(C,A,B){if(A=="px"&&B!="opacity"){C=C.map(Math.round);}return C.join(A+" ")+A;}};
Fx.CSS.Color={parse:function(A){return A.push?A:A.hexToRgb(true);},getNow:function(E,D,C){var A=[];for(var B=0;B<E.length;B++){A[B]=Math.round(C.compute(E[B],D[B]));
}return A;},getValue:function(A){return"rgb("+A.join(",")+")";}};Fx.Style=Fx.Base.extend({initialize:function(B,C,A){this.element=$(B);this.property=C;
this.parent(A);},hide:function(){return this.set(0);},setNow:function(){this.now=this.css.getNow(this.from,this.to,this);},set:function(A){this.css=Fx.CSS.select(this.property,A);
return this.parent(this.css.parse(A));},start:function(C,B){if(this.timer&&this.options.wait){return this;}var A=Fx.CSS.parse(this.element,this.property,[C,B]);
this.css=A.css;return this.parent(A.from,A.to);},increase:function(){this.element.setStyle(this.property,this.css.getValue(this.now,this.options.unit,this.property));
}});Element.extend({effect:function(B,A){return new Fx.Style(this,B,A);}});Fx.Styles=Fx.Base.extend({initialize:function(B,A){this.element=$(B);this.parent(A);
},setNow:function(){for(var A in this.from){this.now[A]=this.css[A].getNow(this.from[A],this.to[A],this);}},set:function(C){var A={};this.css={};for(var B in C){this.css[B]=Fx.CSS.select(B,C[B]);
A[B]=this.css[B].parse(C[B]);}return this.parent(A);},start:function(C){if(this.timer&&this.options.wait){return this;}this.now={};this.css={};var E={},D={};
for(var B in C){var A=Fx.CSS.parse(this.element,B,C[B]);E[B]=A.from;D[B]=A.to;this.css[B]=A.css;}return this.parent(E,D);},increase:function(){for(var A in this.now){this.element.setStyle(A,this.css[A].getValue(this.now[A],this.options.unit,A));
}}});Element.extend({effects:function(A){return new Fx.Styles(this,A);}});Fx.Elements=Fx.Base.extend({initialize:function(B,A){this.elements=$$(B);this.parent(A);
},setNow:function(){for(var C in this.from){var F=this.from[C],E=this.to[C],B=this.css[C],A=this.now[C]={};for(var D in F){A[D]=B[D].getNow(F[D],E[D],this);
}}},set:function(G){var B={};this.css={};for(var D in G){var F=G[D],C=this.css[D]={},A=B[D]={};for(var E in F){C[E]=Fx.CSS.select(E,F[E]);A[E]=C[E].parse(F[E]);
}}return this.parent(B);},start:function(D){if(this.timer&&this.options.wait){return this;}this.now={};this.css={};var I={},J={};for(var E in D){var G=D[E],A=I[E]={},H=J[E]={},C=this.css[E]={};
for(var B in G){var F=Fx.CSS.parse(this.elements[E],B,G[B]);A[B]=F.from;H[B]=F.to;C[B]=F.css;}}return this.parent(I,J);},increase:function(){for(var C in this.now){var A=this.now[C],B=this.css[C];
for(var D in A){this.elements[C].setStyle(D,B[D].getValue(A[D],this.options.unit,D));}}}});Fx.Scroll=Fx.Base.extend({options:{overflown:[],offset:{x:0,y:0},wheelStops:true},initialize:function(B,A){this.now=[];
this.element=$(B);this.bound={stop:this.stop.bind(this,false)};this.parent(A);if(this.options.wheelStops){this.addEvent("onStart",function(){document.addEvent("mousewheel",this.bound.stop);
}.bind(this));this.addEvent("onComplete",function(){document.removeEvent("mousewheel",this.bound.stop);}.bind(this));}},setNow:function(){for(var A=0;A<2;
A++){this.now[A]=this.compute(this.from[A],this.to[A]);}},scrollTo:function(B,F){if(this.timer&&this.options.wait){return this;}var D=this.element.getSize();
var C={x:B,y:F};for(var E in D.size){var A=D.scrollSize[E]-D.size[E];if($chk(C[E])){C[E]=($type(C[E])=="number")?C[E].limit(0,A):A;}else{C[E]=D.scroll[E];
}C[E]+=this.options.offset[E];}return this.start([D.scroll.x,D.scroll.y],[C.x,C.y]);},toTop:function(){return this.scrollTo(false,0);},toBottom:function(){return this.scrollTo(false,"full");
},toLeft:function(){return this.scrollTo(0,false);},toRight:function(){return this.scrollTo("full",false);},toElement:function(B){var A=this.element.getPosition(this.options.overflown);
var C=$(B).getPosition(this.options.overflown);return this.scrollTo(C.x-A.x,C.y-A.y);},increase:function(){this.element.scrollTo(this.now[0],this.now[1]);
}});Fx.Slide=Fx.Base.extend({options:{mode:"vertical"},initialize:function(B,A){this.element=$(B);this.wrapper=new Element("div",{styles:$extend(this.element.getStyles("margin"),{overflow:"hidden"})}).injectAfter(this.element).adopt(this.element);
this.element.setStyle("margin",0);this.setOptions(A);this.now=[];this.parent(this.options);this.open=true;this.addEvent("onComplete",function(){this.open=(this.now[0]===0);
});if(window.webkit419){this.addEvent("onComplete",function(){if(this.open){this.element.remove().inject(this.wrapper);}});}},setNow:function(){for(var A=0;
A<2;A++){this.now[A]=this.compute(this.from[A],this.to[A]);}},vertical:function(){this.margin="margin-top";this.layout="height";this.offset=this.element.offsetHeight;
},horizontal:function(){this.margin="margin-left";this.layout="width";this.offset=this.element.offsetWidth;},slideIn:function(A){this[A||this.options.mode]();
return this.start([this.element.getStyle(this.margin).toInt(),this.wrapper.getStyle(this.layout).toInt()],[0,this.offset]);},slideOut:function(A){this[A||this.options.mode]();
return this.start([this.element.getStyle(this.margin).toInt(),this.wrapper.getStyle(this.layout).toInt()],[-this.offset,0]);},hide:function(A){this[A||this.options.mode]();
this.open=false;return this.set([-this.offset,0]);},show:function(A){this[A||this.options.mode]();this.open=true;return this.set([0,this.offset]);},toggle:function(A){if(this.wrapper.offsetHeight==0||this.wrapper.offsetWidth==0){return this.slideIn(A);
}return this.slideOut(A);},increase:function(){this.element.setStyle(this.margin,this.now[0]+this.options.unit);this.wrapper.setStyle(this.layout,this.now[1]+this.options.unit);
}});Fx.Transition=function(B,A){A=A||[];if($type(A)!="array"){A=[A];}return $extend(B,{easeIn:function(C){return B(C,A);},easeOut:function(C){return 1-B(1-C,A);
},easeInOut:function(C){return(C<=0.5)?B(2*C,A)/2:(2-B(2*(1-C),A))/2;}});};Fx.Transitions=new Abstract({linear:function(A){return A;}});Fx.Transitions.extend=function(A){for(var B in A){Fx.Transitions[B]=new Fx.Transition(A[B]);
Fx.Transitions.compat(B);}};Fx.Transitions.compat=function(A){["In","Out","InOut"].each(function(B){Fx.Transitions[A.toLowerCase()+B]=Fx.Transitions[A]["ease"+B];
});};Fx.Transitions.extend({Pow:function(B,A){return Math.pow(B,A[0]||6);},Expo:function(A){return Math.pow(2,8*(A-1));},Circ:function(A){return 1-Math.sin(Math.acos(A));
},Sine:function(A){return 1-Math.sin((1-A)*Math.PI/2);},Back:function(B,A){A=A[0]||1.618;return Math.pow(B,2)*((A+1)*B-A);},Bounce:function(D){var C;for(var B=0,A=1;
1;B+=A,A/=2){if(D>=(7-4*B)/11){C=-Math.pow((11-6*B-11*D)/4,2)+A*A;break;}}return C;},Elastic:function(B,A){return Math.pow(2,10*--B)*Math.cos(20*B*Math.PI*(A[0]||1)/3);
}});["Quad","Cubic","Quart","Quint"].each(function(B,A){Fx.Transitions[B]=new Fx.Transition(function(C){return Math.pow(C,[A+2]);});Fx.Transitions.compat(B);
});var Drag={};Drag.Base=new Class({options:{handle:false,unit:"px",onStart:Class.empty,onBeforeStart:Class.empty,onComplete:Class.empty,onSnap:Class.empty,onDrag:Class.empty,limit:false,modifiers:{x:"left",y:"top"},grid:false,snap:6},initialize:function(B,A){this.setOptions(A);
this.element=$(B);this.handle=$(this.options.handle)||this.element;this.mouse={now:{},pos:{}};this.value={start:{},now:{}};this.bound={start:this.start.bindWithEvent(this),check:this.check.bindWithEvent(this),drag:this.drag.bindWithEvent(this),stop:this.stop.bind(this)};
this.attach();if(this.options.initialize){this.options.initialize.call(this);}},attach:function(){this.handle.addEvent("mousedown",this.bound.start);return this;
},detach:function(){this.handle.removeEvent("mousedown",this.bound.start);return this;},start:function(C){this.fireEvent("onBeforeStart",this.element);
this.mouse.start=C.page;var A=this.options.limit;this.limit={x:[],y:[]};for(var D in this.options.modifiers){if(!this.options.modifiers[D]){continue;}this.value.now[D]=this.element.getStyle(this.options.modifiers[D]).toInt();
this.mouse.pos[D]=C.page[D]-this.value.now[D];if(A&&A[D]){for(var B=0;B<2;B++){if($chk(A[D][B])){this.limit[D][B]=($type(A[D][B])=="function")?A[D][B]():A[D][B];
}}}}if($type(this.options.grid)=="number"){this.options.grid={x:this.options.grid,y:this.options.grid};}document.addListener("mousemove",this.bound.check);
document.addListener("mouseup",this.bound.stop);this.fireEvent("onStart",this.element);C.stop();},check:function(A){var B=Math.round(Math.sqrt(Math.pow(A.page.x-this.mouse.start.x,2)+Math.pow(A.page.y-this.mouse.start.y,2)));
if(B>this.options.snap){document.removeListener("mousemove",this.bound.check);document.addListener("mousemove",this.bound.drag);this.drag(A);this.fireEvent("onSnap",this.element);
}A.stop();},drag:function(A){this.out=false;this.mouse.now=A.page;for(var B in this.options.modifiers){if(!this.options.modifiers[B]){continue;}this.value.now[B]=this.mouse.now[B]-this.mouse.pos[B];
if(this.limit[B]){if($chk(this.limit[B][1])&&(this.value.now[B]>this.limit[B][1])){this.value.now[B]=this.limit[B][1];this.out=true;}else{if($chk(this.limit[B][0])&&(this.value.now[B]<this.limit[B][0])){this.value.now[B]=this.limit[B][0];
this.out=true;}}}if(this.options.grid[B]){this.value.now[B]-=(this.value.now[B]%this.options.grid[B]);}this.element.setStyle(this.options.modifiers[B],this.value.now[B]+this.options.unit);
}this.fireEvent("onDrag",this.element);A.stop();},stop:function(){document.removeListener("mousemove",this.bound.check);document.removeListener("mousemove",this.bound.drag);
document.removeListener("mouseup",this.bound.stop);this.fireEvent("onComplete",this.element);}});Drag.Base.implement(new Events,new Options);Element.extend({makeResizable:function(A){return new Drag.Base(this,$merge({modifiers:{x:"width",y:"height"}},A));
}});Drag.Move=Drag.Base.extend({options:{droppables:[],container:false,overflown:[]},initialize:function(B,A){this.setOptions(A);this.element=$(B);this.droppables=$$(this.options.droppables);
this.container=$(this.options.container);this.position={element:this.element.getStyle("position"),container:false};if(this.container){this.position.container=this.container.getStyle("position");
}if(!["relative","absolute","fixed"].contains(this.position.element)){this.position.element="absolute";}var D=this.element.getStyle("top").toInt();var C=this.element.getStyle("left").toInt();
if(this.position.element=="absolute"&&!["relative","absolute","fixed"].contains(this.position.container)){D=$chk(D)?D:this.element.getTop(this.options.overflown);
C=$chk(C)?C:this.element.getLeft(this.options.overflown);}else{D=$chk(D)?D:0;C=$chk(C)?C:0;}this.element.setStyles({top:D,left:C,position:this.position.element});
this.parent(this.element);},start:function(C){this.overed=null;if(this.container){var A=this.container.getCoordinates();var B=this.element.getCoordinates();
if(this.position.element=="absolute"&&!["relative","absolute","fixed"].contains(this.position.container)){this.options.limit={x:[A.left,A.right-B.width],y:[A.top,A.bottom-B.height]};
}else{this.options.limit={y:[0,A.height-B.height],x:[0,A.width-B.width]};}}this.parent(C);},drag:function(A){this.parent(A);var B=this.out?false:this.droppables.filter(this.checkAgainst,this).getLast();
if(this.overed!=B){if(this.overed){this.overed.fireEvent("leave",[this.element,this]);}this.overed=B?B.fireEvent("over",[this.element,this]):null;}return this;
},checkAgainst:function(B){B=B.getCoordinates(this.options.overflown);var A=this.mouse.now;return(A.x>B.left&&A.x<B.right&&A.y<B.bottom&&A.y>B.top);},stop:function(){if(this.overed&&!this.out){this.overed.fireEvent("drop",[this.element,this]);
}else{this.element.fireEvent("emptydrop",this);}this.parent();return this;}});Element.extend({makeDraggable:function(A){return new Drag.Move(this,A);}});
var XHR=new Class({options:{method:"post",async:true,onRequest:Class.empty,onSuccess:Class.empty,onFailure:Class.empty,urlEncoded:true,encoding:"utf-8",autoCancel:false,headers:{}},setTransport:function(){this.transport=(window.XMLHttpRequest)?new XMLHttpRequest():(window.ie?new ActiveXObject("Microsoft.XMLHTTP"):false);
return this;},initialize:function(A){this.setTransport().setOptions(A);this.options.isSuccess=this.options.isSuccess||this.isSuccess;this.headers={};if(this.options.urlEncoded&&this.options.method=="post"){var B=(this.options.encoding)?"; charset="+this.options.encoding:"";
this.setHeader("Content-type","application/x-www-form-urlencoded"+B);}if(this.options.initialize){this.options.initialize.call(this);}},onStateChange:function(){if(this.transport.readyState!=4||!this.running){return ;
}this.running=false;var A=0;try{A=this.transport.status;}catch(B){}if(this.options.isSuccess.call(this,A)){this.onSuccess();}else{this.onFailure();}this.transport.onreadystatechange=Class.empty;
},isSuccess:function(A){return((A>=200)&&(A<300));},onSuccess:function(){this.response={text:this.transport.responseText,xml:this.transport.responseXML};
this.fireEvent("onSuccess",[this.response.text,this.response.xml]);this.callChain();},onFailure:function(){this.fireEvent("onFailure",this.transport);},setHeader:function(A,B){this.headers[A]=B;
return this;},send:function(A,C){if(this.options.autoCancel){this.cancel();}else{if(this.running){return this;}}this.running=true;if(C&&this.options.method=="get"){A=A+(A.contains("?")?"&":"?")+C;
C=null;}this.transport.open(this.options.method.toUpperCase(),A,this.options.async);this.transport.onreadystatechange=this.onStateChange.bind(this);if((this.options.method=="post")&&this.transport.overrideMimeType){this.setHeader("Connection","close");
}$extend(this.headers,this.options.headers);for(var B in this.headers){try{this.transport.setRequestHeader(B,this.headers[B]);}catch(D){}}this.fireEvent("onRequest");
this.transport.send($pick(C,null));return this;},cancel:function(){if(!this.running){return this;}this.running=false;this.transport.abort();this.transport.onreadystatechange=Class.empty;
this.setTransport();this.fireEvent("onCancel");return this;}});XHR.implement(new Chain,new Events,new Options);var Ajax=XHR.extend({options:{data:null,update:null,onComplete:Class.empty,evalScripts:false,evalResponse:false},initialize:function(B,A){this.addEvent("onSuccess",this.onComplete);
this.setOptions(A);this.options.data=this.options.data||this.options.postBody;if(!["post","get"].contains(this.options.method)){this._method="_method="+this.options.method;
this.options.method="post";}this.parent();this.setHeader("X-Requested-With","XMLHttpRequest");this.setHeader("Accept","text/javascript, text/html, application/xml, text/xml, */*");
this.url=B;},onComplete:function(){if(this.options.update){$(this.options.update).empty().setHTML(this.response.text);}if(this.options.evalScripts||this.options.evalResponse){this.evalScripts();
}this.fireEvent("onComplete",[this.response.text,this.response.xml],20);},request:function(A){A=A||this.options.data;switch($type(A)){case"element":A=$(A).toQueryString();
break;case"object":A=Object.toQueryString(A);}if(this._method){A=(A)?[this._method,A].join("&"):this._method;}return this.send(this.url,A);},evalScripts:function(){var B,A;
if(this.options.evalResponse||(/(ecma|java)script/).test(this.getHeader("Content-type"))){A=this.response.text;}else{A=[];var C=/<script[^>]*>([\s\S]*?)<\/script>/gi;
while((B=C.exec(this.response.text))){A.push(B[1]);}A=A.join("\n");}if(A){(window.execScript)?window.execScript(A):window.setTimeout(A,0);}},getHeader:function(A){try{return this.transport.getResponseHeader(A);
}catch(B){}return null;}});Object.toQueryString=function(B){var C=[];for(var A in B){C.push(encodeURIComponent(A)+"="+encodeURIComponent(B[A]));}return C.join("&");
};Element.extend({send:function(A){return new Ajax(this.getProperty("action"),$merge({data:this.toQueryString()},A,{method:"post"})).request();}});var Cookie=new Abstract({options:{domain:false,path:false,duration:false,secure:false},set:function(C,D,B){B=$merge(this.options,B);
D=encodeURIComponent(D);if(B.domain){D+="; domain="+B.domain;}if(B.path){D+="; path="+B.path;}if(B.duration){var A=new Date();A.setTime(A.getTime()+B.duration*24*60*60*1000);
D+="; expires="+A.toGMTString();}if(B.secure){D+="; secure";}document.cookie=C+"="+D;return $extend(B,{key:C,value:D});},get:function(A){var B=document.cookie.match("(?:^|;)\\s*"+A.escapeRegExp()+"=([^;]*)");
return B?decodeURIComponent(B[1]):false;},remove:function(B,A){if($type(B)=="object"){this.set(B.key,"",$merge(B,{duration:-1}));}else{this.set(B,"",$merge(A,{duration:-1}));
}}});var Json={toString:function(C){switch($type(C)){case"string":return'"'+C.replace(/(["\\])/g,"\\$1")+'"';case"array":return"["+C.map(Json.toString).join(",")+"]";
case"object":var A=[];for(var B in C){A.push(Json.toString(B)+":"+Json.toString(C[B]));}return"{"+A.join(",")+"}";case"number":if(isFinite(C)){break;}case false:return"null";
}return String(C);},evaluate:function(str,secure){return(($type(str)!="string")||(secure&&!str.test(/^("(\\.|[^"\\\n\r])*?"|[,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t])+?$/)))?null:eval("("+str+")");
}};Json.Remote=XHR.extend({initialize:function(B,A){this.url=B;this.addEvent("onSuccess",this.onComplete);this.parent(A);this.setHeader("X-Request","JSON");
},send:function(A){return this.parent(this.url,"json="+Json.toString(A));},onComplete:function(){this.fireEvent("onComplete",[Json.evaluate(this.response.text,this.options.secure)]);
}});var Asset=new Abstract({javascript:function(C,B){B=$merge({onload:Class.empty},B);var A=new Element("script",{src:C}).addEvents({load:B.onload,readystatechange:function(){if(this.readyState=="complete"){this.fireEvent("load");
}}});delete B.onload;return A.setProperties(B).inject(document.head);},css:function(B,A){return new Element("link",$merge({rel:"stylesheet",media:"screen",type:"text/css",href:B},A)).inject(document.head);
},image:function(C,B){B=$merge({onload:Class.empty,onabort:Class.empty,onerror:Class.empty},B);var D=new Image();D.src=C;var A=new Element("img",{src:C});
["load","abort","error"].each(function(E){var F=B["on"+E];delete B["on"+E];A.addEvent(E,function(){this.removeEvent(E,arguments.callee);F.call(this);});
});if(D.width&&D.height){A.fireEvent("load",A,1);}return A.setProperties(B);},images:function(D,C){C=$merge({onComplete:Class.empty,onProgress:Class.empty},C);
if(!D.push){D=[D];}var A=[];var B=0;D.each(function(F){var E=new Asset.image(F,{onload:function(){C.onProgress.call(this,B);B++;if(B==D.length){C.onComplete();
}}});A.push(E);});return new Elements(A);}});var Hash=new Class({length:0,initialize:function(A){this.obj=A||{};this.setLength();},get:function(A){return(this.hasKey(A))?this.obj[A]:null;
},hasKey:function(A){return(A in this.obj);},set:function(A,B){if(!this.hasKey(A)){this.length++;}this.obj[A]=B;return this;},setLength:function(){this.length=0;
for(var A in this.obj){this.length++;}return this;},remove:function(A){if(this.hasKey(A)){delete this.obj[A];this.length--;}return this;},each:function(A,B){$each(this.obj,A,B);
},extend:function(A){$extend(this.obj,A);return this.setLength();},merge:function(){this.obj=$merge.apply(null,[this.obj].extend(arguments));return this.setLength();
},empty:function(){this.obj={};this.length=0;return this;},keys:function(){var A=[];for(var B in this.obj){A.push(B);}return A;},values:function(){var A=[];
for(var B in this.obj){A.push(this.obj[B]);}return A;}});function $H(A){return new Hash(A);}Hash.Cookie=Hash.extend({initialize:function(B,A){this.name=B;
this.options=$extend({autoSave:true},A||{});this.load();},save:function(){if(this.length==0){Cookie.remove(this.name,this.options);return true;}var A=Json.toString(this.obj);
if(A.length>4096){return false;}Cookie.set(this.name,A,this.options);return true;},load:function(){this.obj=Json.evaluate(Cookie.get(this.name),true)||{};
this.setLength();}});Hash.Cookie.Methods={};["extend","set","merge","empty","remove"].each(function(A){Hash.Cookie.Methods[A]=function(){Hash.prototype[A].apply(this,arguments);
if(this.options.autoSave){this.save();}return this;};});Hash.Cookie.implement(Hash.Cookie.Methods);var Color=new Class({initialize:function(B,D){D=D||(B.push?"rgb":"hex");
var C,A;switch(D){case"rgb":C=B;A=C.rgbToHsb();break;case"hsb":C=B.hsbToRgb();A=B;break;default:C=B.hexToRgb(true);A=C.rgbToHsb();}C.hsb=A;C.hex=C.rgbToHex();
return $extend(C,Color.prototype);},mix:function(){var A=$A(arguments);var C=($type(A[A.length-1])=="number")?A.pop():50;var B=this.copy();A.each(function(D){D=new Color(D);
for(var E=0;E<3;E++){B[E]=Math.round((B[E]/100*(100-C))+(D[E]/100*C));}});return new Color(B,"rgb");},invert:function(){return new Color(this.map(function(A){return 255-A;
}));},setHue:function(A){return new Color([A,this.hsb[1],this.hsb[2]],"hsb");},setSaturation:function(A){return new Color([this.hsb[0],A,this.hsb[2]],"hsb");
},setBrightness:function(A){return new Color([this.hsb[0],this.hsb[1],A],"hsb");}});function $RGB(C,B,A){return new Color([C,B,A],"rgb");}function $HSB(C,B,A){return new Color([C,B,A],"hsb");
}Array.extend({rgbToHsb:function(){var B=this[0],C=this[1],J=this[2];var G,F,H;var I=Math.max(B,C,J),E=Math.min(B,C,J);var K=I-E;H=I/255;F=(I!=0)?K/I:0;
if(F==0){G=0;}else{var D=(I-B)/K;var A=(I-C)/K;var L=(I-J)/K;if(B==I){G=L-A;}else{if(C==I){G=2+D-L;}else{G=4+A-D;}}G/=6;if(G<0){G++;}}return[Math.round(G*360),Math.round(F*100),Math.round(H*100)];
},hsbToRgb:function(){var C=Math.round(this[2]/100*255);if(this[1]==0){return[C,C,C];}else{var A=this[0]%360;var E=A%60;var F=Math.round((this[2]*(100-this[1]))/10000*255);
var D=Math.round((this[2]*(6000-this[1]*E))/600000*255);var B=Math.round((this[2]*(6000-this[1]*(60-E)))/600000*255);switch(Math.floor(A/60)){case 0:return[C,B,F];
case 1:return[D,C,F];case 2:return[F,C,B];case 3:return[F,D,C];case 4:return[B,F,C];case 5:return[C,F,D];}}return false;}});var Scroller=new Class({options:{area:20,velocity:1,onChange:function(A,B){this.element.scrollTo(A,B);
}},initialize:function(B,A){this.setOptions(A);this.element=$(B);this.mousemover=([window,document].contains(B))?$(document.body):this.element;},start:function(){this.coord=this.getCoords.bindWithEvent(this);
this.mousemover.addListener("mousemove",this.coord);},stop:function(){this.mousemover.removeListener("mousemove",this.coord);this.timer=$clear(this.timer);
},getCoords:function(A){this.page=(this.element==window)?A.client:A.page;if(!this.timer){this.timer=this.scroll.periodical(50,this);}},scroll:function(){var A=this.element.getSize();
var D=this.element.getPosition();var C={x:0,y:0};for(var B in this.page){if(this.page[B]<(this.options.area+D[B])&&A.scroll[B]!=0){C[B]=(this.page[B]-this.options.area-D[B])*this.options.velocity;
}else{if(this.page[B]+this.options.area>(A.size[B]+D[B])&&A.scroll[B]+A.size[B]!=A.scrollSize[B]){C[B]=(this.page[B]-A.size[B]+this.options.area-D[B])*this.options.velocity;
}}}if(C.y||C.x){this.fireEvent("onChange",[A.scroll.x+C.x,A.scroll.y+C.y]);}}});Scroller.implement(new Events,new Options);var Slider=new Class({options:{onChange:Class.empty,onComplete:Class.empty,onTick:function(A){this.knob.setStyle(this.p,A);
},mode:"horizontal",steps:100,offset:0},initialize:function(D,A,B){this.element=$(D);this.knob=$(A);this.setOptions(B);this.previousChange=-1;this.previousEnd=-1;
this.step=-1;this.element.addEvent("mousedown",this.clickedElement.bindWithEvent(this));var C,F;switch(this.options.mode){case"horizontal":this.z="x";this.p="left";
C={x:"left",y:false};F="offsetWidth";break;case"vertical":this.z="y";this.p="top";C={x:false,y:"top"};F="offsetHeight";}this.max=this.element[F]-this.knob[F]+(this.options.offset*2);
this.half=this.knob[F]/2;this.getPos=this.element["get"+this.p.capitalize()].bind(this.element);this.knob.setStyle("position","relative").setStyle(this.p,-this.options.offset);
var E={};E[this.z]=[-this.options.offset,this.max-this.options.offset];this.drag=new Drag.Base(this.knob,{limit:E,modifiers:C,snap:0,onStart:function(){this.draggedKnob();
}.bind(this),onDrag:function(){this.draggedKnob();}.bind(this),onComplete:function(){this.draggedKnob();this.end();}.bind(this)});if(this.options.initialize){this.options.initialize.call(this);
}},set:function(A){this.step=A.limit(0,this.options.steps);this.checkStep();this.end();this.fireEvent("onTick",this.toPosition(this.step));return this;
},clickedElement:function(B){var A=B.page[this.z]-this.getPos()-this.half;A=A.limit(-this.options.offset,this.max-this.options.offset);this.step=this.toStep(A);
this.checkStep();this.end();this.fireEvent("onTick",A);},draggedKnob:function(){this.step=this.toStep(this.drag.value.now[this.z]);this.checkStep();},checkStep:function(){if(this.previousChange!=this.step){this.previousChange=this.step;
this.fireEvent("onChange",this.step);}},end:function(){if(this.previousEnd!==this.step){this.previousEnd=this.step;this.fireEvent("onComplete",this.step+"");
}},toStep:function(A){return Math.round((A+this.options.offset)/this.max*this.options.steps);},toPosition:function(A){return this.max*A/this.options.steps;
}});Slider.implement(new Events);Slider.implement(new Options);var SmoothScroll=Fx.Scroll.extend({initialize:function(B){this.parent(window,B);this.links=(this.options.links)?$$(this.options.links):$$(document.links);
var A=window.location.href.match(/^[^#]*/)[0]+"#";this.links.each(function(D){if(D.href.indexOf(A)!=0){return ;}var C=D.href.substr(A.length);if(C&&$(C)){this.useLink(D,C);
}},this);if(!window.webkit419){this.addEvent("onComplete",function(){window.location.hash=this.anchor;});}},useLink:function(B,A){B.addEvent("click",function(C){this.anchor=A;
this.toElement(A);C.stop();}.bindWithEvent(this));}});var Sortables=new Class({options:{handles:false,onStart:Class.empty,onComplete:Class.empty,ghost:true,snap:3,onDragStart:function(A,B){B.setStyle("opacity",0.7);
A.setStyle("opacity",0.7);},onDragComplete:function(A,B){A.setStyle("opacity",1);B.remove();this.trash.remove();}},initialize:function(D,B){this.setOptions(B);
this.list=$(D);this.elements=this.list.getChildren();this.handles=(this.options.handles)?$$(this.options.handles):this.elements;this.bound={start:[],moveGhost:this.moveGhost.bindWithEvent(this)};
for(var C=0,A=this.handles.length;C<A;C++){this.bound.start[C]=this.start.bindWithEvent(this,this.elements[C]);}this.attach();if(this.options.initialize){this.options.initialize.call(this);
}this.bound.move=this.move.bindWithEvent(this);this.bound.end=this.end.bind(this);},attach:function(){this.handles.each(function(B,A){B.addEvent("mousedown",this.bound.start[A]);
},this);},detach:function(){this.handles.each(function(B,A){B.removeEvent("mousedown",this.bound.start[A]);},this);},start:function(C,B){this.active=B;
this.coordinates=this.list.getCoordinates();if(this.options.ghost){var A=B.getPosition();this.offset=C.page.y-A.y;this.trash=new Element("div").inject(document.body);
this.ghost=B.clone().inject(this.trash).setStyles({position:"absolute",left:A.x,top:C.page.y-this.offset});document.addListener("mousemove",this.bound.moveGhost);
this.fireEvent("onDragStart",[B,this.ghost]);}document.addListener("mousemove",this.bound.move);document.addListener("mouseup",this.bound.end);this.fireEvent("onStart",B);
C.stop();},moveGhost:function(A){var B=A.page.y-this.offset;B=B.limit(this.coordinates.top,this.coordinates.bottom-this.ghost.offsetHeight);this.ghost.setStyle("top",B);
A.stop();},move:function(E){var B=E.page.y;this.previous=this.previous||B;var A=((this.previous-B)>0);var D=this.active.getPrevious();var C=this.active.getNext();
if(D&&A&&B<D.getCoordinates().bottom){this.active.injectBefore(D);}if(C&&!A&&B>C.getCoordinates().top){this.active.injectAfter(C);}this.previous=B;},serialize:function(A){return this.list.getChildren().map(A||function(B){return this.elements.indexOf(B);
},this);},end:function(){this.previous=null;document.removeListener("mousemove",this.bound.move);document.removeListener("mouseup",this.bound.end);if(this.options.ghost){document.removeListener("mousemove",this.bound.moveGhost);
this.fireEvent("onDragComplete",[this.active,this.ghost]);}this.fireEvent("onComplete",this.active);}});Sortables.implement(new Events,new Options);var Tips=new Class({options:{onShow:function(A){A.setStyle("visibility","visible");
},onHide:function(A){A.setStyle("visibility","hidden");},maxTitleChars:30,showDelay:100,hideDelay:100,className:"tool",offsets:{x:16,y:16},fixed:false},initialize:function(B,A){this.setOptions(A);
this.toolTip=new Element("div",{"class":this.options.className+"-tip",styles:{position:"absolute",top:"0",left:"0",visibility:"hidden"}}).inject(document.body);
this.wrapper=new Element("div").inject(this.toolTip);$$(B).each(this.build,this);if(this.options.initialize){this.options.initialize.call(this);}},build:function(B){B.$tmp.myTitle=(B.href&&B.getTag()=="a")?B.href.replace("http://",""):(B.rel||false);
if(B.title){var C=B.title.split("::");if(C.length>1){B.$tmp.myTitle=C[0].trim();B.$tmp.myText=C[1].trim();}else{B.$tmp.myText=B.title;}B.removeAttribute("title");
}else{B.$tmp.myText=false;}if(B.$tmp.myTitle&&B.$tmp.myTitle.length>this.options.maxTitleChars){B.$tmp.myTitle=B.$tmp.myTitle.substr(0,this.options.maxTitleChars-1)+"&hellip;";
}B.addEvent("mouseenter",function(D){this.start(B);if(!this.options.fixed){this.locate(D);}else{this.position(B);}}.bind(this));if(!this.options.fixed){B.addEvent("mousemove",this.locate.bindWithEvent(this));
}var A=this.end.bind(this);B.addEvent("mouseleave",A);B.addEvent("trash",A);},start:function(A){this.wrapper.empty();if(A.$tmp.myTitle){this.title=new Element("span").inject(new Element("div",{"class":this.options.className+"-title"}).inject(this.wrapper)).setHTML(A.$tmp.myTitle);
}if(A.$tmp.myText){this.text=new Element("span").inject(new Element("div",{"class":this.options.className+"-text"}).inject(this.wrapper)).setHTML(A.$tmp.myText);
}$clear(this.timer);this.timer=this.show.delay(this.options.showDelay,this);},end:function(A){$clear(this.timer);this.timer=this.hide.delay(this.options.hideDelay,this);
},position:function(A){var B=A.getPosition();this.toolTip.setStyles({left:B.x+this.options.offsets.x,top:B.y+this.options.offsets.y});},locate:function(B){var D={x:window.getWidth(),y:window.getHeight()};
var A={x:window.getScrollLeft(),y:window.getScrollTop()};var C={x:this.toolTip.offsetWidth,y:this.toolTip.offsetHeight};var G={x:"left",y:"top"};for(var E in G){var F=B.page[E]+this.options.offsets[E];
if((F+C[E]-A[E])>D[E]){F=B.page[E]-this.options.offsets[E]-C[E];}this.toolTip.setStyle(G[E],F);}},show:function(){if(this.options.timeout){this.timer=this.hide.delay(this.options.timeout,this);
}this.fireEvent("onShow",[this.toolTip]);},hide:function(){this.fireEvent("onHide",[this.toolTip]);}});Tips.implement(new Events,new Options);var Group=new Class({initialize:function(){this.instances=$A(arguments);
this.events={};this.checker={};},addEvent:function(B,A){this.checker[B]=this.checker[B]||{};this.events[B]=this.events[B]||[];if(this.events[B].contains(A)){return false;
}else{this.events[B].push(A);}this.instances.each(function(C,D){C.addEvent(B,this.check.bind(this,[B,C,D]));},this);return this;},check:function(C,A,B){this.checker[C][B]=true;
var D=this.instances.every(function(F,E){return this.checker[C][E]||false;},this);if(!D){return ;}this.checker[C]={};this.events[C].each(function(E){E.call(this,this.instances,A);
},this);}});var Accordion=Fx.Elements.extend({options:{onActive:Class.empty,onBackground:Class.empty,display:0,show:false,height:true,width:false,opacity:true,fixedHeight:false,fixedWidth:false,wait:false,alwaysHide:false},initialize:function(){var C,E,F,B;
$each(arguments,function(I,H){switch($type(I)){case"object":C=I;break;case"element":B=$(I);break;default:var G=$$(I);if(!E){E=G;}else{F=G;}}});this.togglers=E||[];
this.elements=F||[];this.container=$(B);this.setOptions(C);this.previous=-1;if(this.options.alwaysHide){this.options.wait=true;}if($chk(this.options.show)){this.options.display=false;
this.previous=this.options.show;}if(this.options.start){this.options.display=false;this.options.show=false;}this.effects={};if(this.options.opacity){this.effects.opacity="fullOpacity";
}if(this.options.width){this.effects.width=this.options.fixedWidth?"fullWidth":"offsetWidth";}if(this.options.height){this.effects.height=this.options.fixedHeight?"fullHeight":"scrollHeight";
}for(var D=0,A=this.togglers.length;D<A;D++){this.addSection(this.togglers[D],this.elements[D]);}this.elements.each(function(H,G){if(this.options.show===G){this.fireEvent("onActive",[this.togglers[G],H]);
}else{for(var I in this.effects){H.setStyle(I,0);}}},this);this.parent(this.elements);if($chk(this.options.display)){this.display(this.options.display);
}},addSection:function(E,C,G){E=$(E);C=$(C);var F=this.togglers.contains(E);var B=this.togglers.length;this.togglers.include(E);this.elements.include(C);
if(B&&(!F||G)){G=$pick(G,B-1);E.injectBefore(this.togglers[G]);C.injectAfter(E);}else{if(this.container&&!F){E.inject(this.container);C.inject(this.container);
}}var A=this.togglers.indexOf(E);E.addEvent("click",this.display.bind(this,A));if(this.options.height){C.setStyles({"padding-top":0,"border-top":"none","padding-bottom":0,"border-bottom":"none"});
}if(this.options.width){C.setStyles({"padding-left":0,"border-left":"none","padding-right":0,"border-right":"none"});}C.fullOpacity=1;if(this.options.fixedWidth){C.fullWidth=this.options.fixedWidth;
}if(this.options.fixedHeight){C.fullHeight=this.options.fixedHeight;}C.setStyle("overflow","hidden");if(!F){for(var D in this.effects){C.setStyle(D,0);
}}return this;},display:function(A){A=($type(A)=="element")?this.elements.indexOf(A):A;if((this.timer&&this.options.wait)||(A===this.previous&&!this.options.alwaysHide)){return this;
}this.previous=A;var B={};this.elements.each(function(E,D){B[D]={};var C=(D!=A)||(this.options.alwaysHide&&(E.offsetHeight>0));this.fireEvent(C?"onBackground":"onActive",[this.togglers[D],E]);
for(var F in this.effects){B[D][F]=C?0:E[this.effects[F]];}},this);return this.start(B);},showThisHideOpen:function(A){return this.display(A);}});Fx.Accordion=Accordion;
/**
 * blinkx tv search page
 */
function showEpisodeDetails(elem) {
	if ($(elem)) {
		// open details
		$(elem).addClass('episode_toggleElement_open');
		// open arrow
		$('img_'+elem).addClass('arrow_open');
	}
}
function hideEpisodeDetails(elem) {
	if ($(elem)) {
		// close details
		$(elem).removeClass('episode_toggleElement_open');
		// close arrow
		$('img_'+elem).removeClass('arrow_open');
	}
}
function toggleEpisodeDetails(elem) {
	if ($(elem)) {
		if ($(elem).className == 'episode_toggleElement') {
			// open details
			$(elem).addClass('episode_toggleElement_open');
			// open arrow
			$('img_'+elem).addClass('arrow_open');
		}
		else {
			// close details
			$(elem).removeClass('episode_toggleElement_open');
			// close arrow
			$('img_'+elem).removeClass('arrow_open');
		}
	}
}
function toggleEpisodeDetailsByObj(elem)
{
	if ($(elem)) {
		var episode = elem.nextSibling;
		var children = elem.childNodes;
		// handle arrow
		for (var i=0;i<children.length;i++) {
			if (children[i].className == 'arrow_closed') {
				$(children[i]).addClass('arrow_open');
			}
			else if (children[i].className == 'arrow_closed arrow_open') {
				$(children[i]).removeClass('arrow_open');
			}
		}
		// handle episode
		if (episode.className == 'episode_toggleElement') {
			$(episode).addClass('episode_toggleElement_open');
		}
		else if (episode.className == 'episode_toggleElement episode_toggleElement_open') {
			$(episode).removeClass('episode_toggleElement_open');
		}
	}
}

function seasonImageActive(toggler) {
	var innerDivs = toggler.getElementsByTagName('DIV');
	for(var i=0; i<innerDivs.length; i++) {
		if (innerDivs[i].className == 'season_arrow_closed') {
			$(innerDivs[i].id).addClass('season_arrow_open');
			return;
		}
	}
}

function seasonImageBackground(toggler) {
	var innerDivs = toggler.getElementsByTagName('DIV');
	for(var i=0; i<innerDivs.length; i++) {
		if (innerDivs[i].className == 'season_arrow_closed season_arrow_open') {
			$(innerDivs[i].id).removeClass('season_arrow_open');
			return;
		}
	}
}

function toggleSeason(elem) {
	if ($('season_'+elem)) {
		if ($('season_'+elem).className == 'season_toggleElement') {
			// open details
			$('season_'+elem).addClass('season_toggleElement_open');
			// open arrow
			$('season_img'+elem).addClass('arrow_open');
		}
		else {
			// close details
			$('season_'+elem).removeClass('season_toggleElement_open');
			// close arrow
			$('season_img'+elem).removeClass('arrow_open');
		}
	}
}

function showSeason(elem) {
	if ($('season_'+elem)) {
		// open details
		$('season_'+elem).addClass('season_toggleElement_open');
		// open arrow
		$('season_img'+elem).addClass('arrow_open');
	}
}
function hideSeason(elem) {
	if ($('season_'+elem)) {
		// close details
		$('season_'+elem).removeClass('season_toggleElement_open');
		// close arrow
		$('season_img'+elem).removeClass('arrow_open');
	}
}

function openEpisodeOnLoad2() {
	var hash = location.hash;
	hash = hash.substring(1, hash.length);
	// override hash if js var exists
	try { if (window.blinkxremote_eid) { hash = blinkxremote_eid; }	}
	catch(err) {}
	if (hash.length <= 0 && $('latestEpisode')) {
		hash = $('latestEpisode').innerHTML;
	}
	if (hash.length > 0) {
		if ($('e'+hash)) {
			// open episode
			toggleEpisodeDetailsByObj($('e'+hash).parentNode.parentNode.previousSibling);
			// open season
			var season = ($('e'+hash)).parentNode.parentNode.parentNode.parentNode.parentNode.id;
			season = season.substring(7, season.length);
			showSeason(season);
			return;
		}
		else {
			if($('latestEpisode')) hash = $('latestEpisode').innerHTML;
			if ($('e'+hash)) {
				// open episode
				toggleEpisodeDetailsByObj($('e'+hash).parentNode.parentNode.previousSibling);
				// open season
				var season = ($('e'+hash)).parentNode.parentNode.parentNode.parentNode.parentNode.id;
				season = season.substring(7, season.length);
				showSeason(season);
				return;
			}
		}
	}
}

function openEpisodeOnLoad() {
	var hash = location.hash;
	hash = hash.substring(1, hash.length);
	// override hash if js var exists
	try { if (window.blinkxremote_eid) { hash = blinkxremote_eid; }	}
	catch(err) {}
	if (hash.length > 0) {
		var el = document.getElementById('ep_'+hash);
		if (el) {
			// open episode
			var episode = el.id;
			showEpisodeDetails(episode);
			// open season
			var season = el.parentNode.parentNode.parentNode.id;
			season = season.substring(7, season.length);
			showSeason(season);
		}
		else {
			// get latest episode
			var latestEpisode = document.getElementById('latestEpisode');
			if (latestEpisode) {
				// open episode
				latestEpisode = latestEpisode.innerHTML;
				var el = document.getElementById('ep_'+latestEpisode);
				if (el) {
					var episode = el.id;
					showEpisodeDetails(episode);
					// open season
					var season = el.parentNode.parentNode.parentNode.id;
					season = season.substring(7, season.length);
					showSeason(season);
				}
			}
		}
	}
	else {
		// get latest episode
		var latestEpisode = document.getElementById('latestEpisode');
		if (latestEpisode) {
			// open episode
			latestEpisode = latestEpisode.innerHTML;
			var el = document.getElementById('ep_'+latestEpisode);
			if (el) {
				var episode = el.id;
				showEpisodeDetails(episode);
				// open season
				var season = el.parentNode.parentNode.parentNode.id;
				season = season.substring(7, season.length);
				showSeason(season);
			}
		}
	}
}

function showEmailUpdates() {
	if ('emailUpdatesContainer') {
		$('emailUpdatesContainer').style.display = 'block';
		if ($('emailField')) {
			$('emailField').focus();
		}
	}
}
function hideEmailUpdates() {
	if ('emailUpdatesContainer') {
		$('emailUpdatesContainer').style.display = 'none';
	}
}

function resizeOverlay() {
	var overlayContainer = document.getElementById('overlay');
	if (overlayContainer) { overlayContainer.style.height = window.getScrollHeight() + 'px'; }
}

function selectRegion(el) {
	if (el.value) {
		var region = el.value;
		if (region == 'US' || region == 'GB') {
			// set cookie
			createCookie('blinkxRemoteRegion',region,0);
			// refresh page
			window.location.reload();
		}
	}
}

function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}


/* ---------------------------------------------------------------------------------------------------------*/
/* -------------------------------------------------------------------------------------------------------- */

//EventUtil.addEventHandler(window,"load",function(){openEpisodeOnLoad();});
EventUtil.addEventHandler(window,"load",function(){openEpisodeOnLoad2();});

// email updates
EventUtil.addEventHandler(window,"load",function(){
	if ($('emailUpdatesForm')) {
		$('emailUpdatesForm').addEvent('submit', function(e) {
			new Event(e).stop();
			var emailUpdatesContainer = $('emailUpdatesContainer');
			this.send({
				update: emailUpdatesContainer
			});
		});
	}
});

// resize fader
EventUtil.addEventHandler(window,"load",function(){resizeOverlay();});
//Default declarations
if(typeof searchAreaPlaceholder=="undefined") var searchAreaPlaceholder='Search...';
if(typeof noAutoCompleteEntriesText=="undefined") var noAutoCompleteEntriesText='Sorry, there are no items matching your search';
if(typeof autoCompleteType=="undefined") var autoCompleteType='tv';
if(typeof additionalAjaxParams=="undefined") var additionalAjaxParams='';

/* ---------------------------------------------------------------------------------------------------------*/
/* Filter Section Categories
/* -------------------------------------------------------------------------------------------------------- */

alphaNumCategoriesArray = new Array('other', 'num');
for (var i=97; i<=122; i++) {
	alphaNumCategoriesArray.push(String.fromCharCode(i));
}

function showCategory(val) {
	// category_other, category_num, category_a -> category_z
	// remove 'all' filter
	$('alphaNumFilters_all').removeClass('selected');
	for (var i=0; i<alphaNumCategoriesArray.length; i++) {
		if (alphaNumCategoriesArray[i] != val) {
			if ($('category_' + alphaNumCategoriesArray[i])) {
				$('category_' + alphaNumCategoriesArray[i]).setStyle('display','none');
				if ($('alphaNumFilters_' + alphaNumCategoriesArray[i])) {
					$('alphaNumFilters_' + alphaNumCategoriesArray[i]).removeClass('selected');
				}
			}
		}
		else {
			if ($('category_' + val)) {
				$('category_' + val).setStyle('display','block');
				$('alphaNumFilters_' + val).addClass('selected');
			}
		}
	}
}

function showAllCategories() {
	// category_other, category_num, category_a -> category_z
	for (var i=0; i<alphaNumCategoriesArray.length; i++) {
		if ($('category_' + alphaNumCategoriesArray[i])) {
			$('category_' + alphaNumCategoriesArray[i]).setStyle('display','block');
		}
		if ($('alphaNumFilters_' + alphaNumCategoriesArray[i])) {
			$('alphaNumFilters_' + alphaNumCategoriesArray[i]).removeClass('selected');
		}
	}
	$('alphaNumFilters_all').addClass('selected');
}

function initializeCategoryFilters() {
	var alphaNumFilters=$('alphaNumFilters');
	if(alphaNumFilters)
	{
		var filters=alphaNumFilters.getElementsByTagName("a");
		var currFilter;
		for(var i=0; i<filters.length; i++)
		{
			currFilter=filters[i].id;
			// attach onclick event
			if (currFilter == 'alphaNumFilters_all') {
				EventUtil.addEventHandler($(currFilter), 'click', showAllCategories);
			}
			else if (currFilter == 'alphaNumFilters_num') {
				EventUtil.addEventHandler($(currFilter), 'click', function(){showCategory('num');});
			}
		}
	}
}

/* ---------------------------------------------------------------------------------------------------------*/
/* Placeholder Effect for Search as seen in Safari, made available to other browsers  */
/* -------------------------------------------------------------------------------------------------------- */
function activatePlaceholders() {
	var detect = navigator.userAgent.toLowerCase();
	if (detect.indexOf("safari") > 0) return false;
	var textBox = document.getElementById('showSearchTextBox');
	if (textBox) {
		textBox.value = searchAreaPlaceholder;
		textBox.onclick = function() {
			if (this.value == searchAreaPlaceholder) {
				this.value = '';
			}
			return false;
		}
		textBox.onblur = function() {
			if (this.value.length < 1) {
				this.value = searchAreaPlaceholder;
				clearSearchResults();
			}
		}
	}
}

/* ---------------------------------------------------------------------------------------------------------*/
/* 	SEARCH BOX:
	Used for search box text input interactivity.  When you start typing in the box, the clear button shows up
*/
/* -------------------------------------------------------------------------------------------------------- */
function hideClearBtn() {
	var o=document.getElementById("searchClearBtn");
	if(o) o.style.display = "none";
}

function showClearBtn() {
	var o=document.getElementById("searchClearBtn");
	if(o) o.style.display = "block";
}

function clearSearchText() {
	var input = document.getElementById("showSearchTextBox");
	input.value="";
	input.focus();
	hideClearBtn();
}

function clearSearchResults() {
	var resultsContainer = document.getElementById('autoCompleteSearchResults');
	if (resultsContainer) {
		resultsContainer.innerHTML = '';
	}
}

function checkSearchText(keyid) {
	// enter key
	if (keyid == 13) {
		try {
			if (selectedAutoComplete["link"]) {
				location.href = selectedAutoComplete["link"];
			}
		}
		catch(e) {}
	}
	// up arrow
	else if (keyid == 38) {
		var currentItemIndex = selectedAutoComplete["item"];
		if (currentItemIndex != 0) {
			// decrement item index
			currentItemIndex--;
			// check if that element exists
			if ($('autoComplete_' + currentItemIndex) && $('autoComplete_' + selectedAutoComplete["item"])) {
				$('autoComplete_' + selectedAutoComplete["item"]).removeClass('selectedState');
				selectedAutoComplete["link"] = $('autoComplete_' + currentItemIndex).href;
				selectedAutoComplete["item"] = currentItemIndex;
				$('autoComplete_' + currentItemIndex).addClass('selectedState');
			}
		}
	}
	// down arrow
	else if (keyid == 40) {
		var currentItemIndex = selectedAutoComplete["item"];
		if (currentItemIndex < 6) {
			// increment item index
			currentItemIndex++;
			// check if that element exists
			if ($('autoComplete_' + currentItemIndex) && $('autoComplete_' + selectedAutoComplete["item"])) {
				$('autoComplete_' + selectedAutoComplete["item"]).removeClass('selectedState');
				selectedAutoComplete["link"] = $('autoComplete_' + currentItemIndex).href;
				selectedAutoComplete["item"] = currentItemIndex;
				$('autoComplete_' + currentItemIndex).addClass('selectedState');
			}
		}
	}
	// other key
	else {
		clearSearchResults();
		var input = document.getElementById("showSearchTextBox");
		if (input.value != "")
		{
			showClearBtn();
			if (input.value.length >= 2)
			{
				var resultsContainer=document.getElementById('autoCompleteSearchResults');
				if (resultsContainer)
				{
					AutocompleteHandler.resetTimeout(input.value);
				}
			}
		}
		else
		{
			hideClearBtn();
		}
	}
}

var AutocompleteHandler={
	text:null,
	timeout:null,
	http:null,
	entries:new Array,
	resetTimeout:function(sText)
	{
		if(sText!=this.text)
		{
			this.cancelRequest();
			if(this.timeout)
			{
				clearTimeout(this.timeout);
				this.timeout=null;
			}
			this.clearAllEntries();
			this.text=sText;
			this.timeout=setTimeout(AutocompleteHandler.sendRequest,200);
		}
	},
	sendRequest:function()
	{
		try
		{
			var url="/autosearch?p="+encodeURIComponent(autoCompleteType)+"&text="+encodeURIComponent(AutocompleteHandler.text.substring(0,128));
			if(additionalAjaxParams && additionalAjaxParams.length) url+="&"+additionalAjaxParams;
			AutocompleteHandler.cancelRequest();
			AutocompleteHandler.http=initXMLHttpClient();
			AutocompleteHandler.http.open("GET",url,true);
			AutocompleteHandler.http.onreadystatechange=AutocompleteHandler.httpCallback;
			AutocompleteHandler.http.send(null);
		}
		catch(e){}
	},
	cancelRequest:function()
	{
		if(this.http)
		{
			this.http.onreadystatechange=function(){};
			this.http=null;
		}
	},
	httpCallback:function()
	{
		try
		{
			if(AutocompleteHandler.http && AutocompleteHandler.http.readyState==4)
			{
				eval(AutocompleteHandler.http.responseText);
				autoCompleteHTML();
			}
		}
		catch (e) {}
	},
	clearAllEntries:function()
	{
		this.entries=new Array;
	},
	addEntry:function(sName,sLink)
	{
		this.entries.push(
			{
				name:sName,
				link:sLink
			}
		);
	}
};


function selectAutoComplete() {
	// select first autocomplete entry by default
	if ($('autoComplete_0')) {
		if (!selectedAutoComplete) {
			selectedAutoComplete = new Array();
		}
		selectedAutoComplete["link"] = $('autoComplete_0').href;
		selectedAutoComplete["item"] = 0;
		// show selection
		$('autoComplete_0').addClass('selectedState');
	}
	else {
		selectedAutoComplete = new Array();
	}
}

function autoCompleteHTML() {
	var resultsContainer=document.getElementById('autoCompleteSearchResults');
	if (resultsContainer)
	{
		var resultsHtml='<ul>';
		try
		{
			if(AutocompleteHandler.entries && AutocompleteHandler.entries.length>0)
			{
				var i,iMax=Math.min(6,AutocompleteHandler.entries.length),entry;
				for(i=0;i<iMax;i++)
				{
					entry=AutocompleteHandler.entries[i];
					resultsHtml+='<li><a id="autoComplete_'+i+'" class="defaultState" onmouseout="autoSuggestMouseOut(this);" onmouseover="autoSuggestMouseOver(this);" href="'+entry.link+'">'+entry.name+'</a></li>';
				}
			}
			else
			{
				resultsHtml+='<li><p>'+noAutoCompleteEntriesText+'</p></li>';
			}
		}
		catch(e){}
		resultsHtml+='</ul>';

		resultsContainer.innerHTML=resultsHtml;
		selectAutoComplete();
	}
}

function autoSuggestMouseOut(el) {
	if (selectedAutoComplete) {
		if ('autoComplete_' + selectedAutoComplete["item"] != el.id) {
			$(el.id).removeClass('selectedState');
		}
	}
}

function autoSuggestMouseOver(el) {
	$(el.id).addClass('selectedState');
}

function keyhandler(e) {
	var KeyID = (window.event) ? event.keyCode : e.keyCode;
	if (KeyID == 0) {
		KeyID = e.charCode;
	}
	checkSearchText(KeyID);
}

function resizeOverlay() {
	var overlayContainer = document.getElementById('overlay');
	if (overlayContainer) { overlayContainer.style.height = window.getScrollHeight() + 'px'; }
}

function openUrl(url) {
	location.href = url;
}

/* ---------------------------------------------------------------------------------------------------------*/
/* -------------------------------------------------------------------------------------------------------- */

EventUtil.addEventHandler(window,"load",function()
{
	// Initialize the placeholder functionality
	// Hide the clear button initially
	activatePlaceholders(); hideClearBtn();

	// search
	initializeCategoryFilters();

	// capture key
	selectedAutoComplete = new Array();
	EventUtil.addEventHandler(document.getElementById('showSearchTextBox'),"keyup",keyhandler);

	// resize overlay
	if(typeof resizeOverlay=="function") resizeOverlay();
});


