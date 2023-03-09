/*
Author: Badrinath Chebbi
Date  : 02-13-02
Note:   This page displays the effect of autofill feature for a select box simulator using Input text box.
        It works well only on Internet Explorer only.NETSCAPE6 HAS SOME MINOR PROBLEMS. It doesnt work on Netscape4.
*/

        //Detect Browser
    	var IE4 = (document.all && !document.getElementById) ? true : false;
        var NS4 = (document.layers) ? true : false;
        var IE5 = (document.all && document.getElementById) ? true : false;
        var N6 = (document.getElementById && !document.all) ? true : false;

		//populate the following array with the desired values in the dropdown
		var selectbox = new Array(
		'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER' 
		);
		var typedstring="";
		
		
    function init()
	{
	document.getElementById("dropdowndiv").innerHTML="";
	document.getElementById("dropdowndiv").style.display = "";
	for(i=0;i<=selectbox.length-1;i++)
	{
	document.getElementById("dropdowndiv").innerHTML += "<div id="+i+" class='insidedropdown' onclick=javascript:sendval(this.id) onmouseover=setcursor(this) onmouseout=javascript:this.style.backgroundColor='DBEAF5'>" + selectbox[i] + "</div>";
	}
 document.getElementById("testinput").style.width=document.getElementById("dropdowndiv").offsetWidth+10;
document.getElementById("dropdowndiv").style.width=document.getElementById("dropdowndiv").offsetWidth+10;
document.getElementById("dropdowndiv").style.display="none";
	}		

	//This function executes well only in IE
	function autofill(y,evt){
	len=document.getElementById("testinput").value.length;
	//If the user presses up or down key then excute a different function
	if (NS4 || N6)
	{
	  if (evt.which==40 || evt.which==38)
	{
	updownkeypress(evt);
	}
	}
	if (IE4 || IE5)
	{
	  if (window.event.keyCode==40 || window.event.keyCode==38)	{
	updownkeypress(evt);
	}
	}

	
	//If only alphabet or Numeric key is pressed then execute this function
	if (NS4 || N6)
	{
	  if ((evt.which>=48 && evt.which<=57) || (evt.which>=65 && evt.which<=90) || (evt.which>=97 && evt.which<=122))
	{
	var goin="true";
	}
	}
	if (IE4 || IE5)
	{
		  if ((window.event.keyCode>=48 && window.event.keyCode<=57) || (window.event.keyCode>=65 && window.event.keyCode<=90) || (window.event.keyCode>=97 && window.event.keyCode<=122))
	{
	var goin="true";
	}
	}
	
	if (IE4 || IE5)
	{
		if (window.event.keyCode==8)
		{
		typedstring=document.getElementById("testinput").value+"";
		}
	} 
	if (NS4 || N6)
	{
		if (evt.which==8)
		{
		typedstring=document.getElementById("testinput").value+"";
		}
	}
	if (goin=="true")
	{
	trappedvalue='';
	typedstring=typedstring+""+document.getElementById("testinput").value.charAt(document.getElementById("testinput").value.length-1);
      if (document.getElementById("testinput").value.length==1)
	  {
	  typedstring=document.getElementById("testinput").value.charAt(0);
	  }
			for(i=0;i<=selectbox.length-1;i++)
			{
			if (selectbox[i].substring(0,len) == y || selectbox[i].substring(0,len) == y.toUpperCase())
			{
			len=document.getElementById("testinput").value.length;
			document.getElementById("testinput").value=selectbox[i];
			//<!--To stop the autofill function when the end of the string is reached
				if (len != selectbox[i].length)
				{
				var range=document.getElementById("testinput").value.substring(len,selectbox[i].length);
				}
			//-->
			  if (IE4 || IE5)
			  {
			  				if (len != selectbox[i].length)
							{
			    textrange=document.getElementById("testinput").createTextRange();
			    textrange.findText(range);
		        textrange.select();
							}
			   }	
			    break;
			}
			else
			{
						document.getElementById("testinput").value=typedstring;
			}

			}
	}			
	}

	function builddropdown(){
	document.getElementById("dropdowndiv").innerHTML="";
	document.getElementById("dropdowndiv").style.display = "";
	for(i=0;i<=selectbox.length-1;i++){
	document.getElementById("dropdowndiv").innerHTML += "<div id="+i+" class='insidedropdown' onclick=javascript:sendval(this.id) onmouseover=setcursor(this) onmouseout=javascript:this.style.backgroundColor='DBEAF5'>" + selectbox[i] + "</div>";
    //highlight the already selected option
	if (document.getElementById(i).innerHTML==document.getElementById("testinput").value)
	{
	document.getElementById(i).style.backgroundColor="69adf1";
	}
	else
	{
	document.getElementById(i).style.backgroundColor="DBEAF5";	
	}
	}
			 	if (NS4 || N6)
		{
		    document.getElementById("dropdowndiv").style.overflow="";
			document.getElementById("dropdowndiv").style.overflow="scroll";
		}	

	}
	
	function sendval(i)
	{
	document.getElementById(i).style.backgroundColor="69adf1";
	var sendval1=i;
	document.getElementById("dropdowndiv").style.display="none";
	document.getElementById("testinput").value=selectbox[sendval1];	
	}
	
 
	 function setcursor(ob)
	 {
	 	for(i=0;i<=selectbox.length-1;i++)
	 {
		ob.style.cursor="default";	 
	 document.getElementById(i).style.backgroundColor="DBEAF5";
		 	if (NS4 || N6)
		{
		ob.style.backgroundColor="#69adf1";		
		}
		if (IE4 || IE5)
		{
		ob.style.backgroundColor="#69adf1";		
		}
	 }	
	 }
	 
	 function updownkeypress(evnt)
	 {
	 for (i=0;i<=selectbox.length-1;i++)
	 {
	 if (document.getElementById("testinput").value==selectbox[i])
	 {
			if (NS4 || N6)
			{
			  if (evnt.which==40)
				{
				 if (selectbox[i+1])
				 {
				  document.getElementById("testinput").value=selectbox[i+1];
				 }
				}
			  if (evnt.which==38)
				{
				 if (selectbox[i-1])
				 {
				  document.getElementById("testinput").value=selectbox[i-1];
				 }
				}
			}
			if (IE4 || IE5)
			{
			  if (window.event.keyCode==40)	
			  {
			  if (selectbox[i+1])
				 {
			document.getElementById("testinput").value=selectbox[i+1];
			     }
			  }
			  if (window.event.keyCode==38)	
			  {
			  if (selectbox[i-1])
				 {
			document.getElementById("testinput").value=selectbox[i-1];
			     }
			  }
			}
		break;
	 }
	 }
	 }
