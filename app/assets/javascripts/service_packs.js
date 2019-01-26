// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

document.addEventListener("DOMContentLoaded", function(event) { 
	document.getElementById("view_stat").addEventListener("click", function(){
  		var xhr = new XMLHttpRequest();
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
	});
})