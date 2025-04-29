<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="HistorialEvalSupv.aspx.cs" Inherits="Sistema_RRHH.HistorialEvalSupv" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Historial Evaluaciones - Supervisor
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
    <h2>Historial de Evaluaciones Completadas</h2>

        <asp:Literal ID="litAlert" runat="server"></asp:Literal>
    
    <!-- Filtros: Año, Empleado y Trimestre -->
    <div class="row mb-3">
      <div class="col-md-4">
        <label for="ddlAnios">Año:</label>
        <asp:DropDownList ID="ddlAnios" runat="server" AutoPostBack="true" 
          OnSelectedIndexChanged="ddlAnios_SelectedIndexChanged" 
          CssClass="form-control dropdown-compact"></asp:DropDownList>
      </div>
      <div class="col-md-4">
        <label for="ddlEmpleados">Empleado:</label>
        <asp:DropDownList ID="ddlEmpleados" runat="server" AutoPostBack="true" 
          OnSelectedIndexChanged="ddlEmpleados_SelectedIndexChanged" 
          CssClass="form-control dropdown-compact"></asp:DropDownList>
      </div>
      <div class="col-md-4">
        <label for="ddlTrimestres">Trimestre:</label>
        <asp:DropDownList ID="ddlTrimestres" runat="server" AutoPostBack="true" 
          OnSelectedIndexChanged="ddlTrimestres_SelectedIndexChanged" 
          CssClass="form-control dropdown-compact"></asp:DropDownList>
      </div>
    </div>
    
        <!-- boton "Nueva Búsqueda" -->
        <div class="row mb-3">
            <div class="col-md-12">
                <asp:Button ID="btnNuevaBusqueda" runat="server" Text="Nueva Búsqueda"
                    CssClass="btn btn-primary" OnClick="btnNuevaBusqueda_Click" ToolTip="Borrar campos y realizar una nueva búsqueda." />
            </div>
        </div>

    <!-- Panel para mostrar el historial -->
<asp:Panel ID="pnlHistorial" runat="server" Visible="false" CssClass="mt-4">
    <asp:Repeater ID="rptEvaluaciones" runat="server">
        <HeaderTemplate>
            <table class="table table-bordered">
                <thead>
                    <tr>
                        <th>Pregunta</th>
                        <th>Puntaje Empleado</th>
                        <th>Comentario Empleado</th>
                        <th>Puntaje Supervisor</th>
                        <th>Comentario Supervisor</th>
                    </tr>
                </thead>
                <tbody>
        </HeaderTemplate>
        <ItemTemplate>
                    <tr>
                        <td><%# Eval("texto_pregunta") %></td>
                        <td><%# Eval("puntaje_empleado") %></td>
                        <td><%# Eval("comentario_empleado") %></td>
                        <td><%# Eval("puntaje_supervisor") %></td>
                        <td><%# Eval("comentario_supervisor") %></td>
                    </tr>
        </ItemTemplate>
        <FooterTemplate>
                </tbody>
            </table>
        </FooterTemplate>
    </asp:Repeater>
</asp:Panel>
    
    <asp:Literal ID="litMensaje" runat="server"></asp:Literal>

        <asp:Panel ID="pnlDetalles" runat="server" CssClass="mt-3">
    <p><strong>Evaluado Por:</strong>
        <asp:Literal ID="litEvaluadoPor" runat="server" /></p>
    <p><strong>Departamento:</strong>
        <asp:Literal ID="litDepartamento" runat="server" /></p>
    <p><strong>Fecha Evaluación:</strong>
        <asp:Literal ID="litFechaEvaluacion" runat="server" /></p>
</asp:Panel>
    
    <!-- Botón para descargar PDF del historial -->
    <asp:LinkButton ID="lnkDescargarPdf" runat="server" CssClass="btn btn-danger mt-2" 
        OnClick="lnkDescargarPdf_Click" ToolTip="Descargar PDF">
      <i class="fas fa-file-pdf"></i>
    </asp:LinkButton>
    
  </div>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

     <script type="text/javascript">
document.addEventListener('DOMContentLoaded', function(){
    setTimeout(function(){
       var alerts = document.querySelectorAll('.alert');
       alerts.forEach(function(alert){ alert.style.display = 'none'; });
    }, 5000);
});
     </script>

</asp:Content>
