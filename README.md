<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>Smart Survey Project</title>

<link rel="stylesheet"
href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/xlsx/dist/xlsx.full.min.js"></script>

<style>
body{
font-family:Tahoma;
margin:0;
background:#eef3f7;
direction:rtl;
}
header{
background:#0b3d91;
color:white;
padding:15px;
text-align:center;
font-size:22px;
}
.panel{
max-width:900px;
margin:auto;
padding:15px;
}
input,button{
width:100%;
padding:10px;
margin:6px 0;
font-size:15px;
}
button{
background:#0b3d91;
color:white;
border:none;
cursor:pointer;
}
#map{
height:520px;
border:2px solid #333;
}
.download{
display:none;
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

<header>المشروع المساحي الذكي</header>

<div class="panel">

<input id="lat" placeholder="Latitude مثال 26.1648">
<input id="lng" placeholder="Longitude مثال 32.7168">
<input id="area" type="number" placeholder="Area (m²)">
<input id="grid" type="number" value="6" placeholder="Grid Count">

<button onclick="runProject()">إنشاء المشروع</button>

<div id="map"></div>

<a id="excelBtn" class="download" download="survey.xlsx">تحميل Excel</a>
<a id="kmlBtn" class="download" download="survey.kml">تحميل KML (Google Earth)</a>

</div>

<script>

/* ===== MAP ===== */

let map=L.map('map').setView([26.16,32.71],15);

const osm=L.tileLayer(
'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
{maxZoom:19}).addTo(map);

const satellite=L.tileLayer(
'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
{maxZoom:19});

L.control.layers({"خريطة":osm,"قمر صناعي":satellite}).addTo(map);

let layers=[];

function clearLayers(){
layers.forEach(l=>map.removeLayer(l));
layers=[];
}

/* ===== MAIN ===== */

function runProject(){

clearLayers();

/* قراءة القيم */
const lat=parseFloat(document.getElementById("lat").value);
const lng=parseFloat(document.getElementById("lng").value);
const area=parseFloat(document.getElementById("area").value);
const grid=parseInt(document.getElementById("grid").value);

if(isNaN(lat)||isNaN(lng)||isNaN(area)){
alert("ادخل البيانات بشكل صحيح");
return;
}

map.setView([lat,lng],18);

/* boundary */
const side=Math.sqrt(area)/111000;

const bounds=[
[lat-side/2,lng-side/2],
[lat-side/2,lng+side/2],
[lat+side/2,lng+side/2],
[lat+side/2,lng-side/2]
];

let boundary=L.polygon(bounds,{color:"red"}).addTo(map);
layers.push(boundary);

/* traverse */
let traverse=L.polyline([...bounds,bounds[0]],{color:"blue"}).addTo(map);
layers.push(traverse);

/* grid */
const latStep=(bounds[2][0]-bounds[0][0])/grid;
const lngStep=(bounds[2][1]-bounds[0][1])/grid;

let data=[];
let kml='<?xml version="1.0"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document>';

for(let i=0;i<grid;i++){
for(let j=0;j<grid;j++){

const rect=[
[bounds[0][0]+i*latStep,bounds[0][1]+j*lngStep],
[bounds[0][0]+(i+1)*latStep,bounds[0][1]+j*lngStep],
[bounds[0][0]+(i+1)*latStep,bounds[0][1]+(j+1)*lngStep],
[bounds[0][0]+i*latStep,bounds[0][1]+(j+1)*lngStep]
];

let cell=L.polygon(rect,{
color:"green",
weight:1,
fillOpacity:0.1}).addTo(map);

layers.push(cell);

/* terrain model */
let x=i/grid;
let y=j/grid;

let existing=
100+2*x+1.5*y+
Math.sin(x*3)*0.6+
Math.cos(y*3)*0.6;

let design=102;

let cut=Math.max(existing-design,0);
let fill=Math.max(design-existing,0);

data.push({
cell:`${i}-${j}`,
existing:existing.toFixed(2),
design,
cut:cut.toFixed(2),
fill:fill.toFixed(2)
});

/* KML */
kml+=`<Placemark><Polygon><outerBoundaryIs>
<LinearRing><coordinates>
${rect.map(p=>`${p[1]},${p[0]},0`).join(" ")}
${rect[0][1]},${rect[0][0]},0
</coordinates></LinearRing>
</outerBoundaryIs></Polygon></Placemark>`;
}
}

kml+='</Document></kml>';

/* Excel */
const ws=XLSX.utils.json_to_sheet(data);
const wb=XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb,ws,"Survey");

const wbout=XLSX.write(wb,{bookType:'xlsx',type:'array'});

document.getElementById("excelBtn").href=
URL.createObjectURL(new Blob([wbout]));
document.getElementById("excelBtn").style.display="block";

/* KML */
document.getElementById("kmlBtn").href=
URL.createObjectURL(new Blob([kml],
{type:"application/vnd.google-earth.kml+xml"}));
document.getElementById("kmlBtn").style.display="block";

}

</script>
</body>
</html>
