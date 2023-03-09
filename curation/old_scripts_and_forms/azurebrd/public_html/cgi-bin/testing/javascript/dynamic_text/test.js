	window.onload = function() {
		document.getElementById('txtArea').className = 'inv';
	}

	function hide(f,hideWhich){
		var toHide,toShow;

		if(hideWhich == 1){
			toHide = 'txtToHide';
			toShow = 'txtArea';
		}else{
			toHide = 'txtArea';
			toShow = 'txtToHide';
		}

		document.getElementById(toHide).className = 'inv';
		document.getElementById(toShow).className = '';
		document.getElementById(toShow).value = document.getElementById(toHide).value;
		if(hideWhich == 1){ document.getElementById(toShow).focus(); }
	}
