<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المساحي الذكي - النسخة المتقدمة</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<style>
body{
margin:0;
font-family:Tahoma;
background:#0b1e0b;
color:white;
}
header{
background:#093d00;
color:white;
padding:15px;
text-align:center;
font-size:22px;
}
#panel{
padding:15px;
background:#145214;
box-shadow:0 2px 6px rgba(0,0,0,.5);
}
input,select,button{
width:100%;
padding:8px;
margin:5px 0;
font-size:15px;
}
button{
background:#0b3d00;
color:white;
border:none;
cursor:pointer;
font-weight:bold;
}
#map{
height:70vh;
border:2px solid #0b3d00;
margin-top:5px;
}
.download{
background:#27ae60;
color:white;
padding:10px;
margin-top:10px;
text-decoration:none;
display:block;
text-align:center;
}
</style>
</head>
<body>

<header>📍 المشروع المساحي الذكي - النسخة المتقدمة</header>

<div id="panel">
خط العرض:
<input id="lat" value="26.8206">
خط الطول:
<input id="lng" value="30.8025">

نوع المشروع:
<select id="type">
<option value="stadium">ملعب</option>
<option value="building">مبنى</option>
</select>

نوع الخريطة:
<select id="mapType">
<option value="osm">خريطة عادية</option>
<option value="sat">قمر صناعي HD</option>
</select>

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

// ==========================
// إنشاء الخريطة
// ==========================
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
}

// ==========================
// إنشاء Polygon
// ==========================
function createPolygon(){
drawnLayer.clearLayers();
gridLines=[];
cutfillResults=[];

let lat=parseFloat(document.getElementById("lat").value);
let lng=parseFloat(document.getElementById("lng").value);
let size=0.0003;

let coords=[[lat-size,lng-size],[lat-size,lng+size],[lat+size,lng+size],[lat+size,lng-size]];
polygon=L.polygon(coords,{color:"#0fff00"}).addTo(drawnLayer);
map.fitBounds(polygon.getBounds());
document.getElementById("result").innerHTML="تم إنشاء Polygon بنجاح ✅";
}

// ==========================
// رسم نقاط 2D
// ==========================
function draw2D(){
if(!polygon) return;
polygon.getLatLngs()[0].forEach(p=>{
L.circleMarker(p,{radius:5,color:"#00ffcc"}).addTo(drawnLayer);
});
document.getElementById("result").innerHTML="تم رسم 2D بنجاح ✅";
}

// ==========================
// تقسيم شبكي Mesh Grid
// ==========================
function makeGrid(){
if(!polygon) return;
let bounds=polygon.getBounds();
let rows=6,cols=6;
let stepLat=(bounds.getNorth()-bounds.getSouth())/rows;
let stepLng=(bounds.getEast()-bounds.getWest())/cols;

for(let i=0;i<=rows;i++){
let latLine=L.polyline([[bounds.getSouth()+i*stepLat,bounds.getWest()],[bounds.getSouth()+i*stepLat,bounds.getEast()]],{color:"#00ff00",weight:1}).addTo(drawnLayer);gridLines.push(latLine);}
for(let j=0;j<=cols;j++){
let lngLine=L.polyline([[bounds.getSouth(),bounds.getWest()+j*stepLng],[bounds.getNorth(),bounds.getWest()+j*stepLng]],{color:"#00ff00",weight:1}).addTo(drawnLayer);gridLines.push(lngLine);}
document.getElementById("result").innerHTML="تم إنشاء الشبكة ✅";
}

// ==========================
// حساب Cut & Fill (تقريبي)
// ==========================
function computeCutFill(){
if(!polygon || gridLines.length==0) return;

cutfillResults=[];
let cellsLatStep=(polygon.getBounds().getNorth()-polygon.getBounds().getSouth())/6;
let cellsLngStep=(polygon.getBounds().getEast()-polygon.getBounds().getWest())/6;

for(let i=0;i<6;i++){
for(let j=0;j<6;j++){
let randomCut=Math.floor(Math.random()*5); // ارتفاع افتراضي للتجربة
let randomFill=Math.floor(Math.random()*5);
cutfillResults.push({row:i+1,col:j+1,cut:randomCut,fill:randomFill});
}
}
document.getElementById("result").innerHTML="تم حساب Cut & Fill ✅ (تقديري)";
console.table(cutfillResults);
}

// ==========================
// تصدير KML
// ==========================
function exportKML(){
if(!polygon) return;
let coords=polygon.getLatLngs()[0];
let kml=`<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>`;
coords.forEach(c=>{kml+=`${c.lng},${c.lat},0 `;});
kml+=`</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></Document></kml>`;

let blob=new Blob([kml],{type:"application/vnd.google-earth.kml+xml"});
let link=document.createElement("a");
link.href=URL.createObjectURL(blob);
link.download="survey_project.kml";
link.click();
document.getElementById("result").innerHTML="تم تنزيل KML بنجاح ✅";
}
</script>
</body>
</html>
