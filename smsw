<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المشروع المساحي الذكي GIS</title>

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
font-size:24px;
}
.panel{
padding:15px;
max-width:900px;
margin:auto;
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
a{
display:none;
background:#27ae60;
color:white;
padding:10px;
margin-top:8px;
text-decoration:none;
}
</style>
</head>

<body>

<header>المشروع المساحي الذكي — GIS Edition</header>

<div class="panel">

<input id="lat" placeholder="Latitude مثال 26.1648">
<input id="lng" placeholder="Longitude مثال 32.7168">
<input id="area" type="number" placeholder="Area m²">
<input id="grid" type="number" value="6" placeholder="Grid Size">

<button onclick="runProject()">إنشاء المشروع</button>

<div id="map"></div>

<a id="excelBtn" download="survey.xlsx">تحميل Excel</a>
<a id="kmlBtn" download="survey.kml">تحميل KML</a>

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

const lat=parseFloat(lat.value);
const lng=parseFloat(lng.value);
const area=parseFloat(area.value);
const grid=parseInt(grid.value);

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

let elevationGrid=[];
let data=[];

const baseHeight=100;
const contourInterval=0.5;

let kml='<?xml version="1.0"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document>';

for(let i=0;i<grid;i++){
elevationGrid[i]=[];

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
fillOpacity:0.05}).addTo(map);

layers.push(cell);

/* realistic DEM */
let x=i/grid;
let y=j/grid;

let terrain=
Math.sin(x*3*Math.PI)*0.8+
Math.cos(y*3*Math.PI)*0.6;

let existing=
baseHeight+2.5*x+1.8*y+terrain;

let design=baseHeight+2;

let cut=Math.max(existing-design,0);
let fill=Math.max(design-existing,0);

elevationGrid[i][j]=existing;

data.push({
cell:`${i}-${j}`,
existing:existing.toFixed(2),
design:design,
cut:cut.toFixed(2),
fill:fill.toFixed(2)
});

/* KML polygon */
kml+=`<Placemark><Polygon><outerBoundaryIs>
<LinearRing><coordinates>
${rect.map(p=>`${p[1]},${p[0]},0`).join(" ")}
${rect[0][1]},${rect[0][0]},0
</coordinates></LinearRing>
</outerBoundaryIs></Polygon></Placemark>`;
}
}

/* ===== CONTOUR ===== */

let minZ=999,maxZ=-999;

for(let i=0;i<grid;i++){
for(let j=0;j<grid;j++){
minZ=Math.min(minZ,elevationGrid[i][j]);
maxZ=Math.max(maxZ,elevationGrid[i][j]);
}
}

for(let level=Math.floor(minZ);
level<=maxZ;
level+=contourInterval){

let pts=[];

for(let i=0;i<grid;i++){
for(let j=0;j<grid;j++){

if(Math.abs(elevationGrid[i][j]-level)<0.2){

let latp=bounds[0][0]+i*latStep;
let lngp=bounds[0][1]+j*lngStep;

pts.push([latp,lngp]);
}
}
}

if(pts.length>2){
let contour=L.polyline(pts,{
color:"#8B4513",
weight:2}).addTo(map);

layers.push(contour);
}
}

kml+='</Document></kml>';

/* Excel */
const ws=XLSX.utils.json_to_sheet(data);
const wb=XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb,ws,"Survey");

const wbout=XLSX.write(wb,{bookType:'xlsx',type:'array'});

excelBtn.href=URL.createObjectURL(new Blob([wbout]));
excelBtn.style.display="inline-block";

/* KML */
kmlBtn.href=URL.createObjectURL(
new Blob([kml],{type:"application/vnd.google-earth.kml+xml"})
);
kmlBtn.style.display="inline-block";

}

</script>
</body>
</html>
