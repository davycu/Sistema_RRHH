function renderPermisosChart(data) {
    var ctx = document.getElementById('lineChartPermisos').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
            datasets: [{
                label: 'Solicitudes',
                data: data.map(function (x) { return x.Cantidad; }),
                borderColor: 'lightgray',
                borderWidth: 2,
                //backgroundColor: 'lightblue',
                tension: 0.3,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: { y: { beginAtZero: true, ticks: { stepSize: 5 } } }
        }
    });
}

function loadPermisosChart(json) {
    var data = JSON.parse(json);
    renderPermisosChart(data);
}

//grafico genero
function renderGeneroPie(data) {
    var width = 400,
        height = 400,
        radius = Math.min(width, height) / 2;

    //Elimina contenido previo en el SVG
    d3.select("#svgPieGenero").selectAll("*").remove();

    //Crear el SVG y centrar el grupo principal
    var svg = d3.select("#svgPieGenero")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    //Escala de color: pastel rosa para femenino y pastel azul para masculino
    var color = d3.scale.ordinal()
        .domain(["femenino", "masculino"])
        .range(["#F8BBD0", "#B3E5FC"]);

    //Configurar el layout de pie
    var pie = d3.layout.pie()
        .value(function (d) { return d.cantidad; })
        .sort(null);

    //Generador de arcos
    var arc = d3.svg.arc()
        .outerRadius(radius - 10)
        .innerRadius(0);

    //Generar los segmentos del pie
    var g = svg.selectAll(".arc")
        .data(pie(data))
        .enter().append("g")
        .attr("class", "arc");

    //Dibujar cada segmento con transición
    g.append("path")
        .attr("d", arc)
        .style("fill", function (d) { return color(d.data.genero); })
        .style("stroke", "#ffffff")
        .style("stroke-width", "1px")
        .transition()
        .duration(1000)
        .attrTween("d", function (d) {
            var interpolate = d3.interpolate({ startAngle: 0, endAngle: 0 }, d);
            return function (t) { return arc(interpolate(t)); };
        });

    //Calcular el total de empleados a partir de la data
    var totalEmpleados = d3.sum(data, function (d) { return +d.cantidad; });

    //Agregar etiquetas a cada segmento, mostrando número y porcentaje
    g.append("text")
        .attr("transform", function (d) { return "translate(" + arc.centroid(d) + ")"; })
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .style("font-size", "18px")
        .style("fill", "#333")
        .text(function (d) {
            var porcentaje = (d.data.cantidad / totalEmpleados) * 100;
            //Redondear el porcentaje a 1 decimal
            porcentaje = Math.round(porcentaje * 10) / 10;
            // mostrar: Femenino
            return d.data.genero.charAt(0).toUpperCase() + d.data.genero.slice(1) + ": " + d.data.cantidad + " (" + porcentaje + "%)";
        });
}
function cargarGeneroChart() {
    $.ajax({
        type: "POST",
        url: "Dashboard.aspx/GetEmpleadosPorGeneroJSON",
        data: '{}',
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (response) {
            var data = JSON.parse(response.d);
            //Guarda la data en una variable global si es necesario
            window.generoData = data;
            renderGeneroPie(data);
        },
        error: function (err) {
            console.log("Error:", err);
        }
    });
}

//Llamar a la función al cambiar algún filtro
$(document).ready(function () {
    cargarGeneroChart();
});

