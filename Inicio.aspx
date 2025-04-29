<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="Inicio.aspx.cs" Inherits="Sistema_RRHH.InicioSupv" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

     <!-- Bienvenida al usuario -->
    <div class="container mt-5 text-center">
        <h2><asp:Literal ID="litNombreUsuario" runat="server"></asp:Literal></h2>
        <p class="lead">¡Esperamos que tengas un excelente día! Aquí puedes ver las últimas novedades y el clima actual.</p>
    </div>

    <!-- Banner de Anuncio -->
    <div class="container mt-3">
        <div class="mx-auto" style="max-width: auto;">
            <asp:Panel ID="panelAnuncio" runat="server" CssClass="alert alert-info text-center py-4 animate__animated animate__pulse" 
                Visible="false" Style="font-size: 1.60em; font-weight: bold;">
                <asp:Literal ID="litAnuncio" runat="server"></asp:Literal>
            </asp:Panel>
        </div>
    </div>

    <!-- Sección de Clima y Noticias -->
    <div class="container mt-4">
        <div class="row justify-content-center">
            
            <!-- Clima Actual -->
            <div class="col-md-5">
                <div class="card p-4 shadow text-center">
                    <h4>🌤 Clima Actual</h4>
                    <p id="clima">Cargando clima...</p>
                </div>
            </div>

            <!-- Noticias de la Empresa -->
            <div class="col-md-5">
                <div class="card p-4 shadow text-center">
                    <h4>📰 Noticias Recientes</h4>
                    <div class="news-container" style="max-height: 200px; overflow-y: auto;">
                        <ul id="noticias" class="list-unstyled">
                            <li>Cargando noticias...</li>
                        </ul>
                    </div>
                </div>
            </div>


        </div>
    </div>

    <!-- Accesos Rápidos -->
    <asp:Panel ID="panelAccesosRapidos" runat="server">
    <div class="container mt-5 text-center">
        <div class="row justify-content-center">
            <div class="col-md-3">
                <a href="AprobarPermiso.aspx" class="btn btn-primary w-100">✅ Aprobar Permiso</a>
            </div>
            <div class="col-md-3">
                <a href="EvaluarEmpleados.aspx" class="btn btn-success w-100">📊 Evaluar Personal</a>
            </div>
        </div>
    </div>
    </asp:Panel>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            cargarClima();
            cargarNoticias();
        });

        function cargarClima() {
            fetch("https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/Tegucigalpa?unitGroup=metric&key=N25C9R4GDZXQ3HKXBPWN5YNR4&contentType=json")
                .then(response => response.json())
                .then(data => {
                    let clima = data.currentConditions;
                    document.getElementById('clima').innerHTML =
                        `<h5>🌤 Clima en ${data.resolvedAddress}</h5>
                <p>🌡 ${clima.temp}°C - ${clima.conditions}</p>
                <p>💨 Viento: ${clima.windspeed} km/h</p>
                <p>💧 Humedad: ${clima.humidity}%</p>`;
                })
                .catch(error => {
                    console.error("Error al obtener el clima:", error);
                    document.getElementById('clima').innerHTML = '<p>No se pudo obtener el clima.</p>';
                });
        }

        function cargarNoticias() {
            let apiKey = "KJO8bfsbFpV4b62Hi0wmb6MnZHRhWw4KacUbGdBJ"; //Usar API Key
            let url = `https://api.thenewsapi.com/v1/news/all?api_token=${apiKey}&categories=business,tech&language=es&limit=3`;

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    let listaNoticias = document.getElementById("noticias");
                    listaNoticias.innerHTML = ""; //Limpiar antes de agregar nuevas

                    data.data.forEach(noticia => {
                        let li = document.createElement("li");
                        li.innerHTML = `<a href="${noticia.url}" target="_blank">${noticia.title}</a>`;
                        listaNoticias.appendChild(li);
                    });
                })
                .catch(error => {
                    document.getElementById("noticias").innerHTML = "<li>No se pudieron cargar noticias.</li>";
                });
        }
    </script>

</asp:Content>