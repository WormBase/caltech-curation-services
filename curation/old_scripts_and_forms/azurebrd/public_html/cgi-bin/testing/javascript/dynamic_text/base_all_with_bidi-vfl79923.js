var cookie_domain='youtube.com';
var cookie_prefix='';
var yt={};
function _gel(id){
  return(typeof id=="string"?document.getElementById(id):id);
}
var ref=_gel;
function each(array,func){
  for(var i=0,l=array.length;i<l;i++)func(array[i]);
}
var arrayEach=each;
function hasAncestor(element,ancestor){
  var el=ref(element);
  var an=ref(ancestor);
  while(el!=document&&el!=null){
    if(el==an)return true;
    el=el.parentNode;
  }
  return false;
}
function setInnerHTML(div_id,value){
  var dstDiv=_gel(div_id);
  dstDiv.innerHTML=value;
}
var onLoadFunctionList=onLoadFunctionList||[];
function performOnLoadFunctions(){
  for(var i=0;i<onLoadFunctionList.length;i++){
    onLoadFunctionList[i]();
  }
}
var onUnloadFunctionList=onUnloadFunctionList||[];
function performOnUnloadFunctions(){
  for(var i=onUnloadFunctionList.length-1;i>=0;i--){
    onUnloadFunctionList[i]();
  }
}
var addListener=function(){
  if(window.addEventListener){
    return function(el,type,fn){
      el.addEventListener(type,fn,false);
    };
  }
  else if(window.attachEvent){
    return function(el,type,fn){
      var f=function(){
        fn.call(el,window.event);
      };
      if(!el._listeners)el._listeners={};
      if(!el._listeners[type])el._listeners[type]={};
      el._listeners[type][fn]=f;
      el.attachEvent('on'+type,f);
    };
  }
  else{
    return function(el,type,fn){
      el['on'+type]=fn;
    }
  }
}();
var removeListener=function(el,type,func){
  if(el.removeEventListener){
    el.removeEventListener(type,func,false);
  }else if(el.detachEvent&&el._listeners &&el._listeners[type]&&el._listeners[type][func]){
    el.detachEvent('on'+type,el._listeners[type][func]);
  }
};
function stopPropagation(e){
  if(!e)var e=window.event;
  e.cancelBubble=true;
  if(e.stopPropagation)e.stopPropagation();
}
function buildUrl(url,params){
  var pairs=new Array();
  var result=url;
  if(params){
    for(var key in params){
      pairs.push(key+"="+encodeURIComponent(params[key].toString()));
    }
    if(pairs.length){
      result+="?"+pairs.join("&");
    }
  }
  return result;
}
function redirect(url,params,anchor){
  document.location.href=buildUrl(url,params)+(anchor?anchor:'');
}
function openPopup(url,name,height,width,opt_show_scrollbars){
  var scrollbar_param=opt_show_scrollbars?",scrollbars=1":"";
  var newwindow=window.open(url,name,'height='+height+',width='+width+scrollbar_param);
  if(newwindow&&!newwindow.opener){newwindow.opener=window;}
  if(window.focus){newwindow.focus()}
  return false;
}
function toggleClass(element,className){
  var e=ref(element);
  if(!e)return;
  if(hasClass(e,className)){ removeClass(e,className); }
    else{ addClass(e,className); }
}
function hasClass(element,_className){
  if(!element){
    return false;
  }
  var upperClass=_className.toUpperCase();
  if(element.className){
    var classes=element.className.split(' ');
    for(var i=0;i<classes.length;i++){
      if(classes[i].toUpperCase()==upperClass){
        return true;
      }
    }
  }
  return false;
}
function addClass(element,_class){
  if(!hasClass(element,_class)){
    element.className+=element.className?(" "+_class):_class;
  }
}
function removeClass(element,_class){
  var upperClass=_class.toUpperCase();
  var remainingClasses=[];
  if(element.className){
    var classes=element.className.split(' ');
    for(var i=0;i<classes.length;i++){
      if(classes[i].toUpperCase()!=upperClass){
        remainingClasses[remainingClasses.length]=classes[i];
      }
    }
    element.className=remainingClasses.join(' ');
  }
}

