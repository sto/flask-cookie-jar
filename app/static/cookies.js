function getCookiesDict() {
	var cookies_dict = {};
	if (document.cookie && document.cookie != '') {
		var cookie_list = document.cookie.split(';');
		for (var i = 0; i < cookie_list.length; i++) {
			var cookie_item = cookie_list[i].split("=");
			var cname = decodeURIComponent(cookie_item[0].replace(/^ /, ''));
			var cvalue = decodeURIComponent(cookie_item[1]);
			cookies_dict[cname] = cvalue;
		}
	}
	return cookies_dict;
}

function getCookieNames() {
	var cookie_names = Object.keys(getCookiesDict());
	cookie_names.sort();
	return cookie_names;
}

function getCookieValue(key) {
	return getCookiesDict()[key];
}

function jsCookieNamesAlert() {
	var msg = "Cookies visibles desde JavaScript\n\n";
	msg += getCookieNames().sort().join('\n');
	alert(msg);
}

function setSessionCookie(cname, cvalue) {
	document.cookie = cname + "=" + cvalue + ";";
}

function jsSetCookiePrompt() {
	var cname_value = prompt("Introduce una cookie", "nombre=valor");
	if (cname_value != null && cname_value != "") {
		document.cookie = cname_value;
		location.reload();
	}
}

function delSessionCookie(cname) {
	document.cookie = cname + "=;max-age=0;";
}

function jsDelCookiePrompt() {
	var cname = prompt("Nombre de la cookie a borrar", "nombre");
	if (cname != null && cname != "") {
		document.cookie = cname + "=;max-age=0;";
		location.reload();
	}
}
