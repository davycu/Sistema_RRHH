<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="Sistema_RRHH.Dashboard" MaintainScrollPositionOnPostBack="true" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Dashboard
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Sección 1: Distribución de Empleados y Supervisores -->
    <div class="container mt-4">
        <h2 id="barChart"><i class="fas fa-chart-bar me-2"></i>Distribución Empleados</h2>
        <div id="chart">
            <svg id="svgBarChart" style="height:400px;"></svg>
        </div>

     <!-- Leyenda/tabla de supervisores por departamento -->
    <div class="row">
      <div class="col-md-12">
        <div class="card">
          <div class="card-header">
            <i class="fas fa-user-tie me-2"></i>Supervisores por Departamento
          </div>
          <div class="card-body">
            <asp:GridView ID="gvSupervisores" runat="server" AutoGenerateColumns="false" CssClass="table table-sm table-striped">
              <Columns>
                <asp:BoundField DataField="Departamento" HeaderText="Departamento" />
                <asp:BoundField DataField="Supervisor" HeaderText="Supervisor" />
                <asp:BoundField DataField="FechaInicio" HeaderText="Fecha de Inicio" DataFormatString="{0:dd/MM/yyyy}" />
                <asp:BoundField DataField="Salario" HeaderText="Salario" DataFormatString="L {0:N2}" />
              </Columns>
            </asp:GridView>
          </div>
        </div>
      </div>
    </div>

            <!-- Card para mostrar el total de empleados -->
        <div class="row mt-4">
            <div class="col-md-4 offset-md-4">
                <div class="card text-white bg-secondary mb-3">
                    <div class="card-header text-center">Total Empleados Activos</div>
                    <div class="card-body text-center">
                        <asp:Literal ID="litTotalEmpleados" runat="server" />

                    </div>
                </div>
            </div>
        </div>

        <hr class="my-4" style="border: 1px solid black;">
  </div>

    
    <!-- Sección 2: Evaluaciones Completadas -->
    <div class="container mt-4">
    <h2 id="evalCharts" class="mb-3">
        <i class="fas fa-chart-pie me-2"></i>Evaluaciones Completadas
    </h2>

    <div class="row mb-4">
        <div class="col-md-3">
            <asp:Label ID="lblAnioDash" runat="server" Text="Año:" CssClass="form-label" />
            <asp:DropDownList 
                ID="ddlAnioDash" 
                runat="server" 
                CssClass="form-select selectpicker" 
                AutoPostBack="true" 
                OnSelectedIndexChanged="ddlAnioDash_SelectedIndexChanged">
            </asp:DropDownList>
        </div>
    </div>
    <div id="chartEval">
        <svg id="svgPieChart" style="width:100%; height:400px;"></svg>
    </div>
        <hr class="my-4" style="border: 1px solid black;">
    </div>

        <!-- Sección 3: Histórico y Proyección de Solicitudes de Permisos -->
        <div class="container mt-4">
            <h2 id="lineChart" class="mb-3">
                <i class="fas fa-chart-line me-2"></i>Histórico y Proyección de Solicitudes de Permisos
            </h2>
            <div class="row mb-3">
            <!-- Dropdown para seleccionar el año de permisos -->
            <div class="col-md-3">
                <label for="ddlAnioPermisos">Año:</label>
                <asp:DropDownList ID="ddlAnioPermisos" runat="server" AutoPostBack="true"
                    OnSelectedIndexChanged="ddlAnioPermisos_SelectedIndexChanged" CssClass="form-control">
                </asp:DropDownList>
            </div>

            <!-- Dropdown para seleccionar el tipo de permiso -->
            <div class="col-md-3">
                <label for="ddlTipoPermiso">Tipo de Permiso:</label>
                <asp:DropDownList ID="ddlTipoPermiso" runat="server" AutoPostBack="true"
                    OnSelectedIndexChanged="ddlTipoPermiso_SelectedIndexChanged" CssClass="form-control">
                </asp:DropDownList>
            </div>
            </div>
            <canvas id="lineChartPermisos" style="width: 100%; height: 200px;"></canvas>
             <hr class="my-4" style="border: 1px solid black;">
        </div>

            <div class="container mt-4">
                <h2 class="mb-3">
                    <i class="fas fa-chart-pie me-2"></i>Distribución Empleados por Género
                </h2>
                <div id="chartGenero">
                    <svg id="svgPieGenero" style="width: 100%; height: 400px; margin: 0px auto; margin-left: 400px"></svg>
                </div>
            </div>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script type="text/javascript">
    //Recupera la data generada en el servidor
    var dataJSON = '<%= GetEmpleadosPorDepartamentoJSON() %>';
    var dt = JSON.parse(dataJSON);
    //Formatear la data para NVD3: un array con un objeto que tenga "key" y "values".
    var dataBar = [{
        key: "Departamentos",
        values: dt.map(function(item){
            return { label: item.Departamento, value: +item.Cantidad };
        })
    }];

    nv.addGraph(function() {
        var maxVal = d3.max(dataBar[0].values, d => d.value);
        var chart = nv.models.discreteBarChart()
            .x(d => d.label)
            .y(d => d.value)
            .staggerLabels(true)
            .showValues(true)
            .forceY([0, maxVal + 5])
            .duration(250);

        chart.yAxis
            .tickFormat(d3.format('d'))
            .tickValues(d3.range(0, maxVal + 5, 5));

        d3.select('#svgBarChart')
            .datum(dataBar)
            .call(chart);

        nv.utils.windowResize(chart.update);
        return chart;
    });
    </script>

    <!-- script pie chart -->
    <script type="text/javascript">
        var data = JSON.parse('<%= HttpUtility.JavaScriptStringEncode(GetEvaluacionesCompletadasJSON()) %>');

        nv.addGraph(function () {
            var chart = nv.models.pieChart()
                .x(d => d.label)
                .y(d => d.value)
                .showLabels(true)
                .donut(true)
                .labelType("percent");

            d3.select('#svgPieChart')
                .datum(data)
                .call(chart);

            nv.utils.windowResize(chart.update);
            return chart;
        });
    </script>

</asp:Content>
