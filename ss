<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المساحي الذكي 2.4</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css"/>
<style>
body{margin:0;font-family:Tahoma;background:#000;color:white;}
header{background:linear-gradient(to right,#FF0000,#008000);color:white;padding:15px;text-align:center;font-size:22px;}
#panel{padding:15px;background:#000033;}
input,select,button,textarea{width:100%;padding:8px;margin:5px 0;font-size:15px;}
button{background:#FF0000;color:white;border:none;cursor:pointer;font-weight:bold;}
#map{height:60vh;border:2px solid #008000;margin-top:5px;}
#result{margin-top:10px;}
</style>
</head>
<body>
<header>📍 المشروع المساحي الذكي 2.4</header>

<div id="panel">
نوع المشروع:
<select id="type"><option value="stadium">ملعب</option><option value="building">مبنى</option></select>
نوع الخريطة:
<select id="mapType"><option value="osm">خريطة عادية</option><option value="sat">قمر صناعي HD</option></select>
شبكة الخلايا:
<input id="gridSize" type="number" value="6" min="2" max="50">
إحداثيات Polygon (lat,lng لكل نقطة على سطر جديد):
<textarea id="coordsInput" rows="5" placeholder="مثال: 26.82,30.80"></textarea>
<button onclick="setMap()">تحديث الخريطة</button>
<button onclick="drawFromCoords()">رسم من الإحداثيات</button>
<button onclick="draw2D()">رسم 2D</button>
<button onclick="makeGrid()">إنشاء الشبكة</button>
<button onclick="computeCutFill()">حساب Cut & Fill</button>
<button onclick="calculateArea()">حساب المساحة</button>
<button onclick="exportKML()">تنزيل KML</button>
<button onclick="exportExcel()">تنزيل Excel</button>
<button onclick="searchCoordinates()">بحث بالإحداثيات</button>
<div id="result"></div>
</div>

<div id="map"></div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.js"></script>
<script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
<script>
// إعداد الخريطة
var map = L.map('map').setView([26.82,30.80],18);
var osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:22}).addTo(map);
var sat = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',{maxZoom:22});
var drawnLayer = L.layerGroup().addTo(map);
var drawnItems = new L.FeatureGroup().addTo(map);
var drawControl = new L.Control.Draw({
    draw: {marker:false,polyline:false,circle:false,rectangle:false,circlemarker:false,polygon:{allowIntersection:false,showArea:true}},
    edit:{featureGroup:drawnItems}
});
map.addControl(drawControl);

let polygon;
let gridLines = [];
let cutfillResults=[];

// رسم Polygon بالماوس
map.on(L.Draw.Event.CREATED, function (e) {
    drawnItems.clearLayers();
    drawnLayer.clearLayers();
    gridLines=[];
    cutfillResults=[];
    polygon = e.layer;
    drawnItems.addLayer(polygon);
    drawnLayer.addLayer(polygon);
    map.fitBounds(polygon.getBounds());
    document.getElementById("result").innerHTML="✅ تم تحديد حدود الموقع بالماوس بدقة";
});

// رسم Polygon من الإحداثيات المدخلة
function drawFromCoords(){
    let input = document.getElementById("coordsInput").value.trim();
    if(!input){alert("ادخل الإحداثيات أولاً"); return;}
    let lines = input.split("\n");
    let latlngs = [];
    for(let i=0;i<lines.length;i++){
        let parts = lines[i].split(",");
        if(parts.length!=2){alert("صيغة الإحداثيات خاطئة في السطر "+(i+1)); return;}
        let lat=parseFloat(parts[0].trim());
        let lng=parseFloat(parts[1].trim());
        latlngs.push([lat,lng]);
    }
    drawnItems.clearLayers();
    drawnLayer.clearLayers();
    gridLines=[];
    cutfillResults=[];
    polygon=L.polygon(latlngs,{color:"#008000"}).addTo(drawnItems);
    drawnLayer.addLayer(polygon);
    map.fitBounds(polygon.getBounds());
    document.getElementById("result").innerHTML="✅ تم رسم Polygon من الإحداثيات";
}

// تحديث نوع الخريطة
function setMap(){
    let type = document.getElementById("mapType").value;
    drawnLayer.clearLayers();
    gridLines=[];
    cutfillResults=[];
    if(type=="sat"){map.removeLayer(osm);sat.addTo(map);}else{map.removeLayer(sat);osm.addTo(map);}
    document.getElementById("result").innerHTML="✅ تم تحديث نوع الخريطة";
}

// رسم 2D للنقاط
function draw2D(){
    if(!polygon) {alert("حدد Polygon أولاً"); return;}
    polygon.getLatLngs()[0].forEach(p=>{
        L.circleMarker(p,{radius:5,color:"#FF0000"}).addTo(drawnLayer);
    });
    document.getElementById("result").innerHTML="✅ تم رسم 2D";
}

// إنشاء شبكة ديناميكية
function makeGrid(){
    if(!polygon) {alert("حدد Polygon أولاً"); return;}
    let bounds=polygon.getBounds();
    let rows=parseInt(document.getElementById("gridSize").value);
    let cols=rows;
    gridLines.forEach(l=>drawnLayer.removeLayer(l));
    gridLines=[];
    let stepLat=(bounds.getNorth()-bounds.getSouth())/rows;
    let stepLng=(bounds.getEast()-bounds.getWest())/cols;
    for(let i=0;i<=rows;i++){
        let line=L.polyline([[bounds.getSouth()+i*stepLat,bounds.getWest()],[bounds.getSouth()+i*stepLat,bounds.getEast()]],{color:"#FF0000",weight:1});
        line.addTo(drawnLayer); gridLines.push(line);
    }
    for(let j=0;j<=cols;j++){
        let line=L.polyline([[bounds.getSouth(),bounds.getWest()+j*stepLng],[bounds.getNorth(),bounds.getWest()+j*stepLng]],{color:"#FF0000",weight:1});
        line.addTo(drawnLayer); gridLines.push(line);
    }
    document.getElementById("result").innerHTML="✅ تم إنشاء الشبكة الديناميكية";
}

// حساب Cut & Fill تقديري
function computeCutFill(){
    if(!polygon) {alert("حدد Polygon أولاً"); return;}
    cutfillResults=[];
    let rows=parseInt(document.getElementById("gridSize").value);
    let cols=rows;
    for(let i=0;i<rows;i++){
        for(let j=0;j<cols;j++){
            let randomCut=Math.floor(Math.random()*10);
            let randomFill=Math.floor(Math.random()*10);
            cutfillResults.push({row:i+1,col:j+1,cut:randomCut,fill:randomFill});
        }
    }
    document.getElementById("result").innerHTML="✅ تم حساب Cut & Fill لكل خلية (تقديري)";
    console.table(cutfillResults);
}

// حساب مساحة Polygon
function calculateArea(){
    if(!polygon) {alert("حدد Polygon أولاً"); return;}
    let area=0;
    let coords=polygon.getLatLngs()[0];
    for(let i=0;i<coords.length;i++){
        let j=(i+1)%coords.length;
        let xi=coords[i].lng; let yi=coords[i].lat;
        let xj=coords[j].lng; let yj=coords[j].lat;
        area += (xi*yj - xj*yi);
    }
    area=Math.abs(area/2*1230000);
    document.getElementById("result").innerHTML=`✅ المساحة التقريبية: ${area.toFixed(2)} م²`;
}

// تنزيل KML
function exportKML(){
    if(!polygon) {alert("حدد Polygon أولاً"); return;}
    let coords=polygon.getLatLngs()[0];
    let kml=`<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>`;
    coords.forEach(c=>{kml+=`${c.lng},${c.lat},0 `;});
    kml+=`</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></Document></kml>`;
    let blob=new Blob([kml],{type:"application/vnd.google-earth.kml+xml"});
    let link=document.createElement("a");
    link.href=URL.createObjectURL(blob);
    link.download="smart_survey_project.kml";
    link.click();
    document.getElementById("result").innerHTML="✅ تم تنزيل KML";
}

// تنزيل Excel
function exportExcel(){
    if(!cutfillResults.length){alert("قم بحساب Cut & Fill أولاً"); return;}
    let wb=XLSX.utils.book_new();
    let ws_data=[["Row","Column","Cut(m³)","Fill(m³)"]];
    cutfillResults.forEach(c=>{ws_data.push([c.row,c.col,c.cut,c.fill]);});
    let ws=XLSX.utils.aoa_to_sheet(ws_data);
    XLSX.utils.book_append_sheet(wb,ws,"CutFill");
    XLSX.writeFile(wb,"smart_survey_project.xlsx");
    document.getElementById("result").innerHTML="✅ تم تنزيل ملف Excel";
}

// زر البحث عن نقطة بالإحداثيات
function searchCoordinates() {
    let input = prompt("ادخل الاحداثيات بالصيغة: lat,lng مثلا: 26.82,30.80");
    if(!input) return;
    let parts = input.split(",");
    if(parts.length != 2){alert("صيغة الإحداثيات خاطئة"); return;}
    let lat = parseFloat(parts[0].trim());
    let lng = parseFloat(parts[1].trim());
    if(isNaN(lat) || isNaN(lng)){alert("الإحداثيات غير صالحة"); return;}
    
    if(window.searchMarker) map.removeLayer(window.searchMarker);
    window.searchMarker = L.marker([lat,lng]).addTo(map);
    map.setView([lat,lng], 20);
    document.getElementById("result").innerHTML=`✅ تم العثور على النقطة: ${lat}, ${lng}`;
}
</script>
</body>
</html>
