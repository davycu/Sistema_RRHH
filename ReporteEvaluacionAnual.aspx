<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="ReporteEvaluacionAnual.aspx.cs" Inherits="Sistema_RRHH.ReporteEvaluacionAnual" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Reporte Evaluacion Anual
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container mt-4">
    <h2>Reporte de Evaluación Anual</h2>
<div class="d-flex mb-4">
  <!-- Leyenda de Aumentos -->
  <div class="card me-3" style="width: 300px;">
    <div class="card-header py-1" style="font-size: 0.85rem; font-style: italic; font-weight: bold;">
      Leyenda de Aumentos
    </div>
    <div class="card-body p-0">
      <table class="table table-sm mb-0" style="font-size: 0.85rem;">
        <thead>
          <tr>
            <th>Porcentaje (%)</th>
            <th class="text-center">% Aumento</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>90 o más</td>
            <td class="text-center"><strong>5%</strong></td>
          </tr>
          <tr>
            <td>80 - 89</td>
            <td class="text-center"><strong>4%</strong></td>
          </tr>
          <tr>
            <td>70 - 79</td>
            <td class="text-center"><strong>3%</strong></td>
          </tr>
          <tr>
            <td>60 - 69</td>
            <td class="text-center"><strong>2%</strong></td>
          </tr>
          <tr>
            <td>Menos de 60</td>
            <td class="text-center"><strong>1%</strong></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Resumen de Empleados pendientes -->
  <div class="card" style="flex: 1; max-height: 300px; overflow-y: auto;">
    <div class="card-header py-1" style="font-size: 0.85rem; font-style: italic; font-weight: bold;">
      Empleados sin comenzar proceso de Evaluación Anual
    </div>
    <div class="card-body p-2" style="font-size: 0.85rem;">
      <asp:GridView ID="gvResumenPendientes" runat="server" AutoGenerateColumns="false" CssClass="table table-sm table-bordered mb-0">
          <Columns>
              <asp:BoundField DataField="Empleado" HeaderText="Empleado" />
              <asp:BoundField DataField="PendienteAnios" HeaderText="Años Pendientes" />
              <asp:BoundField DataField="Departamento" HeaderText="Departamento" />
              <asp:BoundField DataField="Cargo" HeaderText="Cargo" />
          </Columns>
      </asp:GridView>
    </div>
  </div>
</div>


        
        <!-- Fila con dropdown y botones de exportación alineados en la misma línea -->
        <div class="row mb-3">
            <div class="col-md-6">
                <asp:Label ID="lblAnio" runat="server" Text="Año:" CssClass="me-2"></asp:Label>
                <asp:DropDownList 
                    ID="ddlAnioReporte" 
                    runat="server" 
                    AutoPostBack="true" 
                    OnSelectedIndexChanged="ddlAnioReporte_SelectedIndexChanged" 
                    CssClass="form-select d-inline-block" 
                    style="width: auto;">
                </asp:DropDownList>
            </div>
            <div class="col-md-6 text-end">
                <!-- Botón de Excel con icono -->
                <asp:LinkButton ID="btnExportarExcel" runat="server" OnClick="btnExportarExcel_Click" CssClass="btn btn-success me-2" ToolTip="Exportar a Excel">
                    <i class="fas fa-file-excel"></i>
                </asp:LinkButton>
                <asp:LinkButton ID="btnExportarPDF" runat="server" OnClick="btnExportarPDF_Click" CssClass="btn btn-danger" ToolTip="Exportar a PDF">
                    <i class="fas fa-file-pdf"></i>
                </asp:LinkButton>
            </div>
        </div>
        
        <asp:GridView ID="gvReporte" runat="server" AutoGenerateColumns="false" CssClass="table table-striped custom-grid">
    <Columns>
        <asp:BoundField DataField="codigo_empleado" HeaderText="Código Empleado" />
        <asp:BoundField DataField="nombreEmpleado" HeaderText="Empleado" />
        <asp:BoundField DataField="departamento" HeaderText="Departamento" />
        <asp:BoundField DataField="fechaIngreso" HeaderText="Fecha Ingreso" DataFormatString="{0:dd/MM/yyyy}" />
        <asp:BoundField DataField="totalPuntos" HeaderText="Total Puntos" />
        <asp:BoundField DataField="porcentajeAnual" HeaderText="Porcentaje (%)" DataFormatString="{0:N2}" />
        <asp:BoundField DataField="salario" HeaderText="Salario Actual" DataFormatString="L {0:N2}" />
        <asp:BoundField DataField="porcentajeAumento" HeaderText="Porcentaje aplicado" DataFormatString="{0:N2}" />
        <asp:BoundField DataField="nuevoSalario" HeaderText="Salario Sugerido" DataFormatString="L {0:N2}" />
        
        <asp:TemplateField HeaderText="Evaluaciones Completadas">
            <ItemTemplate>
                <asp:Literal ID="litEvaluacionesSupervisor" runat="server" 
                    Text='<%# Eval("evaluacionesSupervisor") %>' 
                    Mode="PassThrough"></asp:Literal>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Evaluaciones Pendientes">
            <ItemTemplate>
                <asp:Literal ID="litEvaluacionesSupervisorPendientes" runat="server" 
                    Text='<%# Eval("evaluacionesSupervisorPendientes") %>' 
                    Mode="PassThrough"></asp:Literal>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Autoevaluaciones Pendientes">
            <ItemTemplate>
                <asp:Literal ID="litEvaluacionesAutoPendientes" runat="server" 
                    Text='<%# Eval("evaluacionesAutoPendientes") %>' 
                    Mode="PassThrough"></asp:Literal>
            </ItemTemplate>
        </asp:TemplateField>
    </Columns>
</asp:GridView>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
