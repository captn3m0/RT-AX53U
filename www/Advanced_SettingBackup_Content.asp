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
<title><#860#> - <#429#></title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="other.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script>
var varload = 0;
var lan_ipaddr = '<% nvram_get("lan_ipaddr"); %>';
var ddns_enable = '<% nvram_get("ddns_enable_x"); %>'; //0: disable, 1: enable
var ddns_server = '<% nvram_get("ddns_server_x"); %>'; //WWW.ASUS.COM
var oauth_auth_status_tmp = '<% nvram_get("oauth_auth_status"); %>'; //2: registed
function initial(){
show_menu();
if(account_binding_support && oauth_auth_status_tmp == '2')
document.getElementById("transfer_ddns_field").style.display = "none";
else if(ddns_enable == 1 && ddns_server == "WWW.ASUS.COM")
document.getElementById("transfer_ddns_field").style.display = "";
else
document.getElementById("transfer_ddns_field").style.display = "none";
document.form.file.onchange = function() {
uploadSetting();
};
if(!bwdpi_support){
$("#factorydefault_hint").attr("onclick", "").unbind("click");
$("#factorydefault_hint").attr("onclick", "openHint(19, 1);");
$("#restoreInit_div").css("display", "none");
$("#restoreInit").attr("disabled", "disabled");
$("#restoreInit").prop("checked", false);
}
}
function restoreRule(_flag){
var alert_string = "<#3177#>";
if($('#restoreInit').prop("checked") && bwdpi_support)
alert_string = "<#3184#>";
if(lan_ipaddr != '<% nvram_default_get("lan_ipaddr"); %>')
alert_string += "<#3179#>\n\n".replace("192.168.1.1", '<% nvram_default_get("lan_ipaddr"); %>');
alert_string += "<#3178#>";
if(confirm(alert_string)){
document.form.action1.blur();
if($('#restoreInit').prop("checked") && bwdpi_support)
document.restoreform.action_mode.value = "restore_erase";
else
document.restoreform.action_mode.value = "Restore";
showtext(document.getElementById("loading_block2"), "<#3137#>");
document.getElementById('loading_block3').style.display = "none";
showLoading();
document.restoreform.submit();
}
else
return false;
}
function saveSetting(mode){
var flag = 0;
var remove_passwd = 0;
if(ddns_enable == 1){
if(ddns_server != "WWW.ASUS.COM"){
flag = 1;
}
else{ //ASUS DDNS
flag = document.getElementById("transfer_ddns").checked ? 1 : 0;
}
}
remove_passwd = document.getElementById("remove_passwd").checked ? 1 : 0;
if(isp_customize_tool_support)
location.href='Settings_'+document.form.productid.value+'.CFG?path=' + flag+'&remove_passwd='+remove_passwd;
else
location.href='Settings_'+productid+'.CFG?path=' + flag+'&remove_passwd='+remove_passwd;
}
function uploadSetting(){
var file_obj = document.form.file;
var file_obj_name = file_obj.value.toUpperCase();
if(file_obj_name == ""){
alert("<#332#>");
file_obj.focus();
}
else if(file_obj_name.length < 6 ||
file_obj_name.lastIndexOf(".CFG") < 0 ||
file_obj_name.lastIndexOf(".CFG") != (file_obj_name.length)-4){
alert("<#3189#>");
file_obj.focus();
}
else{
disableCheckChangedStatus();
showtext(document.getElementById("loading_block2"), "<#3175#>");
document.getElementById('loading_block3').style.display = "none";
document.form.submit();
}
}
var dead = 0;
function detect_httpd(){
$.ajax({
url: '/httpd_check.xml',
dataType: 'xml',
timeout: 1500,
error: function(xhr){
dead++;
if(dead < 6){
setTimeout("detect_httpd();", 1000);
}else{
document.getElementById('loading_block1').style.display = "none";
document.getElementById('loading_block2').style.display = "none";
document.getElementById('loading_block3').style.display = "";
/*if(findasus_support){
document.getElementById('loading_block3').innerHTML = "<div><#451#></div>";
}else{*/
document.getElementById('loading_block3').innerHTML = "<div><#384#>.<#361#></div>";
}
},
success: function(){
setTimeout("hideLoadingBar();",1000);
location.href = "/";
}
});
}
function selectSetting() {
document.form.file.click();
}
</script>
</head>
<body onload="initial();" class="bg">
<div id="TopBanner"></div>
<div id="LoadingBar" class="popup_bar_bg">
<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
<tr>
<td height="80">
<div id="loading_block1" class="Bar_container">
<div id="proceeding_img_text"></div>
<div id="proceeding_img"></div>
</div>
<div id="loading_block2" style="margin:5px auto; width:85%;"></div>
<div id="loading_block3" style="margin:5px auto; width:85%; font-size:12pt;"></div>
</td>
</tr>
</table>
<!--[if lte IE 6.5]><iframe class="hackiframe"></iframe><![endif]-->
</div>
<div id="hiddenMask" class="popup_bg">
<table cellpadding="5" cellspacing="0" id="dr_sweet_advise" class="dr_sweet_advise" align="center">
<tr>
<td>
<div class="drword" id="drword"><#385#> <#382#>...
<br/>
<br/>
</div>
<div class="drImg"><img src="images/alertImg.png"></div>
<div style="height:70px; "></div>
</td>
</tr>
</table>
<!--[if lte IE 6.5]><iframe class="hackiframe"></iframe><![endif]-->
</div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="upload.cgi" target="hidden_frame" enctype="multipart/form-data">
<input type="hidden" name="action_mode" value="">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="Advanced_SettingBackup_Content.asp">
<input type="hidden" name="next_page" value="Advanced_SettingBackup_Content.asp">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
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
<td align="left" valign="top" >
<table width="760px" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle">
<tbody>
<tr>
<td bgcolor="#4D595D" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle"><#424#> - <#429#></div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc"><#3188#></div>
<table width="100%" border="1" align="center" cellpadding="6" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<tr>
<th width="25%" align="right">
<a id="factorydefault_hint" class="hintstyle" href="javascript:void(0);" onclick="openHint(19,4)"><#3182#></a>
</th>
<td colspan = "4">
<div style="float:left;">
<input class="button_gen" onclick="restoreRule('restore');" type="button" value="<#1692#>" name="action1" />
</div>
<div id="restoreInit_div">
<div style="float:left;margin-left:5px;">
<input type="checkbox" id="restoreInit">
</div>
<div style="float:left;width:65%;">
<span><label for="restoreInit"><#3185#></label></span>
</div>
</div>
<input type="hidden" name="wl_gmode_protection_x" value="<% nvram_get("wl_gmode_protection_x"); %>" />
</td>
</tr>
<tr>
<th align="right" style="border-bottom:none">
<a class="hintstyle" href="javascript:void(0);" onclick="openHint(19,2)"><#3187#></a>
</th>
<td>
<div style="float:left;display:table-cell">
<input class="button_gen" onclick="saveSetting('Router');" type="button" value="<#3187#>" name="action2" />
</div>
<div style="display:table-cell">
<div id="remove_passwd_field" style="display:table-row">
<div style="float:left;margin-left:5px;">
<input id="remove_passwd" type="checkbox">
</div>
<div style="float:left;width:80%;">
<span><label for="remove_passwd"><#3192#></span></label>
</div>
</div>
<div id="transfer_ddns_field" style="display:table-row">
<div style="float:left;margin-left:5px;">
<input id="transfer_ddns" type="checkbox">
</div>
<div style="float:left;width:80%;">
<span><label for="transfer_ddns"><#1726#></span></label>
</div>
</div>
</div>
</td>
</tr>
<tr>
<th align="right">
<a class="hintstyle" href="javascript:void(0);" onclick="openHint(19,3)"><#3191#></a>
</th>
<td colspan = "4">
<div style="margin-left:-10px;">
<table>
<tr>
<td style="border:0px">
<input type="button" class="button_gen" onclick="selectSetting();" value="<#1697#>"/>
</td>
<td style="display:none;">
<input type="file" name="file" class="input" style="color:#FFCC00;"/>
</td>
</tr>
</table>
</div>
</td>
</tr>
</table>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
</form>
<div id="footer"></div>
<form method="post" name="restoreform" action="apply.cgi" target="hidden_frame">
<input type="hidden" name="action_mode" value="Restore">
<input type="hidden" name="next_page" value="">
</form>
</body>
</html>