function getElementsByTagNameAndClass(tag,className,parentEl){
var array=(parentEl?parentEl:document).getElementsByTagName(tag);
var matches=[];
var re=new RegExp("\\b(?!\-)"+className+"(?!\-)\\b","");
for(var i=0;i<array.length;i++){
if(re.test(array[i].className)){
matches.push(array[i]);
}
}
return matches;
}
function showDiv(divName){
var tempDiv=ref(divName);
if(!tempDiv){
return;
}
if(hasClass(tempDiv,"wasinline")){
tempDiv.style.display="inline";
removeClass(tempDiv,"wasinline");
}else if(hasClass(tempDiv,"wasblock")){
tempDiv.style.display="block";
removeClass(tempDiv,"wasblock");
}else{
var n=tempDiv.nodeName.toLowerCase();
tempDiv.style.display=(n=="span"||n=="img"||n=="a")?"inline":(n=='tr'||n=='td'?"":"block");
}
}
function hideDiv(divName){
var tempDiv=ref(divName);
if(!tempDiv){
return;
}
if(tempDiv.style.display=="inline"){
addClass(tempDiv,"wasinline");
}else if(tempDiv.style.display=="block"){
addClass(tempDiv,"wasblock");
}
tempDiv.style.display="none";
}
function hideDivAfter(divName,delay){
window.setTimeout(function(){
hideDiv(divName)
},delay);
}
function setDisplay(el,visible){
if(visible){
showDiv(el);
}else{
hideDiv(el);
}
}
function toggleDisplay(divName){
var tempDiv=ref(divName);
if(!tempDiv){
return false;
}
if((tempDiv.style.display=="block")||(tempDiv.style.display==""&&hasClass(tempDiv,"hid"))){
tempDiv.style.display="none";
return false;
}else if((tempDiv.style.display=="none")||!hasClass(tempDiv,"hid")){
tempDiv.style.display="block";
return true;
}
}
function toggleDisplay2(){
var elements=Array.prototype.slice.call(arguments);
arrayEach(elements,function(arg){
var element=ref(arg);
if(element){
element.style.display=(element.style.display!="none"?"none":"");
}
});
}
function setVisible(divName,onOrOff){
var tempDiv=ref(divName);
if(!tempDiv){
return;
}
if(onOrOff){
tempDiv.style.visibility="visible";
}else{
tempDiv.style.visibility="hidden";
}
}
function _hbLink(a,b){
if(gIsGoogleAnalyticsEnabled){
urchinTracker('/'+a+'/'+b);
}else{
return false;
}
}
function urchinTracker(a){}
function urchinTrackerDefer(a){
if(!gIsGoogleAnalyticsEnabled){
return;
}
var func=function(){urchinTracker(a)};
onLoadFunctionList.push(func);
}
var __eventsPageTracker;
var __gaTrackers={};
function trackEvent(objName,eventName,opt_label,opt_value){
var gaTracker=__gaTrackers[objName];
if(!gaTracker){
if(!__eventsPageTracker){
return;
}
gaTracker=__eventsPageTracker._createEventTracker(objName);
__gaTrackers[objName]=gaTracker;
}
if(opt_label==""){
opt_label=undefined;
}
if(opt_value==""){
opt_value=undefined;
}
gaTracker._trackEvent(eventName,opt_label,opt_value);
}
function canPlayV9Swf(){
var flashPlayerVersion=deconcept.SWFObjectUtil.getPlayerVersion();
if(flashPlayerVersion.major<9){
return false;
}
var isSonyMylo=navigator.userAgent.indexOf("Sony/COM2")>-1;
if(isSonyMylo){
if(!flashPlayerVersion.versionIsValid(new deconcept.PlayerVersion([9,1,58]))){
return false;
}
}
return true;
}
var dropdownMenu={};
function dropdown(e,menuId,parentId,eventType){
hideDropdown();
dropdownMenu.id=menuId;
dropdownMenu.parentId=(parentId)?parentId:_gel(menuId).parentNode.id;
dropdownMenu.eventType=(eventType)?eventType:"click";
stopPropagation(e);
showDiv(dropdownMenu.id);
addClass(_gel(dropdownMenu.parentId),'show-dropdown');
}
function hideDropdown(){
if(dropdownMenu.id){
hideDiv(dropdownMenu.id);
removeClass(_gel(dropdownMenu.parentId),'show-dropdown');
dropdownMenu={};
}
}
addListener(document,"click",function(e){
hideDropdown();
});
addListener(document,"mouseover",function(e){
var el=e.target||e.srcElement;
if(dropdownMenu&&dropdownMenu.eventType&&dropdownMenu.parentId){
if(e.type.indexOf(dropdownMenu.eventType)!=-1&&!hasAncestor(el,dropdownMenu.parentId))
hideDropdown();
}
});
function toggleSimpleTooltip(el,show){
while(el){
if(el.className&&el.className.indexOf('tooltip-wrapper-box')!=-1){
if(show){
showDiv(el);
}else{
hideDiv(el);
}
break;
}
el=el.nextSibling;
}
}
function disableButton(button_id,opt_clear_onclick){
var button=ref(button_id);
if(button){
button.disabled=true;
if(opt_clear_onclick){
button.onclick=null;
}
}
}
function truncate(text,opt_max_length){
var max_length=opt_max_length;
if(!max_length){
max_length=30;
}
if(text.length>max_length-3){
return text.substring(0,max_length-3)+"...";
}
return text;
}
function UTRating(ratingElementId,maxStars,objectName,formName,ratingMessageId,componentSuffix,size,messages,starCount,callback)
{
this.ratingElementId=ratingElementId;
this.maxStars=maxStars;
this.objectName=objectName;
this.formName=formName;
this.ratingMessageId=ratingMessageId
this.componentSuffix=componentSuffix
this.messages=messages;
this.callback=callback;
this.starTimer=null;
this.starCount=0;
if(starCount){
this.starCount=starCount;
var that=this;
onLoadFunctionList.push(function(){that.drawStars(that.starCount,true);});
}
if(size=='S'){
UTRating.ut_rating_img='icn_star_full_11x11'
UTRating.ut_rating_img_half='icn_star_half_11x11'
UTRating.ut_rating_img_bg='icn_star_empty_11x11'
}
}
UTRating.prototype.ratingElementId=null;
UTRating.prototype.maxStars=null;
UTRating.prototype.objectName=null;
UTRating.prototype.formName=null;
UTRating.prototype.ratingMessageId=null;
UTRating.prototype.componentSuffix=null;
UTRating.prototype.messages=null;
UTRating.prototype.callback=null;
UTRating.prototype.starTimer=null;
UTRating.prototype.starCount=null;
UTRating.prototype.savedMessage=null;
UTRating.prototype.showStars=function(starNum,skipMessageUpdate){
this.clearStarTimer();
this.greyStars();
this.colorStars(starNum);
if(!skipMessageUpdate)
this.setMessage(starNum,this.messages);
}
UTRating.prototype.setMessage=function(starNum){
if(starNum>0){
if(!this.savedMessage){
this.savedMessage=_gel(this.ratingMessageId).innerHTML;
}
_gel(this.ratingMessageId).innerHTML=this.messages[starNum-1];
}else if(this.savedMessage){
_gel(this.ratingMessageId).innerHTML=this.savedMessage;
}
}
UTRating.prototype.colorStars=function(starNum){
var fullStars=Math.floor(starNum+0.25);
var halfStar=(starNum-fullStars>0.25);
for(var i=0;i<fullStars;i++){
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_half);
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_bg);
addClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img);
}
if(halfStar){
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img);
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_bg);
addClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_half);
}
}
UTRating.prototype.greyStars=function(){
for(var i=0;i<this.maxStars;i++){
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img);
removeClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_half);
addClass(_gel('star_'+this.componentSuffix+"_"+(i+1)),UTRating.ut_rating_img_bg);
}
}
UTRating.prototype.setStars=function(starNum){
this.starCount=starNum;
this.drawStars(starNum);
document.forms[this.formName]['rating'].value=this.starCount;
var ratingElementId=this.ratingElementId;
var that=this;
postForm(this.formName,true,function(req){
replaceDivContents(req,ratingElementId);
var pmsTokenNode=_gel('rating_notify_token');
var pmsToken=pmsTokenNode&&pmsTokenNode.value;
if(that.callback){
that.callback();
}
if(typeof pmsForwarder!='undefined'&&pmsToken){
pmsForwarder.ratedVideo(pmsToken);
}
});
}
UTRating.prototype.drawStars=function(starNum,skipMessageUpdate){
this.starCount=starNum;
this.showStars(starNum,skipMessageUpdate);
}
UTRating.prototype.clearStars=function(){
this.starTimer=window.setTimeout(this.objectName+".resetStars()",300);
}
UTRating.prototype.resetStars=function(){
this.clearStarTimer();
if(this.starCount)
this.drawStars(this.starCount);
else
this.greyStars();
this.setMessage(0);
}
UTRating.prototype.clearStarTimer=function(){
if(this.starTimer){
window.clearTimeout(this.starTimer);
this.starTimer=null;
}
}
UTRating.ut_rating_img='icn_star_full_19x20';
UTRating.ut_rating_img_half='icn_star_half_19x20';
UTRating.ut_rating_img_bg='icn_star_empty_19x20';
function isIE()
{
return/msie/i.test(navigator.userAgent);
}
function getXmlHttpRequest()
{
var httpRequest=null;
try
{
httpRequest=new ActiveXObject("Msxml2.XMLHTTP");
}
catch(e)
{
try
{
httpRequest=new ActiveXObject("Microsoft.XMLHTTP");
}
catch(e)
{
httpRequest=null;
}
}
if(!httpRequest&&typeof XMLHttpRequest!="undefined")
{
httpRequest=new XMLHttpRequest();
}
return httpRequest;
}
function getUrlSync(url)
{
return getUrl(url,false,null);
}
function getUrlAsync(url,handleStateChange)
{
return getUrl(url,true,handleStateChange);
}
function getUrl(url,async,opt_handleStateChange){
var xmlHttpReq=getXmlHttpRequest();
if(!xmlHttpReq)
return;
if(opt_handleStateChange)
{
xmlHttpReq.onreadystatechange=function()
{
opt_handleStateChange(xmlHttpReq);
};
}
else
{
xmlHttpReq.onreadystatechange=function(){;}
}
xmlHttpReq.open("GET",url,async);
xmlHttpReq.send(null);
}
function postUrl(url,data,async,stateChangeCallback)
{
var xmlHttpReq=getXmlHttpRequest();
if(!xmlHttpReq)
return;
xmlHttpReq.open("POST",url,async);
xmlHttpReq.onreadystatechange=function()
{
stateChangeCallback(xmlHttpReq);
};
xmlHttpReq.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
xmlHttpReq.send(data);
}
function urlEncodeDict(dict)
{
var result="";
for(var i=0;i<dict.length;i++){
result+="&"+encodeURIComponent(dict[i].name)+"="+encodeURIComponent(dict[i].value);
}
return result;
}
function XMLResponseCallback(successCallback,opt_errorCallback){
if(typeof successCallback=="object"&&successCallback!=null&&successCallback.onSuccessCallback!=undefined){
this.onSuccessCallback=successCallback.onSuccessCallback;
this.onErrorCallback=successCallback.onErrorCallback;
}else if(typeof successCallback=="function"){
this.onSuccessCallback=successCallback;
this.onErrorCallback=opt_errorCallback;
}
}
XMLResponseCallback.prototype={
onSuccessCallback:null,
onErrorCallback:null,
onSuccess:function(xmlHttpReq){
if(this.onSuccessCallback!=null){
this.onSuccessCallback(xmlHttpReq);
}
},
onError:function(xmlHttpReq){
if(this.onErrorCallback!=null){
this.onErrorCallback(xmlHttpReq);
}
}
};
function XMLResponseCallbackJSON(callback){
var cb=new XMLResponseCallback(callback);
this.onSuccessCallback=function(xmlHttpReq){
cb.onSuccess(eval(getNodeValue(getRootNode(xmlHttpReq),"html_content")));
};
this.onErrorCallback=function(xmlHttpReq){
cb.onError(eval(getNodeValue(getRootNode(xmlHttpReq),"html_content")));
};
}
function execOnSuccess(stateChangeCallback,opt_successCallback,opt_divId)
{
return function(xmlHttpReq)
{
if(xmlHttpReq.readyState==4&&
xmlHttpReq.status==200){
if(opt_divId){
stateChangeCallback(xmlHttpReq,opt_successCallback,opt_divId);
}else{
stateChangeCallback(xmlHttpReq,opt_successCallback);
}
}
};
}
function postFormByForm(form,async,successCallback){
var formVars=new Array();
for(var i=0;i<form.elements.length;i++)
{
var formElement=form.elements[i];
if((formElement.type=='radio'||formElement.type=='checkbox')&&!formElement.checked){
continue;
}
var v=new Object;
v.name=formElement.name;
v.value=formElement.value;
formVars.push(v);
}
postUrl(form.action,urlEncodeDict(formVars),async,execOnSuccess(successCallback));
}
function postForm(formName,async,successCallback)
{
var form=document.forms[formName];
return postFormByForm(form,async,successCallback);
}
function replaceDivContents(xmlHttpRequest,dstDivId)
{
var dstDiv=_gel(dstDivId);
dstDiv.innerHTML=xmlHttpRequest.responseText;
}
function getUrlXMLResponseCallback(xmlHttpReq,successCallback){
var callback=new XMLResponseCallback(successCallback);
if(xmlHttpReq.responseXML==null){
alert("Error while processing your request.");
return;
}
var root_node=getRootNode(xmlHttpReq);
var return_code=getNodeValue(root_node,'return_code');
if(return_code==0){
var redirect_val=getNodeValue(root_node,'redirect_on_success');
if(redirect_val!=null){
window.location=redirect_val;
}else{
var success_message=getNodeValue(root_node,'success_message');
if(success_message!=null){
alert(success_message);
}
callback.onSuccess(xmlHttpReq);
}
}else{
var error_msg=getNodeValue(root_node,'error_message');
if(error_msg!=null){
alert(error_msg)
}
callback.onError(xmlHttpReq);
if(!callback.onErrorCallback&&!error_msg){
alert("An error occured while performing this operation.");
}
}
}
function getUrlXMLResponseCallbackFillDiv(xmlHttpReq,successCallback,div_id){
getUrlXMLResponseCallback(xmlHttpReq,successCallback);
_gel(div_id).innerHTML=getNodeValue(xmlHttpReq.responseXML,"html_content");
}
function getUrlXMLResponseFillDivCallback(xmlHttpReq,successCallback,div_id){
_gel(div_id).innerHTML=getNodeValue(xmlHttpReq.responseXML,"html_content");
getUrlXMLResponseCallback(xmlHttpReq,successCallback);
}
function getUrlXMLResponseCallbackJSON(xmlHttpReq,successCallback){
getUrlXMLResponseCallback(xmlHttpReq,new XMLResponseCallbackJSON(successCallback));
}
function getNodeValue(obj,tag)
{
var node=obj.getElementsByTagName(tag);
if(node!=null&&node.length>0&&node[0].firstChild){
return node[0].firstChild.nodeValue;
}else{
return null;
}
}
function getRootNode(xmlHttpReq){
return xmlHttpReq.responseXML.getElementsByTagName('root')[0];
}
function getUrlXMLResponse(url,successCallback){
getUrl(url,true,execOnSuccess(getUrlXMLResponseCallback,successCallback))
}
function getUrlXMLResponseAndFillDiv(url,div_id,opt_successCallback){
getUrl(url,true,execOnSuccess(getUrlXMLResponseCallbackFillDiv,opt_successCallback,div_id))
}
function getUrlXMLResponseFillDivThenCallback(url,div_id,opt_successCallback){
getUrl(url,true,execOnSuccess(getUrlXMLResponseFillDivCallback,opt_successCallback,div_id))
}
function getUrlXMLResponseJSON(url,successCallback){
getUrl(url,true,execOnSuccess(getUrlXMLResponseCallbackJSON,successCallback))
}
getUrlXMLResponseJSON.prototype.getUrlXMLResponseCallbackJSON=getUrlXMLResponseCallbackJSON;
getUrlXMLResponseJSON.prototype.getUrlXMLResponseCallback=getUrlXMLResponseCallback;
function postUrlXMLResponse(url,data,successCallback){
postUrl(url,data,true,execOnSuccess(getUrlXMLResponseCallback,successCallback))
}
function postUrlXMLResponseJSON(url,data,successCallback){
postUrl(url,data,true,execOnSuccess(getUrlXMLResponseCallbackJSON,successCallback))
}
function postUrlXMLResponseAndFillDiv(url,data,div_id,successCallback){
postUrl(url,data,true,execOnSuccess(getUrlXMLResponseCallbackFillDiv,successCallback,div_id))
}
function confirmAndPostUrlXMLResponse(url,confirmMessage,data,successCallback){
if(confirm(confirmMessage)){
postUrlXMLResponse(url,data,successCallback);
}
}
function postFormXMLResponse(formName,successCallback){
postForm(formName,true,execOnSuccess(getUrlXMLResponseCallback,successCallback))
}
function handleStylesheetAndJavascriptContent(req){
var rootNode=getRootNode(req);
var css=rootNode.getElementsByTagName('css_content');
if(css.length){
css=getNodeValue(rootNode,'css_content');
var styleElement=document.createElement('style');
styleElement.setAttribute("type","text/css");
if(styleElement.styleSheet){
styleElement.styleSheet.cssText=css;
}else{
styleElement.appendChild(document.createTextNode(css));
}
document.getElementsByTagName('head')[0].appendChild(styleElement);
}
var js=rootNode.getElementsByTagName('js_content');
if(js.length){
js=getNodeValue(rootNode,'js_content');
var scriptElement=document.createElement('script');
scriptElement.text=js;
document.getElementsByTagName('head')[0].appendChild(scriptElement);
}
}
function showAjaxDivLoggedIn(divName,url,opt_callback){
getUrlXMLResponse(url,showAjaxDivResponseLater(divName,opt_callback));
}
function showAjaxPostDivLoggedIn(divName,url,data,opt_callback){
postUrlXMLResponse(url,data,showAjaxDivResponseLater(divName,opt_callback));
}
var showAjaxDivNotLoggedIn=showAjaxDivLoggedIn;
function showAjaxDivResponseLater(divName,callback){
var callbackWrapper=new XMLResponseCallback(callback);
return new XMLResponseCallback(
function(req){
handleStylesheetAndJavascriptContent(req);
var nodeValue=getNodeValue(req.responseXML,"html_content");
_gel(divName).innerHTML=nodeValue?nodeValue:'';
callbackWrapper.onSuccess(req);
},
function(req){
callbackWrapper.onError(req);
}
);
}
function postAjaxForm(divName,formName,opt_successCallback){
postFormXMLResponse(formName,closeAjaxDivLater(divName,opt_successCallback));
}
function closeAjaxDivLater(divName,callback){
var callbackWrapper=new XMLResponseCallback(callback);
return new XMLResponseCallback(
function(req){
hideDiv(divName);
callbackWrapper.onSuccess(req);
},
function(req){
hideDiv(divName);
callbackWrapper.onError(req);
}
);
}
function setFlashVars(myObjName){
var pvaTag=_gel("pvaTag").value;
_gel("FLASH_"+myObjName).SetVariable("myAdTag",pvaTag);
var canv=_gel("canv").value;
_gel("FLASH_"+myObjName).SetVariable("canv",canv);
var burl=_gel("burl").value;
_gel("FLASH_"+myObjName).SetVariable("dc_PVAurl",burl);
var hl=_gel("pvaHl").value;
_gel("FLASH_"+myObjName).SetVariable("hl",hl);
var yurl=_gel("yeurl").value;
var yeurl=_gel("yeurl").value;
_gel("FLASH_"+myObjName).SetVariable("yeurl",yeurl);
var tdl=_gel("tdl").value;
_gel("FLASH_"+myObjName).SetVariable("BASE_YT_URL",tdl);
_gel("FLASH_"+myObjName).SetVariable("rtg","1");
}
function pyv_google_ad_request_done(ads){
var sv_label=window.pyv_google_ad_sv_label||"Sponsored Videos";
var placeholder_id=window.pyv_google_ad_placeholder_id||"pyv-yva-placeholder";
var collapse_id=window.pyv_google_ad_collapse_id||false;
for(var i=0;i<ads.length;i++){
ads[i]['username']=ads[i]['visible_url'].substring(ads[i]['visible_url'].lastIndexOf('/')+1);
var m=ads[i]['url'].match(/watch%3Fv%3D(\w*)%26feature%3Dpyv/);
ads[i]['video_id']=(m[1]?m[1]:'hTffb8OF8_U');
}
var html='';
if(ads.length>1){
for(var i=0;i<ads.length;i++){
var ad=ads[i];
ad['thumbnail_url']='http://img.youtube.com/vi/'+ad['video_id']+'/default.jpg';
html+='<div'+(i<ads.length-1?' style="margin-bottom: 20px;"':'')+'>'
+'<table width="100%" cellspacing="0" cellpadding="0">'
+'<tr style="vertical-align: top;"><td class="spons-vid-thumb">'
+'<div class="v120WrapperOuter"><div class="v120WrapperInner">'
+'<a title="'+ad['line1']+'" href="'+ad['url']+'">'
+'<img src="'+ad['thumbnail_url']+'" alt="'+ad['line1']+'" class="vimg120"/></a></div></div>'
+'</td><td style="width: 4px;"></td><td valign="top" style="padding-top: 2px;">'
+'<a style="font-weight: bold;" href="'+ad['url']+'">'+ad['line1']+'</a><br/>'
+'<div>'+ad['line2']+'&nbsp;'+ad['line3']+'</div>'
+'<a href="'+ad['url']+'" style="font-size: 11px;">'+ad['username']+'</a>'
+'</td></tr></tbody></table></div>';
}
html='<div style="padding: 6px 4px; border: 1px solid #CCC;">'+html+'</div>'
}else{
var ad=ads[0];
ad['thumbnail_url']='http://img.youtube.com/vi/'+ad['video_id']+'/hqdefault.jpg';
html+='<div>'
+'<a title="'+ad['line1']+'" href="'+ad['url']+'">'
+'<img src="'+ad['thumbnail_url']+'" alt="'+ad['line1']+'" width="298" height="223"/></a>'
+'<div style="padding: 15px 6px;">'
+'<a style="font-weight: bold;" href="'+ad['url']+'">'+ad['line1']+'</a><br/>'
+'<div>'+ad['line2']+'<br>'+ad['line3']+'</div>'
+'<a href="'+ad['url']+'" style="font-size: 11px;">'+ad['username']+'</a>'
+'</div></div>';
html='<div style="border: 1px solid #CCC; background-color: #EEE;">'+html+'</div>'
}
if(collapse_id){
collapse_element(collapse_id);
}
var pypel=document.getElementById(placeholder_id);
if(html.length&&pypel){
pypel.innerHTML=html+'<div class="alignC grayText" style="font-size: 10px; padding: 3px 0 15px 0">'+sv_label+'</div>';
}
}
function collapse_element(collapse_id){
var to_collapse=document.getElementById(collapse_id);
if(to_collapse){
to_collapse.style.display='none';
}
}
function requestPyvAfsAds(){
collapse_element('ad_creative_1');
if(!in_pyv_afs_exp){
return;
}
document.write('<script language="JavaScript" src="/pyv_ads" type="text/javascript"></script>');
}
function pyvAfsRequestCallback(pyv_ad_html){
var pyv_yva_div=document.getElementById('pyv-yva-placeholder');
if(pyv_ad_html.length&&pyv_yva_div){
pyv_yva_div.innerHTML=pyv_ad_html+'<div class="alignC grayText" style="font-size: 10px; padding: 3px 0 15px 0">Sponsored Videos</div>';
}
}
function showCommentReplyForm_js(form_id,reply_parent_id,is_main_comment_form,messages){
if(!isLoggedIn){
window.location="/login?next="+encodeURIComponent(window.location.href);
return false;
}
printCommentReplyForm(form_id,reply_parent_id,is_main_comment_form);
}
var commentPreviewEnabled=commentPreviewEnabled||false;
function printCommentReplyForm_js(form_id,reply_parent_id,is_main_comment_form,comment_type,bidiSupport,id_field_name,id_field_value,comment_xsrf_token,maxChars,messages){
var div_id="div_"+form_id;
var reply_id="reply_"+form_id;
var reply_comment_form="comment_form"+form_id;
var maxCharLabelId="maxCharLabel"+form_id;
var charCountId="charCount"+form_id;
var discard_visible="";
if(is_main_comment_form)
discard_visible="style='display: none'";
var previewVisible="";
if(commentPreviewEnabled){
previewVisible="display: inline;";
}else{
previewVisible="display: none;";
}
var innerHTMLContent='\
	<form name="'+reply_comment_form+'" id="'+reply_comment_form+'" onSubmit="return false" method="post" action="/comment_servlet?add_comment=1&comment_type='+comment_type+'" >\
		<input type="hidden" name="'+id_field_name+'" value="'+id_field_value+'">\
		'+comment_xsrf_token+'\
		<input type="hidden" name="form_id" value="'+reply_comment_form+'">\
		<input type="hidden" name="reply_parent_id" value="'+reply_parent_id+'">\
		<textarea name="comment"  \
		cols="46" rows="5" onkeyup="updateCharCount(\''+charCountId+'\', \''+maxCharLabelId+'\', this); '+bidiSupport+'"\
		onpaste="updateCharCount(\''+charCountId+'\', \''+maxCharLabelId+'\', this);"\
		oninput="updateCharCount(\''+charCountId+'\', \''+maxCharLabelId+'\', this);"\
		></textarea>\
		<input style="vertical-align:top; margin-left: 10px;'+previewVisible+'" align="left" type="button" name="preview_comment_button" \
				value="Audio Preview" \
				onclick="previewComment(\''+reply_comment_form+'\');">\
		<br/>\
		<div style="float:left;clear:left">\
		<input align="left" type="button" name="add_comment_button"\
				value="'+messages['post']+'"\
				onclick="postThreadedComment(\''+reply_comment_form+'\');">\
		<input align="left" type="button" name="discard_comment_button"\
				value="'+messages['discard']+'" '+discard_visible+'\
				onclick="hideCommentReplyForm(\''+form_id+'\',false);">\
		<span id="'+maxCharLabelId+'">'+messages["remaining"]+'</span><input readonly="true" class="watch-comment-char-count" type="text" id="'+charCountId+'" value='+maxChars+'>\
		</div>\
	</form><br style="clear:both"><br>';
if(!is_main_comment_form){
hideDiv(reply_id);
if(reply_parent_id&&_gel("comment_body_"+reply_parent_id).style.display=="none"){
displayHideCommentLink(reply_parent_id);
}
}
setInnerHTML(div_id,innerHTMLContent);
showDiv(div_id);
}
function updateCharCount_js(charCount_id,label_id,textArea,maxChars,messages){
if(textArea.value.length>maxChars){
if(_gel(label_id).innerHTML!=messages["exceeded"]){
_gel(label_id).innerHTML=messages["exceeded"];
}
_gel(charCount_id).value=textArea.value.length-maxChars;
}else{
if(_gel(label_id).innerHTML!=messages["remaining"]){
_gel(label_id).innerHTML=messages["remaining"];
}
_gel(charCount_id).value=maxChars-textArea.value.length;
}
}
function hideCommentReplyForm(form_id){
var div_id="div_"+form_id;
var reply_id="reply_"+form_id;
showDiv(reply_id);
hideDiv(div_id);
}
function postThreadedComment_js(comment_form_id,messages){
if(isLoggedIn==false)
return false;
var form=document.forms[comment_form_id];
if(ThreadedCommentHandler(form,comment_form_id)){
var add_button=form.add_comment_button;
add_button.value=messages["add"];
form.comment.disabled=true;
add_button.disabled=true;
}
}
function ThreadedCommentHandler_js(comment_form,comment_form_id,messages){
var comment=comment_form.comment;
var comment_button=comment_form.comment_button;
if(comment.value.length==0||comment.value==null)
{
alert(messages["empty"]);
comment.disabled=false;
comment.focus();
return false;
}
if(comment.value.length>500)
{
alert(messages["toolong"]);
comment.disabled=false;
comment.focus();
return false;
}
postFormByForm(comment_form,true,commentResponse);
return true;
}
function commentResponse_js(xmlHttpRequest,messages){
var response_str=xmlHttpRequest.responseText;
var response_str_tokens=response_str.split(' ');
var response_code=response_str_tokens[0];
var form_id=response_str_tokens[1];
var pms_token=response_str_tokens[2];
var form=document.forms[form_id];
var dstDiv=form.add_comment_button;
var discard_button=form.discard_comment_button;
var commentDiv=form.comment;
if(response_code=="OK"){
dstDiv.value=messages["ok"];
dstDiv.disabled=true;
discard_button.disabled=true;
discard_button.style.display="none";
if(typeof pmsForwarder!='undefined'&&pms_token){
pmsForwarder.commentedVideo(pms_token);
}
}else if(response_code=="PENDING"){
dstDiv.value=messages["pending"]
dstDiv.disabled=true;
discard_button.disabled=true;
discard_button.style.display="none";
}else if(response_code=="LOGIN"){
dstDiv.disabled=false;
}else if(response_code=="EMAIL"){
if(confirm(messages["email"])){
window.location="/email_confirm"
}
dstDiv.disabled=false;
}else{
if(response_code=="BLOCKED"){
dstDiv.disabled=true;
}else if(response_code=="TOOSOON"){
dstDiv.disabled=false;
alert(messages["toosoon"]);
}else if(response_code=="TOOLONG"){
alert(messages["toolong"]);
dstDiv.disabled=false;
commentDiv.disabled=false;
}else if(response_code=="TOOSHORT"){
alert(messages["tooshort"]);
dstDiv.disabled=false;
commentDiv.disabled=false;
commentDiv.focus();
}else if(response_code=="FAILED"){
dstDiv.disabled=true;
}else if(response_code=="FAILADDED"){
dstDiv.disabled=true;
}else if(response_code=="CAPTCHAFAIL"){
alert(messages["catpchaFail"]);
dstDiv.disabled=false;
}else{
dstDiv.disabled=false;
}
dstDiv.value=messages["default"];
}
}
function spam(comment_id,vid_id){
postUrlXMLResponse('/comment_servlet?mark_comment_as_spam='+comment_id+"&entity_id="+vid_id,"");
displayShowCommentLink(comment_id);
hideSpam(comment_id);
}
function hideSpam(cid){
if(_gel('reply_comment_form_id_'+cid)){
_gel('reply_comment_form_id_'+cid).style.display='none';
}
if(_gel('comment_body_'+cid)){
_gel('comment_body_'+cid).style.display='none';
}
if(_gel('comment_spam_bug_'+cid)){
_gel('comment_spam_bug_'+cid).style.display='inline';
}
}
function loginMsg_js(div_id,display_val,messages){
var login_msg_div_id="comment_msg_"+div_id;
if(display_val==1){
setInnerHTML(login_msg_div_id,messages["login"]);
}
else{
setInnerHTML(login_msg_div_id,'');
}
}
function voteComment(comment_id,vid_id,comment_ref_id,increment){
var url_string="/comment_voting?a="+increment+"&id="+comment_id+"&video_id="+vid_id+"&old_vote="+comment_ref_id;
var vote_div_id="comment_vote_"+comment_id;
var comment_body="comment_body_"+comment_id;
var hide_link_id="hide_link_"+comment_id;
var show_link_id="show_link_"+comment_id;
if(_gel(vote_div_id).className=='watch-comment-voting-off'){
return;
}
getUrlXMLResponseAndFillDiv(url_string,vote_div_id);
if(increment<0){
hideDiv(comment_body);
displayShowCommentLink(comment_id);
}
showLoadingIcon(vote_div_id);
}
function showLoadingIcon(div_id){
var temp_HTML='<img src="http://s.ytimg.com/yt/img/icn_loading_animated-vfl24663.gif">';
_gel(div_id).innerHTML=temp_HTML;
}
function voteCommentHidden(comment_id,vid_id,comment_ref_id,increment){
var comment_body_div="comment_body_"+comment_id;
var vote_div_id="comment_vote_"+comment_id;
var hide_link_id="hide_link_"+comment_id;
var show_link_id="show_link_"+comment_id;
if(_gel(vote_div_id).className=='watch-comment-voting-off'){
return;
}
if(_gel(comment_body_div).style.display=='none'){
displayHideCommentLink(comment_id);
}
else{
voteComment(comment_id,vid_id,comment_ref_id,increment);
}
}
function watchExpandComments(comments_url,comments_count){
if(comments_count&&_gel('recent_comments').innerHTML==""){
showLoading('recent_comments');
getUrlXMLResponseAndFillDiv(comments_url,'recent_comments');
}
watchCommentsPanelStateChange();
}
function watchCommentsPanelStateChange(){
yt.UserPrefs.setFlag(yt.UserPrefs.Flags.FLAG_WATCH_COLLAPSE_COMMENTS_PANEL,!isPanelExpanded(_gel('watch-comment-panel')));
yt.UserPrefs.save();
}
function showLoading(div_id){
var temp_HTML="<br><br><br><br><br><center><img src=/img/icn_loading_animated.gif></center><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>";
_gel(div_id).innerHTML=temp_HTML;
document.body.focus();
}
function approveComment(comment_id,comment_type,entity_id,token){
if(isLoggedIn==false)
return false;
postUrlXMLResponse("/comment_servlet?field_approve_comment=1","comment_id="+comment_id+"&comment_type="+comment_type+"&entity_id="+entity_id+"&"+token,self.commentApproved);
return false;
}
function removeComment(div_id,deleter_user_id,comment_id,comment_type,entity_id,token){
if(isLoggedIn==false)
return;
var callback=function(){hideDiv(div_id);};
postUrlXMLResponse("/comment_servlet?remove_comment=1&comment_type="+comment_type+"&entity_id="+entity_id,"deleter_user_id="+deleter_user_id+"&comment_id="+comment_id+"&"+token,callback);
return false;
}
function unretractComment(hide_div_id,show_div_id,comment_id,comment_type,entity_id,token){
if(isLoggedIn==false)
return false;
var callback=function(){
hideDiv(hide_div_id);
showDiv(show_div_id);
};
postUrlXMLResponse("/comment_servlet?unretract_comment=1","comment_id="+comment_id+"&comment_type="+comment_type+"&entity_id="+entity_id+"&v="+entity_id+"&"+token,callback);
return false;
}
var previewCommentSwfReady=false;
var previewCommentText="";
function previewComment(form_id){
previewCommentText=_gel(form_id)['comment'].value;
var pcb=_gel(form_id)["preview_comment_button"];
var oldValue=pcb.value;
pcb.value="Audio Preview...";
pcb.disabled="disabled";
window.setTimeout(function(){
pcb.value=oldValue;
pcb.disabled="";
previewCommentAvailable=true;
},4000);
if(previewCommentSwfReady){
onPreviewCommentReady();
}else{
var previewSwf=new SWFObject('http://s.ytimg.com/yt/swf/textreader-vfl58814.swf',"preview_comment","1","1",8);
previewSwf.addParam("AllowScriptAccess","always");
if(swfArgs['BASE_YT_URL']){
previewSwf.addVariable('BASE_YT_URL',swfArgs['BASE_YT_URL']);
}
previewSwf.addVariable('t',previewCommentToken);
previewSwf.write(_gel("preview-comment-swf-div"));
}
}
var previewCommentAvailable=true;
function onPreviewCommentReady(){
if(previewCommentAvailable){
previewCommentSwfReady=true;
var text=previewCommentText.split('\n').join(' ');
_gel("preview_comment").speakText(text);
}
}
function displayHideCommentLink(comm_id){
var header_div="comment_header_"+comm_id;
var comment_body_div="comment_body_"+comm_id;
var comment_vote_div="comment_vote_"+comm_id;
var span_hide_id="hide_link_"+comm_id;
var span_show_id="show_link_"+comm_id;
showDiv(comment_body_div);
_gel(span_show_id).style.visibility='hidden';
hideDiv(span_show_id);
showDiv(span_hide_id);
_gel(span_hide_id).style.visibility='visible';
if(_gel(header_div)){
_gel(header_div).className="watch-comment-head";
}
_gel(comment_vote_div).className="watch-comment-voting";
}
function displayShowCommentLink(comm_id){
var header_div="comment_header_"+comm_id;
var comment_body_div="comment_body_"+comm_id;
var comment_vote_div="comment_vote_"+comm_id;
var span_hide_id="hide_link_"+comm_id;
var span_show_id="show_link_"+comm_id;
hideDiv(comment_body_div);
_gel(span_hide_id).style.visibility='hidden';
hideDiv(span_hide_id);
showDiv(span_show_id);
_gel(span_show_id).style.visibility='visible';
if(_gel(header_div)){
_gel(header_div).className="watch-comment-head-hidden opacity80";
}
_gel(comment_vote_div).className="watch-comment-voting-off";
}
var videoResponseCurrentIndex=0;
function rotateVideoResponses(increment,containerId,columns){
performDelayLoad('video_bar');
var box=_gel(containerId);
var responses=getElementsByTagNameAndClass('DIV','video-bar-item',box);
var hideFrom=videoResponseCurrentIndex;
for(var x=0;x<columns;++x){
if(hideFrom>=0&&hideFrom<responses.length){
hideDiv(responses[hideFrom]);
}
++hideFrom;
}
videoResponseCurrentIndex=videoResponseCurrentIndex+(increment?columns:-1*columns);
if(videoResponseCurrentIndex>=responses.length){
videoResponseCurrentIndex=0;
}else if(videoResponseCurrentIndex<0){
videoResponseCurrentIndex=responses.length-(responses.length%columns);
if(videoResponseCurrentIndex==responses.length){
videoResponseCurrentIndex=responses.length-columns;
}
}
var showFrom=videoResponseCurrentIndex;
for(var x=0;x<columns;++x){
if(showFrom>=0&&showFrom<responses.length){
showDiv(responses[showFrom]);
}
++showFrom;
}
}
function writeMoviePlayer(player_div,force,version_required){
var v="7";
var useExpressInstall=false;
if(force){
v="0";
}else if(version_required){
v=version_required;
useExpressInstall=true;
}
var fo=new SWFObject(swfUrl,"movie_player","480","385",v,"#000000");
if(useExpressInstall&&typeof(expressInstallUrl)!="undefined"){
fo.useExpressInstall(expressInstallUrl);
}
fo.addParam("allowFullscreen","true");
if(window!=window.top){
function checkRef(ref){
var a=ref.split('/',3);
if(a.length>=3&&a[0]=='http:'&&a[1]==''){
a=a[2].split('.').reverse();
if(a.length<2)return false;
var d0=a[0];
var d1=a[1];
if(d1=='youtube'&&d0=='com')return true;
if(d1=='google')return true;
if(a.length<3)return false;
if(a[2]=='google'&&((d1=='co'&&d0=='uk')||(d1=='com'&&d0=='au')))return true;
}
return false;
}
var frameref=document.referrer.substring(0,128);
if(!checkRef(frameref)){
swfArgs.framer=encodeURIComponent(frameref);
}
}
for(var x in swfArgs){
fo.addVariable(x,swfArgs[x]);
}
if(watchGamUrl!=null){
fo.addVariable("gam",watchGamUrl);
}
if(watchDCUrl!=null){
fo.addVariable("ad_tag",watchDCUrl);
}
if(!watchIsPlayingAll){
fo.addVariable("playnext",0);
}
if(watchSetWmode){
fo.addParam("wmode","opaque");
}
if(ad_eurl){
fo.addVariable("ad_eurl",ad_eurl);
}
fo.addVariable("enablejsapi",1);
fo.addParam("AllowScriptAccess","always");
player_written=fo.write(player_div);
return fo;
}
function openFull(){
var fs=window.open(fullscreenUrl,
"FullScreenVideo","toolbar=no,width="+screen.availWidth+",height="+screen.availHeight
+",status=no,resizable=yes,fullscreen=yes,scrollbars=no");
fs.focus();
}
function checkCurrentVideo(videoId,offset){
if(playnextFrom&&watchIsPlayingAll){
if(window.randomVideoId){
if(pageVideoId!=randomVideoId){
var newUrl=window.location.href.replace(/v=[^&#]*/,"v="+videoId);
newUrl=newUrl.replace(/&index=[0-9]*/,'');
window.location=newUrl;
}
}else{
var row;
if(typeof(offset)!="undefined"){
row=getNextListRow(false,offset);
}else{
row=findPlaylistRowByVideoId(videoId,playnextFrom);
}
window.location=getUrlFromPlaylistRow(row);
}
}else{
if(pageVideoId!=videoId){
window.location.href="/watch?v="+videoId;
}
}
}
function trackAnnotationsEvent(action,opt_label,opt_value){
annotationsTracker._trackEvent(action,opt_label,opt_value);
}
var g_YouTubePlayerIsReady=false;
function onYouTubePlayerReady(playerId){
g_YouTubePlayerIsReady=true;
var player=_gel("movie_player");
player.addEventListener("onStateChange","handleWatchPagePlayerStateChange");
player.addEventListener("onPlaybackQualityChange","onPlayerFormatChanged");
onPlayerFormatChanged(player.getPlaybackQuality());
}
function handleWatchPagePlayerStateChange(newState){
if(newState==0){
try{
autoGotoNextVideoOnVideoDone();
}catch(err){
if(watchIsPlayingAll){
gotoNext();
}
}
}
}
var widePlayerMode=false;
function toggleWidePlayer(newMode){
var thisVidDiv=_gel('watch-this-vid');
var otherVidsDiv=_gel('watch-other-vids');
if(newMode!=widePlayerMode){
widePlayerMode=newMode;
if(widePlayerMode){
addClass(thisVidDiv,"watch-wide-mode");
addClass(otherVidsDiv,"watch-wide-mode");
}else{
removeClass(thisVidDiv,"watch-wide-mode");
removeClass(otherVidsDiv,"watch-wide-mode");
}
}
}
yt.VideoQualityConstants={
AUTO:0,
LOW:1,
HIGH:2
}
var videoQualityDisplayEnabled=false;
var lastReportedVideoQuality=null;
function enableVideoQualityDisplay(){
videoQualityDisplayEnabled=true;
if(lastReportedVideoQuality!=null){
onPlayerFormatChanged(lastReportedVideoQuality);
}
}
function onPlayerFormatChanged(vq){
if(!videoQualityDisplayEnabled){
lastReportedVideoQuality=vq;
return;
}
var videoQualitySettingsElm=_gel("watch-video-quality-setting");
if(videoQualitySettingsElm&&vq&&vq!=yt.VideoQualityConstants.AUTO){
removeClass(videoQualitySettingsElm,"high");
removeClass(videoQualitySettingsElm,"low");
if(vq==yt.VideoQualityConstants.HIGH){
setTimeout(function(){addClass(videoQualitySettingsElm,"high");},0);
}else if(vq==yt.VideoQualityConstants.LOW){
setTimeout(function(){addClass(videoQualitySettingsElm,"low");},0);
}
if(isHDAvailable){
toggleWidePlayer(vq==yt.VideoQualityConstants.HIGH);
}
}
}
function movie_player_DoFSCommand(command,args){
if(command=="onPlayerFormatChanged"){
onPlayerFormatChanged(args);
}
}
function changeVideoQuality(quality){
var p=_gel("movie_player");
p.setPlaybackQuality(quality);
}
function seekTo(time){
var p=_gel("movie_player");
p.seekTo(time,true);
smoothScrollIntoView(p,50);
p.playVideo();
}
var g_currentHashValue='';
var g_currentHashArgs={};
function pollLocationHash(){
if(!g_YouTubePlayerIsReady){
return;
}
var newHashValue=document.location.hash.substr(1);
if(newHashValue!=g_currentHashValue){
g_currentHashValue=newHashValue;
var newHashArgs=parseHashArgs(newHashValue);
if(newHashArgs['t']&&newHashArgs['t']!=g_currentHashArgs['t']){
var time=hashTextToTime(newHashArgs['t']);
if(time!=null){
var p=_gel("movie_player");
p.seekTo(time,true);
p.playVideo();
}
}
g_currentHashArgs=newHashArgs;
}
}
window.setInterval(pollLocationHash,1000);
function parseHashArgs(hashText){
var parts=hashText.split("&");
var args={};
for(var i=0;i<parts.length;i++){
var nameValue=parts[i].split('=');
if(nameValue.length==2){
args[nameValue[0]]=nameValue[1];
}
}
return args;
}
function hashTextToTime(hashText){
var hashTime=0;
var temp;
if(hashText.indexOf('h')!=-1){
temp=hashText.split('h');
hashTime=(temp[0]*60*60);
hashText=temp[1];
}
if(hashText.indexOf('m')!=-1){
temp=hashText.split('m');
hashTime=(temp[0]*60)+hashTime;
hashText=temp[1];
}
if(hashText.indexOf('s')!=-1){
temp=hashText.split('s');
hashTime=(temp[0]*1)+hashTime;
}else{
hashTime=(hashText*1)+hashTime;
}
return hashTime;
}
function watchSelectTab(tab){
var el=tab.parentNode.firstChild;
while(el){
removeClass(el,'watch-tab-sel');
el=el.nextSibling;
}
addClass(tab,'watch-tab-sel');
el=_gel(tab.id+'-body').parentNode.firstChild;
while(el){
removeClass(el,'watch-tab-sel');
el=el.nextSibling;
}
addClass(_gel(tab.id+'-body'),'watch-tab-sel');
var anchor=tab.getElementsByTagName('A');
anchor[0].blur();
}
function selectMoreFrom(tab){
var el=tab.parentNode.firstChild;
while(el){
removeClass(el,'more-from-selected');
el=el.nextSibling;
}
addClass(tab,'more-from-selected');
el=_gel(tab.id+'-body').parentNode.firstChild;
while(el){
addClass(el,'hidden');
el=el.nextSibling;
}
removeClass(_gel(tab.id+'-body'),'hidden');
if(tab.id=='watch-channel-vids'){
fireInlineEvent(tab,'expanded');
}
}
function resetSharing(){
hideDiv('watch-share-video-div');
hideDiv('shareMessageQuickDiv');
hideDiv('watch-share-blog-quick');
showDiv('aggregationServicesDiv');
toggleMoreShare('fewer-options','more-options');
}
function toggleMoreShare(hide,show){
hideDiv(hide);
showDiv(show);
}
function processShareVideo(eVideoID,divID,component,opt_logging){
shareVideo(eVideoID,divID,component);
showDiv('aggregationServicesDiv');
toggleMoreShare('more-options','fewer-options');
getUrl("/sharing_services?name=MORE_SHARING_OPTIONS&v="+eVideoID+(opt_logging?'&'+opt_logging:''));
return false;
}
function shareVideo(videoId,divID,component,opt_blogInfoID){
var locale=window.ytLocale||'en_US';
var el=_gel(divID);
var action='video_id='+videoId;
if(component=='all'&&locale){
closeShareAll(divID);
toggleDisplay(divID);
toggleMoreShare('more-options','fewer-options');
action=action+'&locale='+locale+'&action_get_share_video_component=1';
}else if(component=='email'){
closeMoreShareIfOpen();
closeShareAll(divID);
toggleDisplay(divID);
action=action+'&action_get_share_message_component=1';
}else if(component=='blog'&&opt_blogInfoID){
closeMoreShareIfOpen();
closeShareAll(divID);
toggleDisplay(divID);
action=action+'&blog_info_id='+opt_blogInfoID+'&action_get_share_blog_component=1';
}
showDiv('aggregationServicesDiv');
if(el.style.display!="none"){
if(el.loaded===undefined){
var onSuccess=function(){
el.loaded=true;
if(opt_blogInfoID){
el.currBlog=opt_blogInfoID;
}
}
var onFailure=function(){
el.loaded=undefined;
hideDiv(divID);
}
showAjaxDivLoggedIn(divID,'/watch_ajax?'+action,new XMLResponseCallback(onSuccess,onFailure));
}
else if(opt_blogInfoID){
if(el.currBlog!=opt_blogInfoID){
showAjaxDivLoggedIn(divID,'/watch_ajax?'+action,true);
el.currBlog=opt_blogInfoID;
}
}
urchinTracker('/Events/VideoWatch/ShareVideo/'+component);
}
if(isLoggedIn){
urchinTracker('/Events/VideoWatch/ActionTab/ShareVideo/Loggedin');
}else{
urchinTracker('/Events/VideoWatch/ActionTab/ShareVideo/Loggedout');
}
}
function closeShareAll(except){
var divs=['watch-share-video-div','watch-share-blog-quick','shareMessageQuickDiv','shareVideoEmailDiv'];
for(var i=0;i<divs.length;i++){
if((divs[i]!=except)&&(_gel(divs[i]))){
var theDiv=_gel(divs[i]);
if(theDiv){
theDiv.style.display="none";
}
}
}
}
function closeMoreShareIfOpen(){
if((_gel('watch-share-video-div').style.display!='none')){
toggleMoreShare('fewer-options','more-options');
}
}
function shareVideoClose(){
if(_gel('watch-share-video-div').style.display!="none"){
toggleDisplay('watch-share-video-div');
}else{
toggleDisplay('shareMessageQuickDiv');
}
toggleMoreShare('fewer-options','more-options');
toggleDisplay('shareVideoResult');
hideDivAfter('shareVideoResult',3000);
}
function recordServiceUsage(service_name,video_id,locale,opt_logging){
getUrl("/sharing_services?name="+encodeURIComponent(service_name)+"&v="+video_id+"&locale="+locale+(opt_logging?'&'+opt_logging:''),true);
}
function shareVideoFromFlash(){
watchSelectTab(_gel('watch-tab-share'));
urchinTracker('/Events/VideoWatch/ShareVideoFromFlash');
if(hasClass(_gel('watch-tab-share'),'watch-tab-sel')&&_gel('watch-share-video-div').style.display!='block'){
processShareVideo(pageVideoId,'watch-share-video-div','all');
}else{
resetSharing();
}
smoothScrollIntoView(_gel("watch-share-video-div"),20);
}
var scrollStep=100;
var scrollStepDelay=50;
function smoothScrollIntoView(node,padding){
if(!padding){
padding=0;
}
smoothScrollIntoViewWorker(node,padding,null);
}
function smoothScrollIntoViewWorker(node,padding,lastTop){
var nodeTop=getPageOffsetTop(node);
var currentTop=getBodyScrollTop();
var deltaTop=0;
if(currentTop<nodeTop){
deltaTop=Math.min(nodeTop-currentTop-padding,scrollStep);
}else{
deltaTop=Math.max(nodeTop-currentTop-padding,scrollStep*-1);
}
window.scrollBy(0,deltaTop);
if(currentTop!=lastTop){
window.setTimeout(function(){smoothScrollIntoViewWorker(node,padding,currentTop)},scrollStepDelay);
}
}
function getPageOffsetTop(element){
var curtop=0;
if(element.offsetParent){
curtop=element.offsetTop;
while(element=element.offsetParent){
curtop+=element.offsetTop;
}
}
return curtop;
}
function getBodyScrollTop(){
if(window.innerHeight){
return window.pageYOffset;
}else if(document&&document.documentElement&&document.documentElement.scrollTop){
return document.documentElement.scrollTop;
}else if(document&&document.body){
return document.body.scrollTop;
}
}
function addToFaves(formName,event){
watchSelectTab(_gel('watch-tab-favorite'));
if(isLoggedIn){
showDiv('watch-add-faves-loading');
hideDiv('watch-add-faves-result');
hideDiv('watch-remove-faves');
hideDiv('watch-add-faves');
hideDiv('watch-add-to-faves-switch');
hideDiv('watch-remove-faves-wrapper');
hideDiv('watch-add-faves-wrapper');
var onSuccess=function(xmlHttpReq){
var pms_token=getNodeValue(getRootNode(xmlHttpReq),"notify_token");
if(typeof pmsForwarder!='undefined'&&pms_token){
pmsForwarder.favoritedVideo(pms_token);
}
showDiv('watch-add-faves-result');
showDiv('watch-remove-faves');
hideDiv('watch-add-faves');
showDiv('watch-add-to-faves-switch');
showDiv('watch-remove-faves-wrapper');
hideDiv('watch-add-faves-wrapper');
hideDiv('watch-add-faves-loading');
};
var onFailure=function(){
hideDiv('watch-add-faves');
hideDiv('watch-add-faves-wrapper');
hideDiv('watch-add-faves-loading');
watchSelectTab(_gel('watch-tab-share'));
};
postAjaxForm('watch-add-faves-div',formName,
new XMLResponseCallback(onSuccess,onFailure));
_gel('watch-action-favorite-link').blur();
urchinTracker('/Events/VideoWatch/ActionTab/AddToFavs/Loggedin');
}
else{
showDiv('addToFavesLogin');
urchinTracker('/Events/VideoWatch/ActionTab/AddToFavs/Loggedout');
}
}
function removeFromFaves(formName,event){
showDiv('watch-add-faves');
hideDiv('watch-remove-faves');
showDiv('watch-add-faves-wrapper');
hideDiv('watch-remove-faves-wrapper');
postAjaxForm('watch-remove-faves-div',formName);
_gel('watch-action-favorite-link').blur();
urchinTracker('/Events/VideoWatch/ActionTab/RemoveFromFavs/Loggedin');
}
var gWatchPlaylistLoading='';
function addToPlaylist(videoId,event){
watchSelectTab(_gel('watch-tab-playlists'));
if(isLoggedIn){
if(!gWatchPlaylistLoading){
gWatchPlaylistLoading=_gel('addToPlaylistDiv').innerHTML;
}else{
_gel('addToPlaylistDiv').innerHTML=gWatchPlaylistLoading;
}
showDiv('addToPlaylistDiv');
showAjaxDivLoggedIn('addToPlaylistDiv','/watch_ajax?video_id='+videoId+'&action_get_playlists_component=1',true);
urchinTracker('/Events/VideoWatch/ActionTab/AddToPlaylists/Loggedin');
}else{
showDiv('addToPlaylistLogin');
urchinTracker('/Events/VideoWatch/ActionTab/AddToPlaylists/Loggedout');
}
}
function reportConcern(videoId,event){
var divs=['reportConcernResult1','reportConcernResult2','reportConcernResult3','reportConcernResult4','reportConcernResult5'];
for(var i=0;i<divs.length;i++){
var theDiv=_gel(divs[i]);
if(theDiv){
theDiv.style.display='none';
}
}
watchSelectTab(_gel('watch-tab-flag'));
if(isLoggedIn){
showDiv('inappropriateVidDiv');
if(_gel('inappropriateVidDiv').innerHTML.toLowerCase().indexOf('<div')!=-1){
return;
}
var callback=function(){
_gel('inappropriateMsgsDiv').innerHTML=_gel('inappropriateMsgs').innerHTML;
_gel('inappropriateMsgs').innerHTML='';
showDiv('inappropriateMsgsDiv');
};
showAjaxDivLoggedIn('inappropriateVidDiv','/watch_ajax?video_id='+videoId+'&action_get_flag_video_component=1',callback);
urchinTracker('/Events/VideoWatch/ActionTab/Flag/Loggedin');
}
else{
showDiv('inappropriateMsgsLogin');
urchinTracker('/Events/VideoWatch/ActionTab/Flag/Loggedout');
}
}
function watchExpandStatBody(){
if(_gel('watch-tab-stats-body').innerHTML.toLowerCase().indexOf('<div')==-1){
showAjaxDivLoggedIn('watch-tab-stats-body',additionalStatsHonorsUrl,false);
}
}
var subscribeTimer;
function subscribe(username,token,show_recommendations){
if(isLoggedIn){
window.clearTimeout(subscribeTimer);
postUrlXMLResponse('/ajax_subscriptions?subscribe_to_user='+username,
'session_token='+token+(show_recommendations?'&show_recommendations':''),
function(result){
var subscribeMsgNode=_gel('subscribeMessage');
subscribeMsgNode.innerHTML=getNodeValue(getRootNode(result),'html_content');
subscribeMsgNode.style.display='block';
addClass(_gel('subscribeDiv'),'hid');
removeClass(_gel('unsubscribeDiv'),'hid');
if(!show_recommendations){
subscribeTimer=window.setTimeout("hideDiv('subscribeMessage')",5000);
}
});
urchinTracker('/Events/VideoWatch/Subscription/'+username+'/Loggedin');
}else{
var subscribeMsgNode=_gel('subscribeLoginInvite');
subscribeMsgNode.style.display='block';
urchinTracker('/Events/VideoWatch/Subscription/'+username+'/Loggedout');
}
}
function unsubscribe(username,token){
window.clearTimeout(subscribeTimer);
postUrlXMLResponse('/ajax_subscriptions?unsubscribe_from_user='+username,'session_token='+token,
function(result){
var subscribeMsgNode=_gel('subscribeMessage');
subscribeMsgNode.innerHTML=getNodeValue(getRootNode(result),'html_content');
subscribeMsgNode.style.display='block';
removeClass(_gel('subscribeDiv'),'hid');
addClass(_gel('unsubscribeDiv'),'hid');
subscribeTimer=window.setTimeout("hideDiv('subscribeMessage')",5000);
});
}
function customizeEmbed(isWidescreenVideo,forceShow){
var loadHtml=false;
if(forceShow){
setDisplay('watch-customize-embed-div',true);
loadHtml=true;
}else{
loadHtml=toggleDisplay('watch-customize-embed-div');
}
if(loadHtml){
if(_gel('watch-customize-embed-div').innerHTML.toLowerCase().indexOf('<div')!=-1){
return;
}
showAjaxDivLoggedIn('watch-customize-embed-div','/watch_ajax?action_customize_embed=1'+(isWidescreenVideo?'&wide=1':''),applyUserPrefs);
}
}
function applyUserPrefs(){
if(_gel('watch-customize-embed-theme')){
var showBorderCheckBox=_gel('show_border_checkbox');
showBorderCheckBox.checked=yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_EMBED_SHOW_BORDER);
var showRelCheckBox=_gel('show_related_checkbox');
showRelCheckBox.checked=!yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_EMBED_NO_RELATED_VIDEOS);
var delayedCookiesCheckBox=_gel('delayed_cookies_checkbox');
delayedCookiesCheckBox.checked=yt.UserPrefs.getFlag2(yt.UserPrefs.Flags.FLAG2_EMBED_DELAYED_COOKIES);
var color=yt.UserPrefs.get('emt');
if(color!='blank'&&color!=''){
onChangeColor(color);
}
var embedSize=yt.UserPrefs.get('ems');
if(embedSize){
onChangeSize(embedSize);
}else{
onChangeSize("default");
}
onUpdateEmbedSizeDisplay();
}
if(_gel('watch-customize-embed-div')){
generateEmbed();
}
}
function generateEmbed(){
var query='';
if(yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_EMBED_NO_RELATED_VIDEOS)){
query+='&rel=0';
}
var color=yt.UserPrefs.get('emt');
if(color!='blank'&&color!=''){
var hexColors=gCustomEmbedThemes[color].split(' ');
query+='&color1=0x'+hexColors[0]+'&color2=0x'+hexColors[1];
}
embedUrl=yt.UserPrefs.getFlag2(yt.UserPrefs.Flags.FLAG2_EMBED_DELAYED_COOKIES)?embedUrl.replace("youtube.com","youtube-nocookie.com"):embedUrl.replace("youtube-nocookie.com","youtube.com");
var showBorder=yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_EMBED_SHOW_BORDER);
query+=showBorder?'&border=1':'';
var embedSizes=getEmbedSize();
var width=embedSizes[0];
var height=embedSizes[1];
var embedCode='<object width="'+width+'" height="'+height+'"><param name="movie" value="'+embedUrl+query+'"><\/param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="'+embedUrl+query+'" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="'+width+'" height="'+height+'"><\/embed><\/object>';
document.embedForm.embed_code.value=embedCode;
}
function getEmbedSize(opt_size){
var embedSize=yt.UserPrefs.get('ems')||'default';
if(opt_size){
embedSize=opt_size;
}
var customEmbedSizes=(isWidescreen)?gCustomEmbedSizesWide:gCustomEmbedSizes;
var showBorder=yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_EMBED_SHOW_BORDER);
var width=parseInt(customEmbedSizes[embedSize].split(" ")[0]);
var height=parseInt(customEmbedSizes[embedSize].split(" ")[1]);
if(showBorder){
width+=20;
height+=20;
}
return[width,height];
}
var delayLoadRegistry=delayLoadRegistry||[];
var delayLoadCompleted=delayLoadCompleted||[];
function delayLoad(id,img,src){
delayLoadRegistry[delayLoadRegistry.length]=[id,img,src];
delayLoadCompleted[id]=false;
}
function performDelayLoad(id){
if(!delayLoadCompleted[id]){
delayLoadCompleted[id]=true;
for(var i=0;i<delayLoadRegistry.length;i++){
if(delayLoadRegistry[i][0]==id){
delayLoadRegistry[i][1].onload="";
delayLoadRegistry[i][1].src=delayLoadRegistry[i][2];
}
}
}
}
function toggleChannelVideos(username){
if(!_gel('watch-channel-video-list-loading-div')){
showAjaxDivLoggedIn('watch-channel-vids-body','/watch_ajax?user='+username+'&video_id='+pageVideoId+'&action_channel_videos');
}
return false;
}
function showRelatedAsList(doAjaxCall){
if(doAjaxCall){
setInnerHTML('watch-related-vids-body',MSG_Loading);
showAjaxDivLoggedIn('watch-related-vids-body',
relatedVideoListUrl,
function(result){
if(result.responseXML!=null){
pageFillRelatedVideoStartIndex+=Number(getNodeValue(result.responseXML,"row_count"));
pageFillRelatedVideoEndIndex=Number(getNodeValue(result.responseXML,"max_count"));
}
}
);
}
}
var first_time=1;
function changeBanner(img_url,ref_url,is_flash){
var e=_gel("gad_leaderboardAd");
if(first_time){
e.style.height="90px";
first_time=0;
}
var url="";
if(is_flash=="true"){
url+="<object width='72"+"8' height='9"+"0'>";
url+="<"+"param value='clickTAG="+encodeURIComponent(ref_url)+"' /"+">";
url+="<"+"embed src='"+img_url+"'";
url+=" type='application/x-shockwave-flash' wmode='transparent'";
url+=" flashvars='clickTAG="+encodeURIComponent(ref_url)+"'";
url+=" width='72"+"8' height='9"+"0' /"+">";
url+="</object>";
}else{
url="<"+"a href='"+ref_url+"' target='_blank'>";
url+="<img src='"+img_url+"'>";
url+="</a>";
}
e.innerHTML=url;
}
var dartOrd=Math.floor(Math.random()*10000000);
function setCompanionAndOrd(ad_tag,show_ad){
ad_tag=ad_tag+'ord='+dartOrd;
setCompanion(ad_tag,show_ad);
}
function setCompanion(ad_tag,show_ad){
if(show_ad=='true'){
ad_tag=ad_tag+'?';
showDiv("watch-channel-brand-div");
_gel("ad300x250").innerHTML='<iframe src="'+ad_tag+'" name="ifr_300x250ad" id="ifr_300x250ad" width="300" height="250" marginwidth=0 marginheight=0 hspace=0 vspace=0 frameborder=0 scrolling=no>'+'<'+'/iframe>';
setJSReadyState();
}
}
function setInstreamCompanion(ad_tag){
ad_tag=ad_tag+'?';
showDiv("watch-longform-ad");
_gel("watch-longform-ad-placeholder").innerHTML='<iframe src="'+ad_tag+'" name="ifr_300x60ad" id="ifr_300x60ad" width="300" height="60" marginwidth=0 marginheight=0 hspace=0 vspace=0 frameborder=0 scrolling=no>'+'<'+'/iframe>';
}
var flashPlayerReadyState=false;
function setFlashPlayerReadyState(){
flashPlayerReadyState=true;
if(jsReadyState){
setReadyToGoInFlash();
}
}
var jsReadyState=false;
function setJSReadyState(){
jsReadyState=true;
if(flashPlayerReadyState){
setReadyToGoInFlash();
}
}
function setReadyToGoInFlash(){
_gel("movie_player").SetVariable("dartOrd",dartOrd);
_gel("movie_player").SetVariable("dcRtg","1");
}
function closeInPageAdIframe(){
hideDiv("ad300x250");
_gel("google_companion_ad_div").style.height="250px";
}
function setLongformCompanion(linkedImg){
var adDiv=_gel("watch-longform-ad");
var adholder=_gel("watch-longform-ad-placeholder");
if(linkedImg){
adDiv.style.visibility='visible';
adholder.innerHTML=linkedImg;
}else{
adDiv.style.visibility='hidden';
}
}
function performPyvClick(pyvCookieName){
var pyvAdUrl=readCookie(pyvCookieName);
if(!pyvAdUrl){
return;
}
if(!verifyPyvAdUrl(pyvAdUrl)){
eraseCookie(pyvCookieName);
return;
}
pingUrlViaImage(pyvAdUrl);
eraseCookie(pyvCookieName);
}
function verifyPyvAdUrl(ad_url){
var matches=ad_url.match(/.*\/aclk.*q=([^&]*)/);
var landing_url=matches&&matches[1];
if(!landing_url){
return false;
}
var curr_id=extractCurrentVideoId()||extractCurrentChannel();
if(!curr_id){
return false;
}
if(landing_url.indexOf(curr_id)>0){
return true;
}
return false;
}
function extractCurrentVideoId(){
var matches=window.location.href.match(/.*\.com\/watch.*v=([^&]*)/);
return matches&&matches[1];
}
function extractCurrentChannel(){
var matches=window.location.href.match(/.*\.com\/(?:user\/)?([a-zA-Z0-9]*)/);
return matches&&matches[1];
}
function pingUrlViaImage(dest_url){
var img=new Image();
img.src=dest_url;
img.height=1;
img.width=1;
document.body.appendChild(img);
}
function reportFlashTiming(timings,opt_fmt){
if(typeof opt_fmt!='undefined'){
window['jstiming']['fmt']=opt_fmt;
}
var timingsCount=timings.length/ 2;
for(var i=0;i<timingsCount;i++){
window['jstiming']['timers']['watch'][timings[2*i]]=timings[2*i+1];
}
if(csiMaybeSendReport){
csiMaybeSendReport();
}
}
function toggleAdvSearch(search_query,geo_name,geo_latlong,search_duration,search_hl,search_categories,search_sort,search_uploaded){
toggleClass(_gel('search-advanced-form'),'hid');
if(_gel('search-advanced-form').innerHTML.toLowerCase().indexOf('<form')!=-1){
return false;
}
var params=new Object();
params['action_advanced']='1';
params['search_query']=search_query;
params['geo_name']=geo_name;
params['geo_latlong']=geo_latlong;
params['search_duration']=search_duration;
params['search_hl']=search_hl;
params['search_sort']=search_sort;
params['search_uploaded']=search_uploaded;
var url=buildUrl('/results_ajax',params);
var categories=search_categories.split(',');
for(var i=0;i<categories.length;i++){
url+='&search_category='+categories[i];
}
var callback=function(){
var setting=yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_SAFE_SEARCH);
_gel('search-filter-checkbox').checked=setting;
setting=gGoogleSuggest||yt.UserPrefs.getFlag(yt.UserPrefs.Flags.FLAG_SUGGEST_ENABLED);
_gel('search-suggest-checkbox').checked=setting;
};
showAjaxDivLoggedIn('search-advanced-form',url,callback);
return false;
}
var videolist=new Array();
function append_token_for_queue(queryParams){
queryParams=queryParams||"";
return queryParams+'&'+gXSRF_ql_pair;
}
function mouseOverQuickAdd(img){
if(!img.className.match('Done')){
removeClass(img,'QLIconImg');
removeClass(img,'QLIconImgDone');
addClass(img,'QLIconImgOver');
}
}
function mouseOutQuickAdd(img){
if(!img.className.match('Done')){
removeClass(img,'QLIconImgOver');
removeClass(img,'QLIconImgDone');
addClass(img,'QLIconImg');
}
}
function quicklistAddedUpdateImage(img){
removeClass(img,'QLIconImg');
removeClass(img,'QLIconImgOver');
addClass(img,'QLIconImgDone');
img.blur();
hideDiv(img);
showDiv(getQuicklistInlist(img));
}
function getQuicklistUtility(){
return self.utilLinksFrame?self.utilLinksFrame.document.getElementById('quicklist-utility'):_gel('quicklist-utility');
}
function getQuicklistInlist(img){
return(getElementsByTagNameAndClass('DIV','quicklist-inlist',img.parentNode.parentNode))[0];
}
var gQuicklistTimeoutId=null;
function updateQuicklistMasthead(increaseBy){
var qUtil=getQuicklistUtility();
if(qUtil){
if(increaseBy==0){
qUtil.innerHTML="0";
}else{
qUtil.innerHTML=parseInt(qUtil.innerHTML)+increaseBy;
}
}else{
return;
}
if(gQuicklistTimeoutId){
window.clearTimeout(gQuicklistTimeoutId);
gQuicklistTimeoutId=null;
}
quicklistMastheadBlinkHelper(1);
}
function quicklistMastheadBlinkHelper(on){
var qUtil=getQuicklistUtility();
qUtil.style.backgroundColor=on%2?'#ff0':'#fff';
++on;
if(on<=10){
gQuicklistTimeoutId=window.setTimeout(function(){quicklistMastheadBlinkHelper(on);},500);
}
}
function onQuickAddClick(imgClicked,encryptedId,thumbSrc,thumbTitle){
if(isPlaylistCssAndJsLoaded){
onQuickAddClickCallback(imgClicked,encryptedId,thumbSrc,thumbTitle);
}else{
isPlaylistCssAndJsLoaded=true;
var scriptElement=document.createElement('script');
scriptElement.src='http://s.ytimg.com/yt/js/watch_queue2-vfl76993.js';
document.getElementsByTagName('head')[0].appendChild(scriptElement);
function jsCallback(imgClicked,encryptedId,thumbSrc,thumbTitle){
if(typeof(onQuickAddClickCallback)!='undefined'){
onQuickAddClickCallback(imgClicked,encryptedId,thumbSrc,thumbTitle);
}else{
var func=function(){jsCallback(imgClicked,encryptedId,thumbSrc,thumbTitle)};
window.setTimeout(func,100);
}
}
var callback=function(req){
handleStylesheetAndJavascriptContent(req);
jsCallback(imgClicked,encryptedId,thumbSrc,thumbTitle);
};
getUrlXMLResponse('/watch_ajax?action_get_playlist_css=1',callback);
}
return false;
}
var quicklistVideoIds=[];
function clicked_add_icon(imgClicked,videoId,fromRelated,thumbSrc,thumbTitle){
for(var x=0;x<quicklistVideoIds.length;++x){
if(quicklistVideoIds[x]==videoId){
return;
}
}
updateQuicklistMasthead(1);
if(typeof(toolbarEnabled)!='undefined'&&toolbarEnabled){
toolbar.addToQueue(imgClicked,videoId,thumbSrc,thumbTitle);
}
quicklistVideoIds.push(videoId);
add_to_watch_queue(videoId);
quicklistAddedUpdateImage(imgClicked);
}
function add_to_watch_queue(videoId){
videolist.push(videoId);
post_videos_to_server();
}
function post_videos_to_server(){
if(videolist.length>0){
postUrlXMLResponse("/watch_queue_ajax?action_add_to_queue&video_id="+videolist[videolist.length-1],append_token_for_queue(),self.videoQueued);
videolist.pop();
}
}
function videoQueued(xmlHttpRequest){
var xmlObj=xmlHttpRequest.responseXML;
if(xmlObj!=null&&getNodeValue(xmlObj,"msg")!="exists"){
post_videos_to_server();
}
}
(function(){
function checkRef(ref){
var a=ref.split('/',3);
if(a.length>=3&&a[0]=='http:'&&a[1]==''){
a=a[2].split('.').reverse();
if(a.length<2)return false;
var d0=a[0];
var d1=a[1];
if(d1=='youtube'&&d0=='com')return true;
if(d1=='google')return true;
if(a.length<3)return false;
if(a[2]=='google'&&((d1=='co'&&d0=='uk')||(d1=='com'&&d0=='au')))return true;
}
return false;
}
if(window!=window.top){
var ref=document.referrer;
if(!checkRef(ref)){
var data='location='+encodeURIComponent(ref)+'&self='+encodeURIComponent(window.location.href);
postUrl('/roger_rabbit',data,true,processReqChange);
}
}
function processReqChange(req){
if(req.readyState==4){
if(req.status==200){
if(req.responseText=='block'){
window.top.location.href='/';
}
}
}
}
})();
function dynamic_append_session_token(form_obj,opt_session_token)
{
var token=undefined;
if(opt_session_token==null)
{
token=gXSRF_token;
}
else
{
token=opt_session_token;
}
var token_elem=document.createElement('input');
token_elem.setAttribute('name',gXSRF_field_name);
token_elem.setAttribute('type','hidden');
token_elem.setAttribute('value',token);
form_obj.appendChild(token_elem);
}
var session_excluded_forms=new Array();
function populate_session_token()
{
for(var form_pos=0;form_pos<document.forms.length;form_pos++)
{
var skip=false;
for(var exclude_pos=0;
exclude_pos<session_excluded_forms.length;
exclude_pos++)
{
if(document.forms[form_pos].name
==session_excluded_forms[exclude_pos])
{
skip=true;
}
}
var aform=document.forms[form_pos];
if((aform.method.toLowerCase()=='post')&&(skip==false))
{
var found=false;
for(var elem_pos=0;elem_pos<aform.elements.length;
elem_pos++)
{
var form_field=aform.elements[elem_pos];
if(form_field.name==gXSRF_field_name)
{
found=true;
}
}
if(!found)
{
dynamic_append_session_token(aform);
}
}
}
}
function loadFlagImgs(el){
showDiv('masthead-region-and-language-picker-box');
var callback=function(){
if(_gel(el).style.display=='none'){
showDiv(el);
}else{
hideDiv(el);
hideDiv('masthead-region-and-language-picker-box');
}
};
if(_gel('masthead-region-and-language-picker-box').innerHTML.toLowerCase().indexOf('<div')!=-1){
callback();
return;
}
showAjaxDivLoggedIn('masthead-region-and-language-picker-box','/masthead_ajax?action_get_region_and_language_picker=1',callback);
}
var gDidSearchBarFocusTest=false;
function searchBarFocusTest(event){
if(!gDidSearchBarFocusTest&&(event.keyCode==40||event.keyCode==32||event.keyCode==34)){
_gel('masthead-search-term').blur();
}
gDidSearchBarFocusTest=true;
}
var UserPrefsImpl=function(){
var data=readCookie(UserPrefsImpl.USER_PREFS_COOKIE);
if(data){
this._parse(data);
}
};
UserPrefsImpl.USER_PREFS_COOKIE=cookie_prefix+"PREF";
UserPrefsImpl.prototype._throwOnNull=function(value){
if(value==null){
throw "ExpectedNotNull";
};
};
UserPrefsImpl.prototype._throwOnInvalidType=function(obj,type){
if(typeof(obj)!=type){
throw "InvalidType";
};
};
UserPrefsImpl.prototype._throwOnRegexMatch=function(str,regex){
if(regex.test(str)){
throw "ExpectedRegexMismatch";
};
};
UserPrefsImpl.prototype._throwOnRegexMismatch=function(str,regex){
if(!regex.test(str)){
throw "ExpectedRegexMatch";
};
};
UserPrefsImpl.prototype.prefs=new Object();
UserPrefsImpl.prototype._throwOnInvalidKey=function(value){
this._throwOnRegexMismatch(value,/^\w+$/);
this._throwOnRegexMatch(value,/^f([1-9][0-9]*)$/);
};
UserPrefsImpl.prototype._setValue=function(key,value){
this.prefs[key]=value.toString();
}
UserPrefsImpl.prototype._getNumber=function(key){
var value=this._getString(key);
return((value!=null&&/^[A-Fa-f0-9]+$/.test(value))?parseInt(value,16):null);
};
UserPrefsImpl.prototype._getString=function(key){
var value=(this.prefs[key]!==undefined?this.prefs[key].toString():null);
return value;
};
UserPrefsImpl.prototype._setFlag=function(key,flag,bit){
var vector=this._getNumber(key);vector=(vector!=null?vector:0);
var value=(bit?vector|flag:vector&~flag);
if(value==0){
this._deleteValue(key);
}else{
this._setValue(key,value.toString(16));
}
};
UserPrefsImpl.prototype._getFlag=function(key,flag){
var vector=this._getNumber(key);
vector=(vector!=null?vector:0);
return((vector&flag)>0);
};
UserPrefsImpl.prototype._deleteValue=function(key){
delete this.prefs[key];
};
UserPrefsImpl.prototype._parse=function(string){
var pairs=unescape(string).split("&");
for(var i=0;i<pairs.length;i++){
var pair=pairs[i].split("=");
var key=pair[0];
var value=pair[1];
if(value)this._setValue(key,value);
}
};
UserPrefsImpl.prototype.get=function(key,opt_def){
this._throwOnInvalidKey(key);
var value=this._getString(key);
return(value!=null?value:(opt_def?opt_def:""));
};
UserPrefsImpl.prototype.set=function(key,value){
this._throwOnInvalidKey(key);
this._throwOnNull(value);
this._setValue(key,value);
};
UserPrefsImpl.prototype.getFlag=function(flag){
return this._getFlag('f1',flag);
};
UserPrefsImpl.prototype.setFlag=function(flag,bit){
return this._setFlag('f1',flag,bit);
};
UserPrefsImpl.prototype.getFlag2=function(flag){
return this._getFlag('f2',flag);
};
UserPrefsImpl.prototype.setFlag2=function(flag,bit){
return this._setFlag('f2',flag,bit);
};
UserPrefsImpl.prototype.remove=function(key){
this._throwOnInvalidKey(key);
this._deleteValue(key);
};
UserPrefsImpl.prototype.save=function(days){
var pairs=new Array();
for(var prop in this.prefs){
pairs.push(prop+"="+escape(this.prefs[prop]));
}
if(days==null)days=7;
createCookie(UserPrefsImpl.USER_PREFS_COOKIE,pairs.join("&"),days);
};
UserPrefsImpl.prototype.clear=function(){
this.prefs=new Object();
};
UserPrefsImpl.prototype.dump=function(){
var pairs=new Array();
for(var prop in this.prefs){
pairs.push(prop+"="+escape(this.prefs[prop]));
}
return pairs.join('&');
};
var EventManagerImpl=function(){
}
EventManagerImpl.prototype.handlerTable=new Object();
EventManagerImpl.prototype.fireEvent=function(name,arg){
if(this.handlerTable[name]==null){
return;
}
var handlers=this.handlerTable[name];
for(var i=0;i<handlers.length;i++){
handlers[i](arg);
}
}
EventManagerImpl.prototype.addHandler=function(name,fn){
if(this.handlerTable[name]==null){
this.handlerTable[name]=new Array();
}
this.handlerTable[name].push(fn);
return fn;
}
EventManagerImpl.prototype.removeHandler=function(name,fn){
if(this.handlerTable[name]==null){
return false;
}
var index=this.handlerTable[name].indexOf(fn);
if(index==-1){
return false;
}
this.handlerTable[name].splice(index,1);
return true;
}
yt.UserPrefs=new UserPrefsImpl();
yt.EventManager=new EventManagerImpl();
var EventManager=yt.EventManager;
function readCookie(name,opt_fallback){
var nameEQ=name+"=";
var ca=document.cookie.split(';');
for(var i=0;i<ca.length;i++){
var c=ca[i];
while(c.charAt(0)==' ')c=c.substring(1,c.length);
if(c.indexOf(nameEQ)==0)return c.substring(nameEQ.length,c.length);
}
if(opt_fallback){
return opt_fallback;
}else{
return null;
}
}
function readIntCookie(name){
var val=readCookie(name);
if(val){
return parseInt(val,10);
}else{
return 0;
}
}
function createCookie(name,value,days){
var cookie="";
var domain=cookie_domain;
var path="/";
cookie+=name+"="+value+";";
cookie+="domain=."+domain+";";
cookie+="path="+path+";";
if(days){
var date=new Date();
date.setTime(date.getTime()+(days*24*60*60*1000));
cookie+="expires="+date.toGMTString()+";";
}
document.cookie=cookie;
}
function eraseCookie(name){
createCookie(name,"",-1);
}

