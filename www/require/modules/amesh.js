﻿function updateAMeshCount() {
if(lastName != "iconAMesh") {
$.ajax({
url: '/ajax_onboarding.asp',
dataType: 'script',
success: function(response) {
var get_cfg_clientlist_num = 0;
if(get_cfg_clientlist.length > 1) {
for (var idx in get_cfg_clientlist) {
if(get_cfg_clientlist.hasOwnProperty(idx)) {
if(idx != 0) {
get_cfg_clientlist_num++;
}
}
}
show_AMesh_status(get_cfg_clientlist_num, 1);
}
else
show_AMesh_status(0, 1);
}
});
}
}
function show_AMesh_status(num, flag) {
document.getElementById("ameshNumber").innerHTML = "<#1055#>: <span>" + num + "</span>";
}
function initial_amesh_obj() {
if($('link[rel=stylesheet][href~="/device-map/amesh.css"]').length == 1) {
$('link[rel=stylesheet][href~="/device-map/amesh.css"]').remove();
}
if($('.amesh_popup_bg').length > 0) {
$('.amesh_popup_bg').remove();
}
}
function check_wl_auth_support(_obj, _wl_unit) {
var auth_mode = _obj.val();
var auth_text = _obj.text();
var support_flag = false;
var support_auth = ["psk2", "pskpsk2"];
if(isSupport("wifi6e")){
var wl_band = httpApi.nvramGet(["wl" + _wl_unit + "_nband"])["wl" + _wl_unit + "_nband"];//1:5G, 2:2.4G, 4:6G
if(wl_band == 4)
support_auth = ["sae"];
else
support_auth = ["psk2", "pskpsk2", "psk2sae"];
}
else{
var re_count = httpApi.hookGet("get_cfg_clientlist", true).length;
if(re_count > 1)// have re node
support_auth = ["psk2", "pskpsk2", "psk2sae"];
else
support_auth = ["psk2", "pskpsk2"];
}
for (var idx in support_auth) {
if (support_auth.hasOwnProperty(idx)) {
if(auth_mode == support_auth[idx]) {
support_flag = true;
break;
}
}
}
if(!support_flag) {
var confirm_msg = "<#1027#>".replace("#AUTHMODE", auth_text);
support_flag = confirm(confirm_msg);
}
return support_flag;
}
function AiMesh_confirm_msg(_name, _value) {
var check_operation_mode = function(_value) {
switch(parseInt(_value)) {
case 2 :
return confirm("<#1017#>\n<#1014#>");//Repeater
break;
case 4 :
return confirm("<#1018#>\n<#1014#>");//Media Bridge
break;
default :
return true;
}
};
var check_feature_status = function(_obj, _value) {
if(_obj.value != _value)
return confirm(_obj.text);
else
return true;
};
var check_wireless_ssid_psk = function(_value) {
var current_ssid = _value["current"]["ssid"];
var current_psk = _value["current"]["psk"];
var original_ssid = _value["original"]["ssid"];
var original_psk = _value["original"]["psk"];
var current_node_count = [<% get_cfg_clientlist(); %>][0].length - 1;
var total_node_count = [<% get_onboardingstatus(); %>][0]["cfg_obcount"];
if(total_node_count != "" && current_node_count < total_node_count) {
if(current_ssid == original_ssid && current_psk == original_psk)
return true;
else if(current_ssid != original_ssid && current_psk != original_psk)
return confirm("<#1019#>\n<#1014#>");//SSID & WPA key
else if(current_ssid != original_ssid)
return confirm("<#1020#>\n<#1014#>");//SSID
else if(current_psk != original_psk)
return confirm("<#1021#>\n<#1014#>");/* untranslated */
}
else
return true;
};
var check_wireless_country_code = function() {
return confirm("<#1022#>\n<#1014#>");//Country code
};
var feature_value = {
"Wireless_Radio" : {
"value" : 1,
"text" : "<#1023#>\n<#1014#>" //Disable Radio
},
"Wireless_Hide" : {
"value" : 0,
"text" : "<#1024#>\n<#1014#>" //Hide SSID
},
"Wireless_Hide_WPS" : {
"value" : 0,
"text" : "<#1025#>\n<#1014#>" //Hide SSID
},
"DHCP_Server" : {
"value" : 1,
"text" : "<#1026#>\n<#1014#>" //Disable DHCP
}
};
var confirm_flag = true;
switch(_name) {
case "Operation_Mode" :
confirm_flag = check_operation_mode(_value);
break;
case "Wireless_Radio" :
case "Wireless_Hide" :
case "Wireless_Hide_WPS" :
case "DHCP_Server" :
confirm_flag = check_feature_status(feature_value[_name], _value);
break;
case "Wireless_SSID_PSK" :
confirm_flag = check_wireless_ssid_psk(_value);
break;
case "Wireless_CountryCode" :
confirm_flag = check_wireless_country_code();
break;
}
return confirm_flag;
}

