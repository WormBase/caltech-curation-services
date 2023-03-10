var ircwindow = null;
var vncwindow = null;

function startApplets() {

   if (ircwindow != null) {
     ircwindow.close();
     ircwindow = null;
   }

   if (vncwindow != null) {
     vncwindow.close();
     vncwindow = null;
   }

   //   vcnwindow = window.open("http://frizzled.lbl.gov:5801", "VNC", "status=no,width=1100,height=800");
   ircwindow = window.open("about:blank", "My window", "scrollbars=no,status=no,width=510,height=430");

   var html = "";

   html += "<html><body>\n";
   html += "<applet code=\"IRCApplet.class\" archive=\"irc.jar,pixx.jar\" width=475 height=400>\n";
   html += "<param name=\"CABINETS\" value=\"irc.cab,securedirc.cab,pixx.cab\">\n";
   html += "<param name=\"nick\" value='"+document.forms["launcher"].username.value+"'>\n";
   html += "<param name=\"fullname\" value='"+document.forms["launcher"].username.value+"'>\n";

   html += "<param name=\"alternatenick\" value=\"Anon???\">\n";
   html += "<param name=\"host\" value=\"irc.sf.net\">\n";
   html += "<param name=\"command1\" value=\"/join #phenote\">\n";
   html += "<param name=\"gui\" value=\"pixx\">\n";
   html += "</applet>\n";
   html += "</body></html>";

//   alert(html);
   ircwindow.document.writeln(html);
   ircwindow.document.close();
}