function isPanelExpanded(panel){
  return hasClass(panel,'expanded');
}
function expandPanel(panel){
  if(!isPanelExpanded(panel)){
    addClass(panel,'expanded');
    fireInlineEvent(panel,'expanded');
  }
}
function collapsePanel(panel){
  if(isPanelExpanded(panel)){
    removeClass(panel,'expanded');
    fireInlineEvent(panel,'collapsed');
  }
}
function togglePanel(panel){
  if(isPanelExpanded(panel)){
    collapsePanel(panel);
  }else{
    expandPanel(panel);
  }
}
function fireInlineEvent(element,eventName){
  var target=ref(element);
  if(target[eventName]==null){
    var attributeName='on'+eventName.toLowerCase();
    var attribute=target.attributes.getNamedItem(attributeName);
    if(attribute){
      target[eventName]=function(){
        eval(attribute.value);
      }
    }
  }
  if(target[eventName])target[eventName]();
}

var thumbnailDelayLoad=function(){
var htmlElement=document.getElementsByTagName('html')[0];
function isBody(element){
return(/^(?:body|html)$/i).test(element.tagName);
};
function getWindowScrollY(){
var doc=(!document.compatMode||document.compatMode=='CSS1Compat')?htmlElement:document.body;
return window.pageYOffset||doc.scrollTop;
};
function getWindowSizeY(){
if(window.opera||(!window.ActiveXObject&&!navigator.taintEnabled))return window.innerHeight;
var doc=(!document.compatMode||document.compatMode=='CSS1Compat')?htmlElement:document.body;
return doc.clientHeight;
};
function getScrollY(element){
var position=0;
while(element&&!isBody(element)){
position+=element.scrollTop;
element=element.parentNode;
}
return position;
};
function getOffsetY(element){
if(document.documentElement["getBoundingClientRect"]){
var bound=element.getBoundingClientRect(),html=document.documentElement;
return bound.top+html.scrollTop-html.clientTop;
}else{
return 0;
}
};
function getPositionY(element){
if(document.documentElement["getBoundingClientRect"]){
var offsetY=getOffsetY(element),scrollY=getScrollY(element);
return offsetY-scrollY;
}else{
return 0;
}
};
return{
testImage:function(img,windowPositionY){
windowPositionY=windowPositionY||(getWindowScrollY()+getWindowSizeY());
if(getPositionY(img)<=windowPositionY+175){
img.src=img.getAttribute('thumb');
img.removeAttribute('thumb');
}
},
loadImages:function(){
var imgs=document.getElementsByTagName('IMG');
var windowPositionY=getWindowScrollY()+getWindowSizeY();
for(var x=0;x<imgs.length;++x){
if(imgs[x].getAttribute('thumb')){
thumbnailDelayLoad.testImage(imgs[x],windowPositionY);
}
}
}
};
}();
if(yt&&yt.UserPrefs){
yt.UserPrefs.Flags={
FLAG_SAFE_SEARCH:0x1,
FLAG_GRID_VIEW_SEARCH_RESULTS:0x2,
FLAG_EMBED_NO_RELATED_VIDEOS:0x4,
FLAG_EMBED_SHOW_BORDER:0x8,
FLAG_GRID_VIEW_VIDEOS_AND_CHANNELS:0x10,
FLAG_WATCH_EXPAND_ABOUT_PANEL:0x20,
FLAG_WATCH_EXPAND_MOREFROM_PANEL:0x40,
FLAG_WATCH_COLLAPSE_RELATED_PANEL:0x80,
FLAG_WATCH_COLLAPSE_PLAYLIST_PANEL:0x100,
FLAG_WATCH_COLLAPSE_QUICKLIST_PANEL:0x200,
FLAG_WATCH_EXPAND_ALSOWATCHING_PANEL:0x400,
FLAG_WATCH_COLLAPSE_COMMENTS_PANEL:0x800,
FLAG_STATMODULES_INBOX_COLLAPSED:0x1000,
FLAG_STATMODULES_ABOUTYOU_COLLAPSED:0x2000,
FLAG_STATMODULES_ABOUTVIDEOS_COLLAPSED:0x4000,
FLAG_PERSONALIZED_HOMEPAGE_EXPERIMENT:0x8000,
FLAG_PERSONALIZED_HOMEPAGE_FEED_FEATURED_COLLAPSED:0x10000,
FLAG_PERSONALIZED_HOMEPAGE_FEED_RECOMMENDED_COLLAPSED:0x20000,
FLAG_PERSONALIZED_HOMEPAGE_FEED_SUBSCRIPTIONS_COLLAPSED:0x40000,
FLAG_PERSONALIZED_HOMEPAGE_FEED_POPULAR_COLLAPSED:0x80000,
FLAG_PERSONALIZED_HOMEPAGE_FEED_FRIENDTIVITY_COLLAPSED:0x100000,
FLAG_SUGGEST_ENABLED:0x200000,
FLAG_HAS_SUGGEST_ENABLED:0x400000,
FLAG_WATCH_BETA_PLAYER:0x800000,
FLAG_HAS_REDIRECTED_TO_LOCAL_SITE:0x1000000,
FLAG_ACCOUNT_SHOW_PLAYLIST_INFO:0x2000000,
FLAG_HAS_TAKEN_CHANNEL_SURVEY:0x4000000,
FLAG_HIDE_TOOLBAR:0x8000000,
FLAG_SHOW_LANG_OPT_OUT:0x10000000,
FLAG_HAS_REDIRECTED_TO_LOCAL_LANG:0x20000000,
FLAG_SHOW_COUNTRY_OPT_OUT:0x40000000,
FLAG2_UPLOAD_BETA_OPTSET:0x1,
FLAG2_UPLOAD_BETA_OPTIN:0x2,
FLAG2_HIDE_MASTHEAD:0x4,
FLAG2_TV_PARITY:0x8,
FLAG2_TV_AUTO_FULLSCREEN_OFF:0x10,
FLAG2_TV_AUTO_PLAY_NEXT_OFF:0x20,
FLAG2_TV_ENABLE_MULTIPLE_CONTROLLERS:0x40,
FLAG2_TV_RESERVED:0x80,
FLAG2_LIGHT_HOMEPAGE:0x100,
FLAG2_REDLINE_HIDE_TOAST:0x200,
FLAG2_ANNOTATIONS_EDITOR_WATCH_PAGE_DEFAULT_OFF:0x400,
FLAG2_REDLINE_HIDE_START_MESSAGE:0x800,
FLAG2_ANNOTATIONS_LOAD_POLICY_BY_DEMAND:0x1000,
FLAG2_EMBED_DELAYED_COOKIES:0x2000,
FLAG2_HD_TIP_DEMOTE:0x4000,
FLAG2_NEWS_TIP_DEMOTE:0x8000,
FLAG2_UPLOAD_RESTRICT_TIP_DEMOTE:0x10000
}
}
var gCustomEmbedThemes={'blank':'b1b1b1 cfcfcf','storm':'3a3a3a 999999','iceberg':'2b405b 6b8ab6','acid':'006699 54abd6','green':'234900 4e9e00','orange':'e1600f febd01','pink':'cc2550 e87a9f','purple':'402061 9461ca','rubyred':'5d1719 cd311b'};
var gCustomEmbedSizes={'small':'320 265','default':'425 344','medium':'480 385','large':'640 505'};
var gCustomEmbedSizesWide={'small':'425 264','default':'480 295','medium':'560 345','large':'640 385'};
if(typeof deconcept=="undefined"){var deconcept={};}if(typeof deconcept.util=="undefined"){deconcept.util={};}if(typeof deconcept.SWFObjectUtil=="undefined"){deconcept.SWFObjectUtil={};}deconcept.SWFObject=function(_1,id,w,h,_5,c,_7,_8,_9,_a){if(!document.getElementById){return;}this.DETECT_KEY=_a?_a:"detectflash";this.skipDetect=deconcept.util.getRequestParameter(this.DETECT_KEY);this.params={};this.variables={};this.attributes=[];if(_1){this.setAttribute("swf",_1);}if(id){this.setAttribute("id",id);}if(w){this.setAttribute("width",w);}if(h){this.setAttribute("height",h);}if(_5){this.setAttribute("version",new deconcept.PlayerVersion(_5.toString().split(".")));}this.installedVer=deconcept.SWFObjectUtil.getPlayerVersion();if(!window.opera&&document.all&&this.installedVer.major>7){if(!deconcept.unloadSet){deconcept.SWFObjectUtil.prepUnload=function(){__flash_unloadHandler=function(){};__flash_savedUnloadHandler=function(){};window.attachEvent("onunload",deconcept.SWFObjectUtil.cleanupSWFs);};window.attachEvent("onbeforeunload",deconcept.SWFObjectUtil.prepUnload);deconcept.unloadSet=true;}}if(c){this.addParam("bgcolor",c);}var q=_7?_7:"high";this.addParam("quality",q);this.setAttribute("useExpressInstall",false);this.setAttribute("doExpressInstall",false);var _c=(_8)?_8:window.location;this.setAttribute("xiRedirectUrl",_c);this.setAttribute("redirectUrl","");if(_9){this.setAttribute("redirectUrl",_9);}};deconcept.SWFObject.prototype={useExpressInstall:function(_d){this.xiSWFPath=!_d?"expressinstall.swf":_d;this.setAttribute("useExpressInstall",true);},setAttribute:function(_e,_f){this.attributes[_e]=_f;},getAttribute:function(_10){return this.attributes[_10]||"";},addParam:function(_11,_12){this.params[_11]=_12;},getParams:function(){return this.params;},addVariable:function(_13,_14){this.variables[_13]=_14;},getVariable:function(_15){return this.variables[_15]||"";},getVariables:function(){return this.variables;},getVariablePairs:function(){var _16=[];var key;var _18=this.getVariables();for(key in _18){_16[_16.length]=key+"="+_18[key];}return _16;},getSWFHTML:function(){var _19="";if(navigator.plugins&&navigator.mimeTypes&&navigator.mimeTypes.length){if(this.getAttribute("doExpressInstall")){this.addVariable("MMplayerType","PlugIn");this.setAttribute("swf",this.xiSWFPath);}_19="<embed type=\"application/x-shockwave-flash\" src=\""+this.getAttribute("swf")+"\" width=\""+this.getAttribute("width")+"\" height=\""+this.getAttribute("height")+"\" style=\""+(this.getAttribute("style")||"")+"\"";_19+=" id=\""+this.getAttribute("id")+"\" name=\""+this.getAttribute("id")+"\" ";var _1a=this.getParams();for(var key in _1a){_19+=[key]+"=\""+_1a[key]+"\" ";}var _1c=this.getVariablePairs().join("&");if(_1c.length>0){_19+="flashvars=\""+_1c+"\"";}_19+="/>";}else{if(this.getAttribute("doExpressInstall")){this.addVariable("MMplayerType","ActiveX");this.setAttribute("swf",this.xiSWFPath);}_19="<object id=\""+this.getAttribute("id")+"\" classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\" width=\""+this.getAttribute("width")+"\" height=\""+this.getAttribute("height")+"\" style=\""+(this.getAttribute("style")||"")+"\">";_19+="<param name=\"movie\" value=\""+this.getAttribute("swf")+"\" />";var _1d=this.getParams();for(var key in _1d){_19+="<param name=\""+key+"\" value=\""+_1d[key]+"\" />";}var _1f=this.getVariablePairs().join("&");if(_1f.length>0){_19+="<param name=\"flashvars\" value=\""+_1f+"\" />";}_19+="</object>";}return _19;},write:function(_20){if(this.getAttribute("useExpressInstall")){var _21=new deconcept.PlayerVersion([6,0,65]);if(this.installedVer.versionIsValid(_21)&&!this.installedVer.versionIsValid(this.getAttribute("version"))){this.setAttribute("doExpressInstall",true);this.addVariable("MMredirectURL",escape(this.getAttribute("xiRedirectUrl")));document.title=document.title.slice(0,47)+" - Flash Player Installation";this.addVariable("MMdoctitle",document.title);}}if(this.skipDetect||this.getAttribute("doExpressInstall")||this.installedVer.versionIsValid(this.getAttribute("version"))){var n=(typeof _20=="string")?document.getElementById(_20):_20;n.innerHTML=this.getSWFHTML();return true;}else{if(this.getAttribute("redirectUrl")!=""){document.location.replace(this.getAttribute("redirectUrl"));}}return false;}};deconcept.SWFObjectUtil.getPlayerVersion=function(){var _23=new deconcept.PlayerVersion([0,0,0]);if(navigator.plugins&&navigator.mimeTypes.length){var x=navigator.plugins["Shockwave Flash"];if(x&&x.description){_23=new deconcept.PlayerVersion(x.description.replace(/([a-zA-Z]|\s)+/,"").replace(/(\s+r|\s+b[0-9]+)/,".").split("."));}}else{if(navigator.userAgent&&navigator.userAgent.indexOf("Windows CE")>=0){var axo=1;var _26=3;while(axo){try{_26++;axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash."+_26);_23=new deconcept.PlayerVersion([_26,0,0]);}catch(e){axo=null;}}}else{try{var axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");}catch(e){try{var axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");_23=new deconcept.PlayerVersion([6,0,21]);axo.AllowScriptAccess="always";}catch(e){if(_23.major==6){return _23;}}try{axo=new ActiveXObject("ShockwaveFlash.ShockwaveFlash");}catch(e){}}if(axo!=null){_23=new deconcept.PlayerVersion(axo.GetVariable("$version").split(" ")[1].split(","));}}}return _23;};deconcept.PlayerVersion=function(_29){this.major=_29[0]!=null?parseInt(_29[0]):0;this.minor=_29[1]!=null?parseInt(_29[1]):0;this.rev=_29[2]!=null?parseInt(_29[2]):0;};deconcept.PlayerVersion.prototype.versionIsValid=function(fv){if(this.major<fv.major){return false;}if(this.major>fv.major){return true;}if(this.minor<fv.minor){return false;}if(this.minor>fv.minor){return true;}if(this.rev<fv.rev){return false;}return true;};deconcept.util={getRequestParameter:function(_2b){var q=document.location.search||document.location.hash;if(_2b==null){return q;}if(q){var _2d=q.substring(1).split("&");for(var i=0;i<_2d.length;i++){if(_2d[i].substring(0,_2d[i].indexOf("="))==_2b){return _2d[i].substring((_2d[i].indexOf("=")+1));}}}return "";}};deconcept.SWFObjectUtil.cleanupSWFs=function(){var _2f=document.getElementsByTagName("OBJECT");for(var i=_2f.length-1;i>=0;i--){_2f[i].style.display="none";for(var x in _2f[i]){if(typeof _2f[i][x]=="function"){_2f[i][x]=function(){};}}}};if(!document.getElementById&&document.all){document.getElementById=function(id){return document.all[id];};}var getQueryParamValue=deconcept.util.getRequestParameter;var FlashObject=deconcept.SWFObject;var SWFObject=deconcept.SWFObject;
(function(){
function f(a,b){return a.className=b}function g(a,b){return a.value=b}function aa(a,b,e,c,d,h,l,x,q){ba=a;i=b;ca=c;j=d;da=h;ea=l;k=x;if(fa&&m.location.href[n]("/watch?")!=-1)if(q)return;else{ga=2;j=""}ha=/^(zh-(CN|TW)|ja|ko)$/.test(c);ia="/complete/search?hl="+c+"&client=suggest&hjson=t";o(ba,"onsubmit",ja);i[p]("autocomplete","off");o(i,"blur",ka);o(i,"beforedeactivate",la);if(i.addEventListener){if(ma)i.onkeydown=na;else i.onkeypress=na;i.onkeyup=oa}else{o(i,r?"keydown":"keypress",na);o(i,"keyup",
oa)}s=t=u=i[v];pa=qa(i);w=y[z]("table");w.id="completeTable";w.cellSpacing=w.cellPadding="0";A=w[ra];f(w,B+"m");C();y.body[D](w);E=y[z]("iframe");F=E[ra];E.id="completeIFrame";F.zIndex="1";F.position="absolute";F.display="block";F.borderWidth=0;y.body[D](E);sa();ta();o(m,"resize",sa);o(m,"pageshow",ua);ha&&m.setInterval(va,10);G=wa("aq","f",H);I=wa("oq",s,J);if(k==-1){if(ca in xa)K=J}else{wa("aex",String(k),H);if(k==1)K=J;else if(k==2){K=J;ya=J}else if(k==3){K=J;za=J}}L=K||ya||za;if(L)j="";M()}function ua(a){if(a.persisted)g(G,
"f");g(I,i[v])}function ta(){var a=y.body.dir=="rtl",b=a?"right":"left",e=a?"left":"right",c=y.getElementsByTagName("head")[0],d=y[z]("style"),h=O,l=O,x=H;if(y.styleSheets){c[D](d);x=J;h=d.sheet?d.sheet:d.styleSheet}if(!h){l=y.createTextNode("");d[D](l)}var q=function(Ka,La){var Ma=Ka+" { "+La+" }";if(h)if(h.insertRule)h.insertRule(Ma,h.cssRules[P]);else h.addRule&&h.addRule(Ka,La);else l.data+=Ma+"\n"};q("."+B+"m","font-size:13px;font-family:arial,sans-serif;cursor:default;line-height:17px;border:1px solid #999;z-index:99;position:absolute;background-color:white;margin:0;");
q("."+B+"a","background-color:white;");var U="background-color:#36c;color:white;";q("."+B+"b ."+B+"d",U);q("."+B+"b ."+B+"c",U);var N="padding-"+b+":",Na="padding-"+e+":";q("."+B+"c","white-space:nowrap;overflow:hidden;text-align:"+b+";"+N+"3px;"+(r||Aa?"padding-bottom:1px;":""));q("."+B+"d","white-space:nowrap;overflow:hidden;font-size:10px;text-align:"+e+";color:#666;"+N+"3px;"+Na+"3px;");q("."+B+"e td","padding:0 3px 2px;text-align:"+e+";font-size:10px;line-height:15px;");q("."+B+"e span","color:#03c;text-decoration:underline;cursor:pointer;");
q("."+B+"f","width: 16px;background-color:#EAEAEA;white-space:nowrap;overflow:hidden;"+N+"2px;"+Na+"2px;"+(r||Aa?"padding-bottom:1px;":""));x||c[D](d)}function sa(){if(w){var a=L?20:0;A.left=Ba(i,"offsetLeft")-a+"px";A.top=Ba(i,"offsetTop")+i.offsetHeight-1+"px";A.width=i.offsetWidth+a+"px";if(E){F.left=A.left;F.top=A.top;F.width=w.offsetWidth+"px";F.height=w.offsetHeight+"px"}}}function Ca(a,b){a.visibility=b?"visible":"hidden"}function wa(a,b,e){var c=y[z]("input");c.type="hidden";c.name=a;g(c,
b);c.disabled=e;return ba[D](c)}function ka(){Q||C();Q=H}function la(){if(Q){m.event.cancelBubble=J;m.event.returnValue=H}Q=H}function na(a){var b=a.keyCode;if(b==13&&R&&"googleSuggestion"in R){R.onclick();return H}if(b==27&&Da()){C();S(s);a.cancelBubble=J;a.returnValue=H;return H}if(!Ea(b))return J;Fa++;Fa%3==1&&Ga(b);return H}function oa(a){var b=a.keyCode;!(ha&&Ea(b))&&Fa==0&&Ga(b);Fa=0;return!Ea(b)}function Ga(a){ha&&Ea(a)&&Ha();if(i[v]!=u||a==39){s=i[v];pa=qa(i);if(a!=39)g(I,s)}if(a==40||a==
63233)Ia(T+1);else(a==38||a==63232)&&Ia(T-1);sa();if(V!=s&&!W)W=m.setTimeout(C,500);u=i[v];u==""&&!X&&M()}function Ea(a){return a==38||a==63232||a==40||a==63233}function Ja(){i.blur();g(G,this.completeId);S(this.completeString);ja()&&ba.submit()}function Oa(){i.blur();m.open("http://www.google."+xa[ca]+"/search?source=youtube-suggest"+(k>=0?"-"+k:"")+"&hl="+ca+"&q="+(Pa||escape)(this.completeString));R=O}function Qa(){if(Ra)return;if(R)f(R,B+"a");f(this,B+"b");R=this;for(var a=0;a<Y[P];a++)if(Y[a]==
R){T=a;break}}function Sa(){if(Ra){Ra=H;Qa.call(this)}}function Ia(a){if(V==""&&s!=""){t="";M();return}if(s!=V||!X)return;if(!Y||Y[P]<=0)return;if(!Da()){Ta();return}var b=Y[P];if(j)b-=1;if(R)f(R,B+"a");if(a==b||a==-1){T=-1;S(s);Ua();g(G,"f");return}else if(a>b)a=0;else if(a<-1)a=b-1;T=a;R=Y.item(a);f(R,B+"b");S(R.completeString);g(G,R.completeId)}function C(){if(W){m[Va](W);W=O}Ca(A,H);E&&Ca(F,H)}function Ta(){if(!Wa)return;Ca(A,J);E&&Ca(F,J);sa();Ra=J}function Da(){return A.visibility=="visible"}
function Xa(a){var b=ea.replace(/\$\{?tailored_search_query\}?/,a),e=w[Ya][P];j&&e--;var c=w.insertRow(e);c.onclick=Oa;c.onmousedown=Za;c.onmouseover=Qa;c.onmousemove=Sa;c.completeString=a;c.completeId=w[Ya][P]-1;f(c,B+"a");c.googleSuggestion=J;if(L){var d=y[z]("td"),h=y[z]("img");f(d,B+"f");h.src=$a;d[D](h);c[D](d)}var l=y[z]("td");l.innerHTML=b;f(l,B+"c");if(r&&ab.test(b))l[ra].paddingTop="2px";c[D](l);var x=y[z]("td");f(x,B+"d");c[D](x)}function bb(){var a=cb,b=db;if(eb==V&&a[P]>0){ya&&Xa(a[0][0]);
if(za)for(var e=0;e<a[P];e++){if(e>3)break;var c=a[e];if(!c)continue;var d=H;for(var h in b)if(b[h][0]==c[0]){d=J;break}if(!d){Xa(c[0]);break}}}}function fb(a){Z>0&&Z--;if(a[0]!=s)return;if(W){m[Va](W);W=O}V=a[0];db=a[1];gb(a[1]);K&&Xa(s);bb();T=-1;Y=w[Ya];(Y[P]>0?Ta:C)()}function hb(a){Z>0&&Z--;if(a[0]!=s)return;if(W){m[Va](W);W=O}if(eb!=a[0]){eb=a[0];cb=a[1];bb();Y=w[Ya];(Y[P]>0?Ta:C)()}}function ja(){C();I.disabled=J;if(I[v]!=i[v]){g(G,Y.item(T).completeId);I.disabled=H}else if(ib>=3||Z>=10)g(G,
"o");return J}function jb(a,b,e,c){Z++;var d=y[z]("script");d[p]("type","text/javascript");d[p]("charset","utf-8");d[p]("id",b);d[p]("src","http://"+kb+ia+(c?"&ds="+c:"")+"&jsonp="+e+"&q="+a+"&cp="+pa);var h=y.getElementById(b),l=y.getElementsByTagName("head")[0];h&&l.removeChild(h);l[D](d)}function M(){if(!Wa)return H;if(ib>=3)return H;if(t!=s&&s){var a=(Pa||escape)(s);jb(a,"jsonpACScriptTagY","window.google.ac.hry","yt");if(ya||za)jb(a,"jsonpACScriptTagG","window.google.ac.hrg","");Ua()}t=s;var b=
100;for(var e=1;e<=(Z-2)/2;++e)b*=2;b+=50;X=m.setTimeout(M,b);return J}function S(a){g(i,a);u=a}function Ua(){i.focus()}function Ba(a,b){var e=0;while(a){e+=a[b];a=a.offsetParent}return e}function lb(a,b){a[D](y.createTextNode(b))}function gb(a){while(w[Ya][P]>0)w.deleteRow(-1);var b=0;for(var e in a){if(b>=ga)break;var c=a[e];if(!c)continue;b++;var d=w.insertRow(-1);d.onclick=Ja;d.onmousedown=Za;d.onmouseover=Qa;d.onmousemove=Sa;d.completeString=c[0];d.completeId=c[2];f(d,B+"a");if(L){var h=y[z]("td");
f(h,B+"f");d[D](h)}var l=y[z]("td");lb(l,c[0]);f(l,B+"c");if(r&&ab.test(c[0]))l[ra].paddingTop="2px";d[D](l);var x=y[z]("td");b==1&&lb(x,da);f(x,B+"d");d[D](x)}if(j&&b>0){var q=w.insertRow(-1);q.onmousedown=Za;var U=y[z]("td");U.colSpan=L?3:2;f(q,B+"e");var N=y[z]("span");q[D](U);U[D](N);lb(N,j);N.onclick=function(){C();V="";m[Va](X);X=O;g(G,"x")}}}function Za(a){if(a&&a.stopPropagation){a.stopPropagation();Ta();i.focus()}else Q=J;return H}function va(){var a=i[v];a!=u&&Ga(0);u=a}function Ha(){Q=
J;i.blur();m.setTimeout(Ua,10)}function qa(a){var b=0,e=0;if(mb(a)){b=a.selectionStart;e=a.selectionEnd}if(r){var c=a.createTextRange(),d=y.selection.createRange();if(c.inRange(d)){c.setEndPoint("EndToStart",d);b=c.text[P];c.setEndPoint("EndToEnd",d);e=c.text[P]}}if(b&&e&&b==e)return b;return 0}function mb(a){try{return typeof a.selectionStart=="number"}catch(b){return H}}function nb(){Wa=J;if(i){i[p]("autocomplete","off");M()}}function ob(){Wa=H;if(i){t="";i[p]("autocomplete","on");C()}}function o(a,
b,e){var c="on"+b;if(a.addEventListener)a.addEventListener(b,e,H);else if(a.attachEvent)a.attachEvent(c,e);else{var d=a[c];a[c]=function(){var h=d.apply(this,arguments),l=e.apply(this,arguments);return h==undefined?l:l==undefined?h:l&&h}}}var H=false,O=null,J=true,Pa=encodeURIComponent,m=window,y=document,D="appendChild",P="length",Va="clearTimeout",v="value",n="indexOf",ra="style",z="createElement",p="setAttribute",Ya="rows",pb=pb||{};var Wa=J,u,s,t,V="",db,eb="",cb,pa,X=O,Y=O,R=O,T=-1,ba,i,w,A,E=O,F=O,G,I,ia,kb="suggestqueries.google.com",Z=0,ib=0,Fa=0,W=O,ha,Q=H,Ra=H,Aa,r,ma,fa,xa={ja:"co.jp"},$=navigator.userAgent.toLowerCase();Aa=$[n]("opera")!=-1;r=$[n]("msie")!=-1&&!Aa;ma=$[n]("webkit")!=-1;var qb=$[n]("firefox")!=-1,rb=$[n]("firefox/3")!=-1;fa=$[n]("windows")!=-1&&(qb||ma)||$[n]("macintosh")!=-1&&qb&&!rb;var j=O,da=O,ab=new RegExp("^[\\s\\u1100-\\u11FF\\u3040-\\u30FF\\u3130-\\u318F\\u31F0-\\u31FF\\u3400-\\u4DBF\\u4E00-\\u9FFF\\uAC00-\\uD7A3\\uF900-\\uFAFF\\uFF65-\\uFFDC]+$"),
B="google-ac-",L=H,K=H,ya=H,za=H,k=-1,$a="http://www.google.com/favicon.ico",ea="",ca="",ga=10;m.google=m.google||{};m.google.ac={install:aa,hry:fb,hrg:hb,setFieldValue:S,enable:nb,disable:ob};
})();
var goog=window.goog?window.goog:{};
goog.i18n={bidi:{}};
goog.i18n.bidi.initialized=false;
goog.i18n.bidi.isSafeUserAgent=-1;
goog.i18n.bidi.safeUserAgent=function(){
if(1==goog.i18n.bidi.isSafeUserAgent)return true;
if(0==goog.i18n.bidi.isSafeUserAgent)return false;
var userAgent=navigator.userAgent.toLowerCase();
var pat=new RegExp("applewebkit/(\\d*)");
var mt=userAgent.match(pat);
if(null==mt){
goog.i18n.bidi.isSafeUserAgent=1;
return true;
}
var ver=userAgent.match(pat)[1];
if(parseInt(ver)>=500){
goog.i18n.bidi.isSafeUserAgent=1;
return true;
}
goog.i18n.bidi.isSafeUserAgent=0;
return false;
};
goog.i18n.bidi.init=function(){
if(goog.i18n.bidi.initialized)return true;
if(!goog.i18n.bidi.safeUserAgent()){
return false;
}
goog.i18n.bidi.ltrChars_=
'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF'+
'\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF';
goog.i18n.bidi.neutralChars_=
'\u0000-\u0020!-@[-`{-\u00BF\u00D7\u00F7\u02B9-\u02FF\u2000-\u2BFF';
goog.i18n.bidi.rtlChars_='\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC';
goog.i18n.bidi.ltrDirCheckRe_=new RegExp(
'^[^'+goog.i18n.bidi.rtlChars_+']*['+goog.i18n.bidi.ltrChars_+']');
goog.i18n.bidi.rtlDirCheckRe_=new RegExp(
'^[^'+goog.i18n.bidi.ltrChars_+']*['+goog.i18n.bidi.rtlChars_+']');
goog.i18n.bidi.neutralDirCheckRe_=new RegExp(
'^['+goog.i18n.bidi.neutralChars_+']*$|^http://');
goog.i18n.bidi.initialized=true;
return true;
};
goog.i18n.bidi.isRtlText=function(str){
if(!goog.i18n.bidi.init())return false;
return goog.i18n.bidi.rtlDirCheckRe_.test(str);
};
goog.i18n.bidi.isLtrText=function(str){
if(!goog.i18n.bidi.init())return true;
return goog.i18n.bidi.ltrDirCheckRe_.test(str);
};
goog.i18n.bidi.isNeutralText=function(str){
if(!goog.i18n.bidi.init())return false;
return goog.i18n.bidi.neutralDirCheckRe_.test(str);
};
goog.i18n.bidi.setDirAttribute=function(e,field){
var text=field.value;
var dir='';
if(goog.i18n.bidi.isRtlText(text)){
dir='rtl';
}else if(!goog.i18n.bidi.isRtlText(text)){
dir='ltr';
}
field.dir=dir;
};
