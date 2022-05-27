﻿<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title><#837#> - <#386#></title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="device-map/device-map.css">
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" language="JavaScript" src="/help.js"></script>
<script type="text/javascript" language="JavaScript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/js/httpApi.js"></script>
<style>
.sort_border{
position: relative;
cursor: pointer;
}
.sort_border:before{
content: "";
position: absolute;
width: 100%;
left: 0;
border-top: 1px solid #FC0;
top: 0;
}
.sort_border.decrease:before{
bottom: 0;
top: initial;
}
</style>
<script>
$(function () {
if(amesh_support && (isSwMode("rt") || isSwMode("ap")) && ameshRouter_support) {
addNewScript('/require/modules/amesh.js');
}
});
var vpnc_dev_policy_list_array = [];
var vpnc_dev_policy_list_array_ori = [];
var dhcp_staticlist_array = '<% nvram_get("dhcp_staticlist"); %>';
var manually_dhcp_list_array = new Array();
var manually_dhcp_list_array_ori = new Array();
if(pptpd_support){
var pptpd_clients = '<% nvram_get("pptpd_clients"); %>';
var pptpd_clients_subnet = pptpd_clients.split(".")[0]+"."
+pptpd_clients.split(".")[1]+"."
+pptpd_clients.split(".")[2]+".";
var pptpd_clients_start_ip = parseInt(pptpd_clients.split(".")[3].split("-")[0]);
var pptpd_clients_end_ip = parseInt(pptpd_clients.split("-")[1]);
}
var dhcp_enable = '<% nvram_get("dhcp_enable_x"); %>';
var pool_start = '<% nvram_get("dhcp_start"); %>';
var pool_end = '<% nvram_get("dhcp_end"); %>';
var pool_subnet = pool_start.split(".")[0]+"."+pool_start.split(".")[1]+"."+pool_start.split(".")[2]+".";
var pool_start_end = parseInt(pool_start.split(".")[3]);
var pool_end_end = parseInt(pool_end.split(".")[3]);
var static_enable = '<% nvram_get("dhcp_static_x"); %>';
var dhcp_staticlists = '<% nvram_get("dhcp_staticlist"); %>';
var staticclist_row = dhcp_staticlists.split('&#60');
if(yadns_support){
var yadns_enable = '<% nvram_get("yadns_enable_x"); %>';
var yadns_mode = '<% nvram_get("yadns_mode"); %>';
}
var MaxRule_extend_limit = ((isSupport("MaxRule_extend_limit") != "") ? isSupport("MaxRule_extend_limit") : 64);
var manually_dhcp_sort_type = 0;//0:increase, 1:decrease
var faq_href = "https://nw-dlcdnet.asus.com/support/forward.html?model=&type=Faq&lang="+ui_lang+"&kw=&num=101";
function initial(){
show_menu();
document.getElementById("faq").href=faq_href;
var dhcp_staticlist_row = dhcp_staticlist_array.split('&#60');
for(var i = 1; i < dhcp_staticlist_row.length; i += 1) {
var dhcp_staticlist_col = dhcp_staticlist_row[i].split('&#62');
var item_para = {
"mac" : dhcp_staticlist_col[0].toUpperCase(),
"dns" : (dhcp_staticlist_col[2] == undefined) ? "" : dhcp_staticlist_col[2],
"hostname" : (dhcp_staticlist_col[3] == undefined) ? "" : dhcp_staticlist_col[3]
};
manually_dhcp_list_array[dhcp_staticlist_col[1]] = item_para;
manually_dhcp_list_array_ori[dhcp_staticlist_col[1]] = item_para;
}
showtext(document.getElementById("LANIP"), '<% nvram_get("lan_ipaddr"); %>');
if((inet_network(document.form.lan_ipaddr.value)>=inet_network(document.form.dhcp_start.value))&&(inet_network(document.form.lan_ipaddr.value)<=inet_network(document.form.dhcp_end.value))){
document.getElementById('router_in_pool').style.display="";
}else if(dhcp_staticlists != ""){
for(var i = 1; i < staticclist_row.length; i++){
var static_ip = staticclist_row[i].split('&#62')[1];
if(static_ip == document.form.lan_ipaddr.value){
document.getElementById('router_in_pool').style.display="";
}
}
}
setTimeout("showdhcp_staticlist();", 100);
setTimeout("showDropdownClientList('setClientIP', 'mac>ip', 'all', 'ClientList_Block_PC', 'pull_arrow', 'all');", 1000);
if(pptpd_support){
var chk_vpn = check_vpn();
if(chk_vpn == true){
document.getElementById("VPN_conflict").style.display = "";
document.getElementById("VPN_conflict_span").innerHTML = "<#3483#>"+pptpd_clients;
}
}
if(yadns_support){
if(yadns_enable != 0 && yadns_mode != -1){
document.getElementById("yadns_hint").style.display = "";
document.getElementById("yadns_hint").innerHTML = "<span><#3946#></span>";
}
}
document.form.sip_server.disabled = true;
document.form.sip_server.parentNode.parentNode.style.display = "none";
if(vpn_fusion_support) {
vpnc_dev_policy_list_array = parse_vpnc_dev_policy_list('<% nvram_char_to_ascii("","vpnc_dev_policy_list"); %>');
vpnc_dev_policy_list_array_ori = vpnc_dev_policy_list_array.slice();
}
if(lyra_hide_support){
$("#dhcpEnable").hide();
}
$("#GWStatic").html("<#2485#>&nbsp;(<#2576#>&nbsp;"+MaxRule_extend_limit+")");
}
function addRow_Group(){
if(dhcp_enable != "1")
document.form.dhcp_enable_x[0].checked = true;
if(static_enable != "1")
document.form.dhcp_static_x[0].checked = true;
var rule_num = Object.keys(manually_dhcp_list_array).length;
if(rule_num >= MaxRule_extend_limit){
alert("<#2444#> " + MaxRule_extend_limit + " <#2445#>");
return false;
}
if(document.form.dhcp_staticmac_x_0.value==""){
alert("<#315#>");
document.form.dhcp_staticmac_x_0.focus();
document.form.dhcp_staticmac_x_0.select();
return false;
}else if(document.form.dhcp_staticip_x_0.value==""){
alert("<#315#>");
document.form.dhcp_staticip_x_0.focus();
document.form.dhcp_staticip_x_0.select();
return false;
}else if(check_macaddr(document.form.dhcp_staticmac_x_0, check_hwaddr_flag(document.form.dhcp_staticmac_x_0, 'inner')) == true &&
validator.validIPForm(document.form.dhcp_staticip_x_0,0) == true &&
validate_dhcp_range(document.form.dhcp_staticip_x_0) == true){
if(document.form.dhcp_dnsip_x_0.value != "") {
if(!validator.ipAddrFinal(document.form.dhcp_dnsip_x_0, 'dhcp_dns1_x'))
return false;
}
var match_flag = false;
for(var key in manually_dhcp_list_array) {
if(manually_dhcp_list_array.hasOwnProperty(key)){
var exist_ip = key;
var exist_mac = manually_dhcp_list_array[exist_ip].mac;
if(exist_mac == document.form.dhcp_staticmac_x_0.value.toUpperCase()) {
alert("<#2437#>");
document.form.dhcp_staticmac_x_0.focus();
document.form.dhcp_staticmac_x_0.select();
match_flag = true;
break;
}
if(exist_ip == document.form.dhcp_staticip_x_0.value) {
alert("<#2437#>");
document.form.dhcp_staticip_x_0.focus();
document.form.dhcp_staticip_x_0.select();
match_flag = true;
break;
}
}
}
if(match_flag) return false;
var alert_str = "";
if(document.form.dhcp_hostname_x_0.value.length > 0)
alert_str = validator.host_name(document.form.dhcp_hostname_x_0);
if(alert_str != ""){
alert(alert_str);
document.form.dhcp_hostname_x_0.focus();
document.form.dhcp_hostname_x_0.select();
return false;
}
var item_para = {
"mac" : document.form.dhcp_staticmac_x_0.value.toUpperCase(),
"dns" : document.form.dhcp_dnsip_x_0.value,
"hostname" : document.form.dhcp_hostname_x_0.value
};
manually_dhcp_list_array[document.form.dhcp_staticip_x_0.value.toUpperCase()] = item_para;
document.form.dhcp_staticip_x_0.value = "";
document.form.dhcp_staticmac_x_0.value = "";
document.form.dhcp_dnsip_x_0.value = "";
document.form.dhcp_hostname_x_0.value = "";
showdhcp_staticlist();
}else{
return false;
}
}
function del_Row(r){
var i = r.parentNode.parentNode.rowIndex;
var delIP = document.getElementById('dhcp_staticlist_table').rows[i].cells[1].innerHTML;
if(vpn_fusion_support) {
if(manually_dhcp_list_array_ori[delIP] != undefined) {
if(!confirm("Remove the client's IP binding will also delete the client's policy in the exception list of <#4069#>. Are you sure you want to delete?"))/*untranslated*/
return false;
}
}
delete manually_dhcp_list_array[delIP];
document.getElementById('dhcp_staticlist_table').deleteRow(i);
if(Object.keys(manually_dhcp_list_array).length == 0)
showdhcp_staticlist();
if(vpn_fusion_support) {
for(var i = 0; i < vpnc_dev_policy_list_array.length; i += 1) {
var tmp_array = [];
for(var i in vpnc_dev_policy_list_array){
if (vpnc_dev_policy_list_array.hasOwnProperty(i)) {
if(vpnc_dev_policy_list_array[i][0] != delIP) {
tmp_array.push(vpnc_dev_policy_list_array[i]);
}
}
}
vpnc_dev_policy_list_array = tmp_array;
}
}
}
function edit_Row(r){
var i=r.parentNode.parentNode.rowIndex;
document.form.dhcp_staticmac_x_0.value = document.getElementById('dhcp_staticlist_table').rows[i].cells[0].innerHTML;
document.form.dhcp_staticip_x_0.value = document.getElementById('dhcp_staticlist_table').rows[i].cells[1].innerHTML;
del_Row(r);
}
function showdhcp_staticlist(){
var code = "";
var clientListEventData = [];
code += '<table width="100%" cellspacing="0" cellpadding="4" align="center" class="list_table" id="dhcp_staticlist_table">';
if(Object.keys(manually_dhcp_list_array).length == 0)
code += '<tr><td style="color:#FFCC00;"><#2372#></td></tr>';
else {
var userIconBase64 = "NoIcon";
var clientName, deviceType, deviceVender;
var sortData = Object.keys(manually_dhcp_list_array).sort(
function(a, b){
if(manually_dhcp_sort_type == 0)
return inet_network(a) - inet_network(b);
else if(manually_dhcp_sort_type == 1)
return inet_network(b) - inet_network(a);
}
)
$.each(sortData, function( index, value ) {
var clientIP = value;
var clientMac = manually_dhcp_list_array[clientIP]["mac"].toUpperCase();
var clientDNS = manually_dhcp_list_array[clientIP]["dns"];
if(clientDNS == "")
clientDNS = "<#3076#>";
var clientHostname = manually_dhcp_list_array[clientIP]["hostname"];
var clientIconID = "clientIcon_" + clientMac.replace(/\:/g, "");
if(clientList[clientMac]) {
clientName = (clientList[clientMac].nickName == "") ? clientList[clientMac].name : clientList[clientMac].nickName;
deviceType = clientList[clientMac].type;
deviceVender = clientList[clientMac].vendor;
}
else {
clientName = "New device";
deviceType = 0;
deviceVender = "";
}
code += '<tr><td width="30%" align="center">';
code += '<table style="width:100%;"><tr><td style="width:35%;height:56px;border:0px;">';
if(clientList[clientMac] == undefined) {
code += '<div id="' + clientIconID + '" class="clientIcon type0"></div>';
}
else {
if(usericon_support) {
userIconBase64 = getUploadIcon(clientMac.replace(/\:/g, ""));
}
if(userIconBase64 != "NoIcon") {
code += '<div id="' + clientIconID + '" style="text-align:center;"><img class="imgUserIcon_card" src="' + userIconBase64 + '"></div>';
}
else if(deviceType != "0" || deviceVender == "") {
code += '<div id="' + clientIconID + '" class="clientIcon type' + deviceType + '"></div>';
}
else if(deviceVender != "" ) {
var venderIconClassName = getVenderIconClassName(deviceVender.toLowerCase());
if(venderIconClassName != "" && !downsize_4m_support) {
code += '<div id="' + clientIconID + '" class="venderIcon ' + venderIconClassName + '"></div>';
}
else {
code += '<div id="' + clientIconID + '" class="clientIcon type' + deviceType + '"></div>';
}
}
}
code += '</td><td style="width:65%;border:0px;">';
code += '<div>' + clientName + '</div>';
code += '<div>' + clientMac + '</div>';
code += '</td></tr></table>';
code += '</td>';
code += '<td width="20%">'+ clientIP +'</td>';
code += '<td width="20%">'+ clientDNS +'</td>';
code += '<td width="20%" style="word-break:break-all;">'+ clientHostname +'</td>';
code += '<td width="10%">';
code += '<input class="remove_btn" onclick="del_Row(this);" value=""/></td></tr>';
if(validator.mac_addr(clientMac))
clientListEventData.push({"mac" : clientMac, "name" : clientName, "ip" : clientIP, "callBack" : "DHCP"});
});
}
code += '</table>';
document.getElementById("dhcp_staticlist_Block").innerHTML = code;
for(var i = 0; i < clientListEventData.length; i += 1) {
var clientIconID = "clientIcon_" + clientListEventData[i].mac.replace(/\:/g, "");
var clientIconObj = $("#dhcp_staticlist_Block").children("#dhcp_staticlist_table").find("#" + clientIconID + "")[0];
var paramData = JSON.parse(JSON.stringify(clientListEventData[i]));
paramData["obj"] = clientIconObj;
$("#dhcp_staticlist_Block").children("#dhcp_staticlist_table").find("#" + clientIconID + "").click(paramData, popClientListEditTable);
}
}
function applyRule(){
if(validForm()){
dhcp_staticlist_array = "";
Object.keys(manually_dhcp_list_array).forEach(function(key) {
dhcp_staticlist_array += "<" + manually_dhcp_list_array[key].mac + ">" + key + ">" + manually_dhcp_list_array[key].dns + ">" + manually_dhcp_list_array[key].hostname;
});
document.form.dhcp_staticlist.value = dhcp_staticlist_array;
if(vpn_fusion_support) {
if(vpnc_dev_policy_list_array.toString() != vpnc_dev_policy_list_array_ori.toString()) {
var action_script_tmp = "restart_vpnc_dev_policy;" + document.form.action_script.value;
document.form.action_script.value = action_script_tmp;
var parseArrayToStr_vpnc_dev_policy_list = function(_array) {
var vpnc_dev_policy_list = "";
for(var i = 0; i < _array.length; i += 1) {
if(_array[i].length != 0) {
if(i != 0)
vpnc_dev_policy_list += "<";
var temp_ipaddr = _array[i][0];
var temp_vpnc_idx = _array[i][1];
var temp_active = _array[i][2];
var temp_destination_ip = "";
vpnc_dev_policy_list += temp_active + ">" + temp_ipaddr + ">" + temp_destination_ip + ">" + temp_vpnc_idx;
}
}
return vpnc_dev_policy_list;
};
document.form.vpnc_dev_policy_list.disabled = false;
document.form.vpnc_dev_policy_list_tmp.disabled = false;
document.form.vpnc_dev_policy_list_tmp.value = parseArrayToStr_vpnc_dev_policy_list(vpnc_dev_policy_list_array_ori);
document.form.vpnc_dev_policy_list.value = parseArrayToStr_vpnc_dev_policy_list(vpnc_dev_policy_list_array);
}
}
if(based_modelid == "MAP-AC1300" || based_modelid == "MAP-AC2200" || based_modelid == "VZW-AC1300" || based_modelid == "MAP-AC1750")
alert("By applying new LAN settings, please reboot all Lyras connected to main Lyra manually.");
if(amesh_support && isSwMode("rt") && ameshRouter_support) {
var radio_value = (document.form.dhcp_enable_x[0].checked) ? 1 : 0;
if(!AiMesh_confirm_msg("DHCP_Server", radio_value))
return false;
}
showLoading();
document.form.submit();
}
}
function validate_dhcp_range(ip_obj){
var ip_num = inet_network(ip_obj.value);
var subnet_head, subnet_end;
if(ip_num <= 0){
alert(ip_obj.value+" <#329#>");
ip_obj.value = "";
ip_obj.focus();
ip_obj.select();
return 0;
}
subnet_head = getSubnet(document.form.lan_ipaddr.value, document.form.lan_netmask.value, "head");
subnet_end = getSubnet(document.form.lan_ipaddr.value, document.form.lan_netmask.value, "end");
if(ip_num <= subnet_head || ip_num >= subnet_end){
alert(ip_obj.value+" <#329#>");
ip_obj.value = "";
ip_obj.focus();
ip_obj.select();
return 0;
}
return 1;
}
function validForm(){
var re = new RegExp('^[a-zA-Z0-9][a-zA-Z0-9\.\-]*[a-zA-Z0-9]$','gi');
if((!re.test(document.form.lan_domain.value) || document.form.lan_domain.value.indexOf("asuscomm.com") > 0) && document.form.lan_domain.value != ""){
alert("<#328#>");
document.form.lan_domain.focus();
document.form.lan_domain.select();
return false;
}
if(!validator.ipAddrFinal(document.form.dhcp_gateway_x, 'dhcp_gateway_x') ||
!validator.ipAddrFinal(document.form.dhcp_dns1_x, 'dhcp_dns1_x') ||
!validator.ipAddrFinal(document.form.dhcp_wins_x, 'dhcp_wins_x'))
return false;
if(tmo_support && !validator.ipAddrFinal(document.form.sip_server, 'sip_server'))
return false;
if(!validate_dhcp_range(document.form.dhcp_start)
|| !validate_dhcp_range(document.form.dhcp_end))
return false;
var dhcp_start_num = inet_network(document.form.dhcp_start.value);
var dhcp_end_num = inet_network(document.form.dhcp_end.value);
if(dhcp_start_num > dhcp_end_num){
var tmp = document.form.dhcp_start.value;
document.form.dhcp_start.value = document.form.dhcp_end.value;
document.form.dhcp_end.value = tmp;
}
var default_pool = new Array();
default_pool =get_default_pool(document.form.lan_ipaddr.value, document.form.lan_netmask.value);
if((inet_network(document.form.dhcp_start.value) < inet_network(default_pool[0])) || (inet_network(document.form.dhcp_end.value) > inet_network(default_pool[1]))){
if(confirm("<#2436#>")){ //Acceptable DHCP ip pool : "+default_pool[0]+"~"+default_pool[1]+"\n
document.form.dhcp_start.value=default_pool[0];
document.form.dhcp_end.value=default_pool[1];
}else{return false;}
}
if(!validator.range(document.form.dhcp_lease, 120, 604800))
return false;
document.form.dhcp_start.value = ipFilterZero(document.form.dhcp_start.value);
document.form.dhcp_end.value = ipFilterZero(document.form.dhcp_end.value);
return true;
}
function done_validating(action){
refreshpage();
}
function get_default_pool(ip, netmask){
z=0;
tmp_ip=0;
for(i=0;i<document.form.lan_ipaddr.value.length;i++){
if (document.form.lan_ipaddr.value.charAt(i) == '.') z++;
if (z==3){ tmp_ip=i+1; break;}
}
post_lan_ipaddr = document.form.lan_ipaddr.value.substr(tmp_ip,3);
c=0;
tmp_nm=0;
for(i=0;i<document.form.lan_netmask.value.length;i++){
if (document.form.lan_netmask.value.charAt(i) == '.') c++;
if (c==3){ tmp_nm=i+1; break;}
}
var post_lan_netmask = document.form.lan_netmask.value.substr(tmp_nm,3);
var nm = new Array("0", "128", "192", "224", "240", "248", "252");
for(i=0;i<nm.length;i++){
if(post_lan_netmask==nm[i]){
gap=256-Number(nm[i]);
subnet_set = 256/gap;
for(j=1;j<=subnet_set;j++){
if(post_lan_ipaddr < j*gap){
pool_start=(j-1)*gap+1;
pool_end=j*gap-2;
break;
}
}
var default_pool_start = subnetPostfix(document.form.dhcp_start.value, pool_start, 3);
var default_pool_end = subnetPostfix(document.form.dhcp_end.value, pool_end, 3);
var default_pool = new Array(default_pool_start, default_pool_end);
return default_pool;
break;
}
}
}
function setClientIP(macaddr, ipaddr){
document.form.dhcp_staticmac_x_0.value = macaddr;
document.form.dhcp_staticip_x_0.value = ipaddr;
hideClients_Block();
}
function hideClients_Block(){
document.getElementById("pull_arrow").src = "/images/arrow-down.gif";
document.getElementById('ClientList_Block_PC').style.display='none';
}
function pullLANIPList(obj){
var element = document.getElementById('ClientList_Block_PC');
var isMenuopen = element.offsetWidth > 0 || element.offsetHeight > 0;
if(isMenuopen == 0){
obj.src = "/images/arrow-top.gif"
element.style.display = 'block';
document.form.dhcp_staticmac_x_0.focus();
}
else
hideClients_Block();
}
function check_macaddr(obj,flag){ //control hint of input mac address
if(flag == 1){
var childsel=document.createElement("div");
childsel.setAttribute("id","check_mac");
childsel.style.color="#FFCC00";
obj.parentNode.appendChild(childsel);
document.getElementById("check_mac").innerHTML="<#347#>";
document.getElementById("check_mac").style.display = "";
obj.focus();
obj.select();
return false;
}else if(flag == 2){
var childsel=document.createElement("div");
childsel.setAttribute("id","check_mac");
childsel.style.color="#FFCC00";
obj.parentNode.appendChild(childsel);
document.getElementById("check_mac").innerHTML="<#308#>";
document.getElementById("check_mac").style.display = "";
obj.focus();
obj.select();
return false;
}else{
document.getElementById("check_mac") ? document.getElementById("check_mac").style.display="none" : true;
return true;
}
}
function check_vpn(){ //true: (DHCP ip pool & static ip ) conflict with VPN clients
if(pool_subnet == pptpd_clients_subnet
&& ((pool_start_end >= pptpd_clients_start_ip && pool_start_end <= pptpd_clients_end_ip)
|| (pool_end_end >= pptpd_clients_start_ip && pool_end_end <= pptpd_clients_end_ip)
|| (pptpd_clients_start_ip >= pool_start_end && pptpd_clients_start_ip <= pool_end_end)
|| (pptpd_clients_end_ip >= pool_start_end && pptpd_clients_end_ip <= pool_end_end))
){
return true;
}
if(dhcp_staticlists != ""){
for(var i = 1; i < staticclist_row.length; i++){
var static_subnet ="";
var static_end ="";
var static_ip = staticclist_row[i].split('&#62')[1];
static_subnet = static_ip.split(".")[0]+"."+static_ip.split(".")[1]+"."+static_ip.split(".")[2]+".";
static_end = parseInt(static_ip.split(".")[3]);
if(static_subnet == pptpd_clients_subnet
&& static_end >= pptpd_clients_start_ip
&& static_end <= pptpd_clients_end_ip){
return true;
}
}
}
return false;
}
function parse_vpnc_dev_policy_list(_oriNvram) {
var parseArray = [];
var oriNvramRow = decodeURIComponent(_oriNvram).split('<');
for(var i = 0; i < oriNvramRow.length; i += 1) {
if(oriNvramRow[i] != "") {
var oriNvramCol = oriNvramRow[i].split('>');
var eachRuleArray = new Array();
if(oriNvramCol.length == 4) {
var temp_ipaddr = oriNvramCol[1];
var temp_vpnc_idx = oriNvramCol[3];
var temp_active = oriNvramCol[0];
eachRuleArray.push(temp_ipaddr);
eachRuleArray.push(temp_vpnc_idx);
eachRuleArray.push(temp_active);
}
parseArray.push(eachRuleArray);
}
}
return parseArray;
}
function sortClientIP(){
manually_dhcp_sort_type
if($(".sort_border").hasClass("decrease")){
$(".sort_border").removeClass("decrease");
manually_dhcp_sort_type = 0;
}
else{
$(".sort_border").addClass("decrease");
manually_dhcp_sort_type = 1;
}
showdhcp_staticlist();
}
</script>
</head>
<body onload="initial();" onunLoad="return unload_body();" class="bg">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="Advanced_DHCP_Content.asp">
<input type="hidden" name="next_page" value="Advanced_GWStaticRoute_Content.asp">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply_new">
<input type="hidden" name="action_wait" value="30">
<input type="hidden" name="action_script" value="restart_net_and_phy">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="lan_ipaddr" value="<% nvram_get("lan_ipaddr"); %>">
<input type="hidden" name="lan_netmask" value="<% nvram_get("lan_netmask"); %>">
<input type="hidden" name="dhcp_staticlist" value="">
<input type="hidden" name="vpnc_dev_policy_list" value="" disabled>
<input type="hidden" name="vpnc_dev_policy_list_tmp" value="" disabled>
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760" border="0" cellpadding="4" cellspacing="0" class="FormTitle" id="FormTitle">
<tbody>
<tr>
<td bgcolor="#4D595D" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle"><#384#> - <#386#></div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc"><#2469#></div>
<div id="router_in_pool" class="formfontdesc" class="hint-color" style="display:none;"><#2470#><span id="LANIP"></span></div>
<div id="VPN_conflict" class="formfontdesc" class="hint-color" style="display:none;"><span id="VPN_conflict_span"></span></div>
<div class="formfontdesc" style="margin-top:-10px;">
<a id="faq" href="" target="_blank" style="font-family:Lucida Console;text-decoration:underline;"><#2485#>&nbsp;FAQ</a>
</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead>
<tr>
<td colspan="2"><#3240#></td>
</tr>
</thead>
<tr id="dhcpEnable">
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,1);"><#2468#></a></th>
<td>
<input type="radio" value="1" name="dhcp_enable_x" class="content_input_fd" onClick="return change_common_radio(this, 'LANHostConfig', 'dhcp_enable_x', '1')" <% nvram_match("dhcp_enable_x", "1", "checked"); %>><#186#>
<input type="radio" value="0" name="dhcp_enable_x" class="content_input_fd" onClick="return change_common_radio(this, 'LANHostConfig', 'dhcp_enable_x', '0')" <% nvram_match("dhcp_enable_x", "0", "checked"); %>><#185#>
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,2);"><#2479#></a></th>
<td>
<input type="text" maxlength="32" class="input_25_table" name="lan_domain" value="<% nvram_get("lan_domain"); %>" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,3);"><#2491#></a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_start" value="<% nvram_get("dhcp_start"); %>" onKeyPress="return validator.isIPAddr(this,event);" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,4);"><#2489#></a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_end" value="<% nvram_get("dhcp_end"); %>" onKeyPress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,5);"><#2481#> (<#3047#>)</a></th>
<td>
<input type="text" maxlength="6" name="dhcp_lease" class="input_15_table" value="<% nvram_get("dhcp_lease"); %>" onKeyPress="return validator.isNumber(this,event)" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,6);"><#305#></a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_gateway_x" value="<% nvram_get("dhcp_gateway_x"); %>" onKeyPress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr>
<th>Sip Server</th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="sip_server" value="<% nvram_get("sip_server"); %>" onKeyPress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="margin-top:8px">
<thead>
<tr>
<td colspan="2"><#2539#></td>
</tr>
</thead>
<tr>
<th width="200"><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,7);"><#2538#> 1</a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_dns1_x" value="<% nvram_get("dhcp_dns1_x"); %>" onKeyPress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
<div id="yadns_hint" style="display:none;"></div>
</td>
</tr>
<tr>
<th width="200"><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,7);"><#2538#> 2</a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_dns2_x" value="<% nvram_get("dhcp_dns2_x"); %>" onKeyPress="return validator.isIPAddr(this,event)">
</td>
</tr>
<tr>
<th><#353#></th>
<td>
<input type="radio" value="1" name="dhcpd_dns_router" class="content_input_fd" onClick="return change_common_radio(this, 'LANHostConfig', 'dhcpd_dns_router', '1')" <% nvram_match("dhcpd_dns_router", "1", "checked"); %>><#186#>
<input type="radio" value="0" name="dhcpd_dns_router" class="content_input_fd" onClick="return change_common_radio(this, 'LANHostConfig', 'dhcpd_dns_router', '0')" <% nvram_match("dhcpd_dns_router", "0", "checked"); %>><#185#>
</td>
</tr>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,8);"><#2556#></a></th>
<td>
<input type="text" maxlength="15" class="input_15_table" name="dhcp_wins_x" value="<% nvram_get("dhcp_wins_x"); %>" onkeypress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off"/>
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable" style="margin-top:8px;" >
<thead>
<tr>
<td colspan="3"><#2484#></td>
</tr>
</thead>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,9);"><#2483#></a></th>
<td colspan="2" style="text-align:left;">
<input type="radio" value="1" name="dhcp_static_x" onclick="return change_common_radio(this, 'LANHostConfig', 'dhcp_static_x', '1')" <% nvram_match("dhcp_static_x", "1", "checked"); %> /><#186#>
<input type="radio" value="0" name="dhcp_static_x" onclick="return change_common_radio(this, 'LANHostConfig', 'dhcp_static_x', '0')" <% nvram_match("dhcp_static_x", "0", "checked"); %> /><#185#>
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable_table" style="margin-top:8px;">
<thead>
<tr>
<td colspan="5" id="GWStatic"></td>
</tr>
</thead>
<tr>
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(5,10);"><#1521#> (<#2913#>)</a></th>
<th class="sort_border" onClick="sortClientIP()"><#289#></th>
<th><#2538#> (Optional)</th>
<th><#2522#> (Optional)</th>
<th><#2575#></th>
</tr>
<tr>
<td width="30%">
<input type="text" class="input_20_table" maxlength="17" name="dhcp_staticmac_x_0" style="margin-left:-20px;width:190px;" onKeyPress="return validator.isHWAddr(this,event)" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off" placeholder="ex: <% nvram_get("lan_hwaddr"); %>">
<img id="pull_arrow" height="14px;" src="/images/arrow-down.gif" style="position:absolute;*margin-left:-3px;*margin-top:1px;" onclick="pullLANIPList(this);" title="<#3055#>">
<div id="ClientList_Block_PC" class="clientlist_dropdown" style="margin-left:-1px;"></div>
</td>
<td width="20%">
<input type="text" class="input_15_table" maxlength="15" name="dhcp_staticip_x_0" onkeypress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
</td>
<td width="20%">
<input type="text" class="input_15_table" maxlength="15" name="dhcp_dnsip_x_0" onkeypress="return validator.isIPAddr(this,event)" autocorrect="off" autocapitalize="off">
</td>
<td width="20%">
<input type="text" class="input_15_table" maxlength="32" name="dhcp_hostname_x_0" onkeypress="return validator.isString(this, event)" autocorrect="off" autocapitalize="off">
</td>
<td width="10%">
<div>
<input type="button" class="add_btn" onClick="addRow_Group();" value="">
</div>
</td>
</tr>
</table>
<div id="dhcp_staticlist_Block"></div>
<div class="apply_gen">
<input type="button" name="button" class="button_gen" onclick="applyRule();" value="<#195#>"/>
</div>
</td>
</tr>
</tbody>
</table>
</td>
</form>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
<div id="footer"></div>
</body>
</html>

