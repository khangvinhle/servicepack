//use <% javascript_include_tag %>
function loadServicePack() {
	var co = document.querySelector("#select-sp");
	if (co.selectedIndex == 0) {
		document.querySelector("#sp-content").innerHTML = "<hr/>Please select a Service Pack";
		return;
	}
	var comp = co.options[co.selectedIndex];
	var str = "<hr/> Activation Date:" + comp.dataset.start + "<br/>";
	str += "Expiration Date:" + comp.dataset.end + "<br/>";
	str += "Capacity: " + comp.dataset.cap + "<br/>";
	str += "Remained: " + comp.dataset.rem + "<br/>";
	//click for more
	document.querySelector("#sp-content").innerHTML = str;
}
document.addEventListener("DOMContentLoaded", function(event) { 
	document.querySelector("#select-sp").addEventListener("change", loadServicePack);
})