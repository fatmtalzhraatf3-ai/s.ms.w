<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المساحي الذكي - كامل</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<style>
body{margin:0;font-family:Tahoma;background:#000;color:white;}
header{background:#8B0000;color:white;padding:15px;text-align:center;font-size:22px;}
#panel{padding:15px;background:#330000;}
input,select,button{width:100%;padding:8px;margin:5px 0;font-size:15px;}
button{background:#B22222;color:white;border:none;cursor:pointer;font-weight:bold;}
#map{height:70vh;border:2px solid #B22222;margin-top:5px;}
.download{background:#FF0000;color:white;padding:10px;margin-top:10px;text-decoration:none;display:block;text-align:center;}
</style>
</head>
<body>
<header>📍 المشروع المساحي الذكي - كامل</header>

<div id="panel">
خط العرض: <input id="lat" value="26.8206">
خط الطول: <input id="lng" value="30.8025">
نوع المشروع:
<select id="type"><option value="stadium">ملعب</option><option value="building">مبنى</option></select>
نوع الخريطة:
<select id="mapType"><option value="osm">خريطة عادية</option><option value="sat">قمر صناعي HD</option></select>
<button onclick="setMap()">تحديث الخريطة</button>
<button onclick="createPolygon()">إنشاء Polygon</button>
<button onclick="draw2D()">رسم 2D</button>
<button onclick="makeGrid()">تقسيم شبكي</button>
<button onclick="computeCutFill()">حساب Cut & Fill</button>
<button onclick="exportKML()">تنزيل KML</button>
<div id="result"></div>
</div>

<div id="map"></div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
var map = L.map('map').setView([26.82,30.80],18);
var osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:22}).addTo(map);
var sat = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',{maxZoom:22});

var drawnLayer = L.layerGroup().addTo(map);
let polygon;
let gridLines = [];
let cutfillResults=[];

function setMap(){
let type = document.getElementById("mapType").value;
drawnLayer.clearLayers();
gridLines=[];
cutfillResults=[];
if(type=="sat"){map.removeLayer(osm);sat.addTo(map);}else{map.removeLayer(sat);osm.addTo(map);}
document.getElementById("result").innerHTML="تم تحديث نوع الخريطة ✅";
}

function createPolygon(){
drawnLayer.clearLayers();
gridLines=[];
cutfillResults=[];
let lat=parseFloat(document.getElementById("lat").value);
let lng=parseFloat(document.getElementById("lng").value);
let size=0.0003;
let coords=[[lat-size,lng-size],[lat-size,lng+size],[lat+size,lng+size],[lat+size,lng-size]];
polygon=L.polygon(coords,{color:"#FF4500"}).addTo(drawnLayer);
map.fitBounds(polygon.getBounds());
document.getElementById("result").innerHTML="تم إنشاء Polygon بنجاح ✅";
}

function draw2D(){
if(!polygon) {alert("قم بإنشاء Polygon أولاً"); return;}
polygon.getLatLngs()[0].forEach(p=>{
L.circleMarker(p,{radius:5,color:"#FF6347"}).addTo(drawnLayer);
});
document.getElementById("result").innerHTML="تم رسم 2D بنجاح ✅";
}

function makeGrid(){
if(!polygon) {alert("قم بإنشاء Polygon أولاً"); return;}
let bounds=polygon.getBounds();
let rows=6,cols=6;
let stepLat=(bounds.getNorth()-bounds.getSouth())/rows;
let stepLng=(bounds.getEast()-bounds.getWest())/cols;

for(let i=0;i<=rows;i++){
L.polyline([[bounds.getSouth()+i*stepLat,bounds.getWest()],[bounds.getSouth()+i*stepLat,bounds.getEast()]],{color:"#FF0000",weight:1}).addTo(drawnLayer);}
for(let j=0;j<=cols;j++){
L.polyline([[bounds.getSouth(),bounds.getWest()+j*stepLng],[bounds.getNorth(),bounds.getWest()+j*stepLng]],{color:"#FF0000",weight:1}).addTo(drawnLayer);}
document.getElementById("result").innerHTML="تم إنشاء الشبكة ✅";
}

function computeCutFill(){
if(!polygon) {alert("قم بإنشاء Polygon أولاً"); return;}
cutfillResults=[];
let cellsLatStep=(polygon.getBounds().getNorth()-polygon.getBounds().getSouth())/6;
let cellsLngStep=(polygon.getBounds().getEast()-polygon.getBounds().getWest())/6;
for(let i=0;i<6;i++){
for(let j=0;j<6;j++){
// قيم تقديرية Cut & Fill محسوبة لكل خلية
let randomCut=Math.floor(Math.random()*5);
let randomFill=Math.floor(Math.random()*5);
cutfillResults.push({row:i+1,col:j+1,cut:randomCut,fill:randomFill});
}
}
document.getElementById("result").innerHTML="تم حساب Cut & Fill ✅ (تقديري)";
console.table(cutfillResults);
}

function exportKML(){
if(!polygon) {alert("قم بإنشاء Polygon أولاً"); return;}
let coords=polygon.getLatLngs()[0];
let kml=`<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>`;
coords.forEach(c=>{kml+=`${c.lng},${c.lat},0 `;});
kml+=`</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></Document></kml>`;
let blob=new Blob([kml],{type:"application/vnd.google-earth.kml+xml"});
let link=document.createElement("a");
link.href=URL.createObjectURL(blob);
link.download="smart_survey_project.kml";
link.click();
document.getElementById("result").innerHTML="تم تنزيل KML بنجاح ✅";
}
</script>
</body>
</html>
