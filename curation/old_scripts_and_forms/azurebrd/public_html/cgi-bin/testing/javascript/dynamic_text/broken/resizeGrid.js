function adjustHeight() {
    // Calculate the height of the header.
    var headerHeight = 0;
    var header = document.getElementById("applicationHeader");

    if (header != null) {
        headerHeight = header.offsetHeight;
    }

    // Calculate the height of the footer section.
    var footerHeight = 0;
    var footer = document.getElementById("footer");
    if (footer != null) {
        footerHeight = footer.offsetHeight;
    }

    // Calculate the height of application components that are always visible.
    var applicationHeight = headerHeight + footerHeight;

    // Target height for the remainder of the screen is the browser height
    // minus the height of the fixed components.
    var targetHeight = document.body.clientHeight - applicationHeight;

    // Adjust the height of the scrollable segment.
    var scroller = document.getElementById("scroll");
    if (scroller != null) {
        targetHeight -= 30;
        window.status = "Scroll height to " + targetHeight + "=" + document.body.clientHeight + " clientHeight - " + applicationHeight + " (" + headerHeight + " headerHeight + " + footerHeight+ " footerHeight)";
        scroller.style.setExpression("height", targetHeight);
    }
}

window.onresize=adjustHeight;
 
