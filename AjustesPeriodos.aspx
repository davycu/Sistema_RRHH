<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="AjustesPeriodos.aspx.cs" Inherits="Sistema_RRHH.AjustesPeriodos" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Ajustes Periodos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
    <h2>Ajustes de Periodos de Evaluación</h2>
    
    <!-- Formulario para crear/editar un periodo -->
    <div class="card mb-4">
      <div class="card-header">
            Crear Nuevo Periodo
      </div>
      <div class="card-body">
        <asp:Literal ID="litMensaje" runat="server"></asp:Literal>
        <!-- HiddenField para saber si estamos editando (almacena el id_periodo) -->
        <asp:HiddenField ID="hfPeriodoID" runat="server" />

        <div class="mb-3">
          <label for="ddlAnio" class="form-label">Año</label>
          <asp:DropDownList ID="ddlAnio" runat="server" CssClass="form-select">
              <asp:ListItem Value="2020">2020</asp:ListItem>
              <asp:ListItem Value="2021">2021</asp:ListItem>
              <asp:ListItem Value="2022">2022</asp:ListItem>
              <asp:ListItem Value="2023">2023</asp:ListItem>
              <asp:ListItem Value="2024">2024</asp:ListItem>
              <asp:ListItem Value="2025">2025</asp:ListItem>
              <asp:ListItem Value="2026">2026</asp:ListItem>
              <asp:ListItem Value="2027">2027</asp:ListItem>
              <asp:ListItem Value="2028">2028</asp:ListItem>
              <asp:ListItem Value="2029">2029</asp:ListItem>
              <asp:ListItem Value="2030">2030</asp:ListItem>
          </asp:DropDownList>
        </div>

        <div class="mb-3">
          <label for="ddlTrimestre" class="form-label">Trimestre</label>
          <asp:DropDownList ID="ddlTrimestre" runat="server" CssClass="form-select">
            <asp:ListItem Value="1">1</asp:ListItem>
            <asp:ListItem Value="2">2</asp:ListItem>
            <asp:ListItem Value="3">3</asp:ListItem>
            <asp:ListItem Value="4">4</asp:ListItem>
          </asp:DropDownList>
        </div>
        <div class="mb-3">
          <label for="txtFechaInicio" class="form-label">Fecha de Inicio</label>
          <asp:TextBox ID="txtFechaInicio" runat="server" CssClass="form-control" Placeholder="yyyy-mm-dd"></asp:TextBox>
        </div>
        <div class="mb-3">
          <label for="txtFechaFin" class="form-label">Fecha de Fin</label>
          <asp:TextBox ID="txtFechaFin" runat="server" CssClass="form-control" Placeholder="yyyy-mm-dd"></asp:TextBox>
        </div>
        <div class="mb-3">
          <!-- El botón Crear lleva confirmacin en el OnClientClick -->
          <asp:Button ID="btnCrearPeriodo" runat="server" 
              Text="Crear Periodo" 
              CssClass="btn btn-primary me-2" 
              OnClick="btnCrearPeriodo_Click" 
              OnClientClick="return confirm('¿Está seguro de guardar este periodo?');" />
          <!-- Botón Cancelar: limpia el formulario y vuelve al estado inicial -->
          <asp:Button ID="btnCancelar" runat="server" 
              Text="Cancelar" 
              CssClass="btn btn-secondary" 
              OnClick="btnCancelar_Click" />
        </div>
      </div>
    </div>
    
    <!-- Tabla con los periodos existentes -->
    <div class="card">
      <div class="card-header">
        Periodos Existentes
      </div>
      <div class="card-body">
        <asp:Repeater ID="repeaterPeriodos" runat="server">
          <HeaderTemplate>
            <div class="table-responsive">
              <table class="table table-bordered table-sm">
                <thead>
                  <tr class="text-center">
                    <th>Año</th>
                    <th>Trimestre</th>
                    <th>Fecha Inicio</th>
                    <th>Fecha Fin</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
          </HeaderTemplate>
          <ItemTemplate>
                  <tr class="text-center">
                    <td><%# Eval("anio") %></td>
                    <td><%# Eval("trimestre") %></td>
                    <td><%# Eval("fecha_inicio", "{0:yyyy-MM-dd}") %></td>
                    <td><%# Eval("fecha_fin", "{0:yyyy-MM-dd}") %></td>
                    <td>
                      <!-- Botón Editar: carga los datos en el formulario -->
                      <asp:LinkButton ID="lnkEditarPeriodo" runat="server" Text="Editar" 
                          CommandArgument='<%# Eval("id_periodo") %>' OnClick="lnkEditarPeriodo_Click" CssClass="btn btn-sm btn-warning me-1" />
                      <!-- Botón Eliminar -->
                      <asp:LinkButton ID="lnkEliminarPeriodo" runat="server" Text="Eliminar" 
                          CommandArgument='<%# Eval("id_periodo") %>' OnClick="lnkEliminarPeriodo_Click" CssClass="btn btn-sm btn-danger" 
                          OnClientClick="return confirm('¿Está seguro de eliminar este periodo?');" />
                    </td>
                  </tr>
          </ItemTemplate>
          <FooterTemplate>
                </tbody>
              </table>
            </div>
          </FooterTemplate>
        </asp:Repeater>
      </div>
    </div>
  </div>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script type="text/javascript"> 
    document.addEventListener('DOMContentLoaded', function () {
    setTimeout(function () {
        var alerts = document.querySelectorAll('.alert');
        alerts.forEach(function (alert) {
            alert.style.display = 'none';
        });
    }, 5000);
    });
    
        $(document).ready(function () {
            //Inicializar datepicker para Fecha de Inicio
            $('#<%= txtFechaInicio.ClientID %>').datepicker({
            format: 'yyyy-mm-dd',
            autoclose: true,
            todayHighlight: true,
            startDate: '2020-01-01',
            endDate: '2030-12-31'
        });
        
        //Inicializar datepicker para Fecha de Fin
        $('#<%= txtFechaFin.ClientID %>').datepicker({
            format: 'yyyy-mm-dd',
            autoclose: true,
            todayHighlight: true,
            startDate: '2020-01-01',
            endDate: '2030-12-31'
        });
    });
</script>

        

</asp:Content>
