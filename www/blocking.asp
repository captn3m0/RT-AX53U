﻿<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title><#837#> - Blocking Page</title>
<script type="text/JavaScript" src="/js/jquery.js"></script>
<style>
body{
color:#FFF;
font-family: Arial;
}
.wrapper{
background:url(images/New_ui/login_bg.png) #1F1F1F no-repeat;
background-size: 1280px 1076px;
background-position: center 0%;
margin: 0px;
}
.title_name {
font-size: 32px;
color:#93D2D9;
}
.title_text{
width:520px;
}
.prod_madelName{
font-size: 26px;
color:#fff;
margin-left:78px;
margin-top: 10px;
}
.login_img{
width:43px;
height:43px;
background-image: url('images/New_ui/icon_titleName.png');
background-repeat: no-repeat;
}
.p1{
font-size: 16px;
color:#fff;
width: 480px;
}
.button{
background-color:#279FD9;
/*background:rgba(255,255,255,0.1);
border: solid 1px #6e8385;*/
border-radius: 4px ;
transition: visibility 0s linear 0.218s,opacity 0.218s,background-color 0.218s;
height: 68px;
width: 300px;
font-size: 28px;
color:#fff;
color:#000\9; /* IE6 IE7 IE8 */
text-align: center;
float:right;
margin:25px 0 0 78px;
line-height:68px;
}
.form_input{
background-color:rgba(255,255,255,0.2);
border-radius: 4px;
padding:26px 22px;
width: 480px;
border: 0;
height:25px;
color:#fff;
color:#000\9; /* IE6 IE7 IE8 */
font-size:28px
}
.nologin{
margin:10px 0px 0px 78px;
background-color:rgba(255,255,255,0.2);
padding:20px;
line-height:36px;
border-radius: 5px;
width: 600px;
border: 0;
color:#fff;
color:#000\9; /* IE6 IE7 IE8 */
font-size: 18px;
}
.div_table{
display:table;
}
.div_tr{
display:table-row;
}
.div_td{
display:table-cell;
}
.title_gap{
margin:10px 0px 0px 78px;
}
.img_gap{
padding-right:30px;
vertical-align:middle;
}
.password_gap{
margin:30px 0px 0px 78px;
}
.error_hint{
color: rgb(255, 204, 0);
margin:10px 0px -10px 78px;
font-size: 18px;
font-weight: bolder;
}
.main_field_gap{
margin:100px auto 0;
}
ul{
margin: 0;
}
li{
margin: 10px 0;
}
#wanLink{
cursor: pointer;
}
.button_background{
background-color: transparent;
}
.tm_logo{
background:url('images/New_ui/tm_logo_1.png') no-repeat;
width:487px;
height:90px;
background-size: 80%;
margin-left: -20px;
}
.desc_info{
font-weight:bold;
}
#tm_block{
margin: 0 20px;
}
a{
color: #FC0;
}
/*for mobile device*/
@media screen and (max-width: 1000px){
.title_name {
font-size: 1.2em;
color:#93d2d9;
margin-left:15px;
}
.prod_madelName{
font-size: 1.2em;
margin-left: 15px;
}
.p1{
font-size: 16px;
width:100%;
}
.login_img{
background-size: 75%;
}
.title_text{
width: 100%;
}
.form_input{
padding:13px 11px;
width: 100%;
height:25px;
font-size:16px
}
.button{
height: 50px;
width: 100%;
font-size: 16px;
text-align: center;
float:right;
margin: 25px -30px 0 0;
line-height:50px;
padding: 0 10px;
}
.nologin{
margin-left:10px;
padding:5px;
line-height:18px;
width: 100%;
font-size:14px;
}
.error_hint{
margin-left:10px;
}
.main_field_gap{
width:80%;
margin:30px 0 0 15px;
/*margin:30px auto 0;*/
}
.title_gap{
margin-left:15px;
}
.password_gap{
margin-left:15px;
}
.img_gap{
padding-right:0;
vertical-align:middle;
}
ul{
margin-left:-20px;
}
li{
margin: 10px 0;
}
.tm_logo{
width: 400px;
background-repeat: no-repeat;
background-size: 100%;
}
}
</style>
<script type="text/javascript">
var isRouterMode = ('<% nvram_get("sw_mode"); %>' == '1') ? true : false;
var header_info = [<% get_header_info(); %>][0];
var ROUTERHOSTNAME = '<% nvram_get("local_domain"); %>';
var domainNameUrl = header_info.protocol+"://"+ROUTERHOSTNAME+":"+header_info.port;
var chdom = function(){window.location.href=domainNameUrl+"/blocking.asp"+window.location.search};
(function(){
if(ROUTERHOSTNAME !== header_info.host && ROUTERHOSTNAME != "" && isRouterMode){
setTimeout(function(){
var s=document.createElement("script");s.type="text/javascript";s.src=domainNameUrl+"/chdom.json?hostname="+header_info.host;var h=document.getElementsByTagName("script")[0];h.parentNode.insertBefore(s,h);
}, 1);
}
})();
var bwdpi_support = ('<% nvram_get("rc_support"); %>'.search('bwdpi') == -1) ? false : true;
var casenum = '<% get_parameter("cat_id"); %>';
var flag = '<% get_parameter("flag"); %>';
var block_info = '<% bwdpi_redirect_info(); %>';
if(block_info != "")
block_info = JSON.parse(block_info);
var category_info = [ ["Parental Controls", "1", "<#1201#>", "<#1203#>", "<#1434#>"],
["Parental Controls", "3", "<#1201#>", "<#1203#>", "<#1436#>"],
["Parental Controls", "4", "<#1201#>", "<#1203#>", "<#1437#>"],
["Parental Controls", "5", "<#1201#>", "<#1203#>", "<#1438#>"],
["Parental Controls", "6", "<#1201#>", "<#1203#>", "<#1439#>"],
["Parental Controls", "8", "<#1201#>", "<#1203#>", "<#1440#>"],
["Parental Controls", "9", "<#1201#>", "<#1204#>", "<#1441#>"],
["Parental Controls", "10", "<#1201#>", "<#1204#>", "<#1442#>"],
["Parental Controls", "14", "<#1201#>", "<#1204#>", "<#1443#>"],
["Parental Controls", "15", "<#1201#>", "<#1204#>", "<#1444#>"],
["Parental Controls", "16", "<#1201#>", "<#1204#>", "<#1445#>"],
["Parental Controls", "25", "<#1201#>", "<#1204#>", "<#1446#>"],
["Parental Controls", "26", "<#1201#>", "<#1204#>", "<#1447#>"],
["Parental Controls", "11", "<#1201#>", "<#1205#>", "<#1448#>"],
["Parental Controls", "24", "<#1216#>", "<#1206#>", "<#1449#>"],
["Parental Controls", "51", "<#1216#>", "<#1207#>", "<#1450#>"],
["Parental Controls", "53", "<#1216#>", "<#1208#>", "<#1451#>"],
["Parental Controls", "89", "<#1216#>", "<#1208#>", "<#1452#>"],
["Parental Controls", "42", "<#1216#>", "<#1209#>", "<#1453#>"],
["Parental Controls", "56", "<#1219#>", "<#1221#>", "<#1454#>"],
["Parental Controls", "70", "<#1219#>", "<#1221#>", "<#1455#>"],
["Parental Controls", "71", "<#1219#>", "<#1221#>", "<#1456#>"],
["Parental Controls", "57", "<#1219#>", "<#1222#>", "<#1457#>"],
["Parental Controls", "69", "<#1223#>", "<#1225#>", "<#1458#>"],
["Parental Controls", "23", "<#1223#>", "<#1226#>", "<#1459#>"],
["Home Protection", "91", "Anti-Trojan detecting and blocked", "", "<#1460#>"],
["Home Protection", "2", "Malicious site blocked", "", "<#1435#>"],
["Home Protection", "39", "Malicious site blocked", "", "<#1461#>"],
["Home Protection", "73", "Malicious site blocked", "", "<#1462#>"],
["Home Protection", "74", "Malicious site blocked", "", "<#1463#>"],
["Home Protection", "75", "Malicious site blocked", "", "<#1464#>"],
["Home Protection", "76", "Malicious site blocked", "", "<#1465#>"],
["Home Protection", "77", "Malicious site blocked", "", "<#1466#>"],
["Home Protection", "78", "Malicious site blocked", "", "<#1467#>"],
["Home Protection", "79", "Malicious site blocked", "", "<#1468#>"],
["Home Protection", "80", "Malicious site blocked", "", "<#1469#>"],
["Home Protection", "81", "Malicious site blocked", "", "<#1470#>"],
["Home Protection", "82", "Malicious site blocked", "", "<#1471#>"],
["Home Protection", "83", "Malicious site blocked", "", "<#1472#>"],
["Home Protection", "84", "Malicious site blocked", "", "<#1473#>"],
["Home Protection", "85", "Malicious site blocked", "", "<#1474#>"],
["Home Protection", "86", "Malicious site blocked", "", "<#1475#>"],
["Home Protection", "88", "Malicious site blocked", "", "<#1476#>"],
["Home Protection", "92", "Malicious site blocked", "", "<#1477#>"],
["Home Protection", "94", "Malicious site blocked", "", "<#1478#>"],
["Home Protection", "95", "Malicious site blocked", "", "<#1479#>"]
];
var target_info = {
url: "",
category_id: "",
category_type: "",
content_category: "",
desc: ""
}
function initial(){
get_target_info();
show_information();
}
function get_target_info(){
if(casenum != ""){ //for AiProtection
target_info.url = block_info[1];
target_info.category_id = block_info[2];
get_category_info();
}
else{ //for Parental Controls (Time Scheduling)
target_info.desc = "<#1490#>";
}
}
function get_category_info(){
var cat_id = target_info.category_id;
var category_string = "";
for(i=0;i< category_info.length;i++){
if(category_info[i][1] == cat_id){
category_string = category_info[i][2];
if(category_info[i][3] != ""){
category_string += " - " + category_info[i][3];
}
target_info.category_type = category_info[i][0];
target_info.content_category = category_string;
target_info.desc = category_info[i][4];
}
}
}
function show_information(){
var code = "";
var code_suggestion = "";
var code_title = "";
var parental_string = "";
code = "<ul>";
code += "<li><div><span class='desc_info'><#1700#>:</span><br>" + target_info.desc + "</div></li>";
if(casenum != "")
code += "<li><div><span class='desc_info'>URL: </span>" + target_info.url +"</div></li>";
if(target_info.category_type == "Parental Controls")
code += "<li><div><span class='desc_info'><#1211#> :</span>" + target_info.content_category + "</div></li>";
code += "</ul>";
document.getElementById('detail_info').innerHTML = code;
if(target_info.category_type == "Parental Controls"){ //Webs Apps filter
code_title = "<div class='er_title' style='height:auto;'><#1489#></div>";
code_suggestion = "<ul>";
code_suggestion += "<li><span><#1488#></span></li>";
code_suggestion += "<li><span><#1493#></span></li>";
code_suggestion += '<li><#1271#><a href="https://global.sitesafety.trendmicro.com/index.php" target="_blank"><#1272#></a></li>';
code_suggestion += "</ul>";
document.getElementById('tm_block').style.display = "none";
$("#go_btn").click(function(){
location.href = "AiProtection_WebProtector.asp";
});
document.getElementById('go_btn').style.display = "";
}
else if(target_info.category_type == "Home Protection"){
code_title = "<div class='er_title' style='height:auto;'><#1485#></div>";
code_suggestion = "<ul>";
code_suggestion += '<li>If you are not sure of this website, visit <a href="https://global.sitesafety.trendmicro.com/index.php" target="_blank">TrendMicro\'s Site Safety Center</a> for more information. You can check the safety level of a particular URL that might seem suspicious.</li>';
code_suggestion += "<li>If you trust this website, click <a id='goToSetup' style='text-decoration:underline;'>here</a> to unblock (administrator credential required)</li>";
code_suggestion += "</ul>";
document.getElementById('tm_block').style.display = "";
/*$("#go_btn").click(function(){
location.href = "AiProtection_HomeProtection.asp";
});
document.getElementById('go_btn').style.display = "";*/
}
else if(flag != ""){
code_title = "<div class='er_title' style='height:auto;'><#803#></div>";
document.getElementById('main_reason').innerHTML = "<#802#>";
code = "";
code += "<div><#813#></div>";
document.getElementById('detail_info').innerHTML = code;
code_suggestion = "<ul>";
code_suggestion += "<li><span><#814#></span></li>";
code_suggestion += "<li><span><#815#></span></li>";
code_suggestion += "</ul>";
$("#go_btn").click(function(){
location.href = "AdaptiveQoS_TrafficLimiter.asp";
});
document.getElementById('go_btn').style.display = "";
}
else{ //for Parental Control(Time Scheduling)
code_title = "<div class='er_title' style='height:auto;'><#1494#></div>"
code_suggestion = "<ul>";
if(bwdpi_support)
parental_string = "<#3245#>";
else
parental_string = "<#463#>";
code_suggestion += "<li><#1491#> "+ parental_string +" <#1492#></li>";
code_suggestion += "<li><#1493#></li>";
code_suggestion += "</ul>";
$("#go_btn").click(function(){
location.href = "ParentalControl.asp";
});
document.getElementById('go_btn').style.display = "";
document.getElementById('tm_block').style.display = "none";
}
document.getElementById('page_title').innerHTML = code_title;
document.getElementById('suggestion').innerHTML = code_suggestion;
$("#goToSetup").click(function(){
function setValue(key, value, days) {
document.cookie = key + '=' + value + '; expires=' +
(new Date(new Date().getTime() + ((days ? days : 14) * 86400000))).toUTCString() + '; path=/';
}
setValue("malware", target_info.url)
location.href = "/AiProtection_MaliciousSitesBlocking.asp"
})
}
</script>
</head>
<body class="wrapper" onload="initial();">
<div class="div_table main_field_gap">
<div class="title_name">
<div class="div_td img_gap">
<div class="login_img"></div>
</div>
<div id="page_title" class="div_td title_text"></div>
</div>
<div class="prod_madelName"><#838#></div>
<div id="main_reason" class="p1 title_gap"><#1481#></div>
<div ></div>
<div>
<div class="p1 title_gap"></div>
<div class="nologin">
<div id="detail_info"></div>
</div>
</div>
<div class="p1 title_gap"><#822#></div>
<div>
<div class="p1 title_gap"></div>
<div class="nologin">
<div id="case_content"></div>
<div id="suggestion"></div>
<div id="tm_block" style="display:none">
<!--div><#1484#></div-->
<div class="tm_logo"></div>
</div>
</div>
</div>
<div id="go_btn" class='button' style="display:none;"><#1511#></div>
</div>
</body>
</html>

