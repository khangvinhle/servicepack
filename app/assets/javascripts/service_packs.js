document.addEventListener("DOMContentLoaded", function(event) { 
	document.getElementById("view-stat").addEventListener("click", function(){
  		var xhr = new XMLHttpRequest();
  		// replace the link with statistics link
  		xhr.open('GET', 'http://localhost:3000/service_packs/1.json');
  		xhr.setRequestHeader('Content-Type', 'application/json');
		xhr.onload = function() {
		    if (xhr.status === 200) {
		        console.log(JSON.parse(xhr.responseText))
		    }
		    else {
		        alert('Request failed.  Returned status of ' + xhr.status);
		    }
		};
		xhr.send();
	});
})