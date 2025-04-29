<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="AutoEvaluacion.aspx.cs" Inherits="Sistema_RRHH.AutoEvaluacion" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Autoevaluacion
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="alert alert-info permanent-alert">
        <strong>Fecha de Ingreso:</strong>
        <asp:Label ID="lblFechaIngreso" runat="server" />
        &nbsp;&nbsp;
    <strong>Antigüedad:</strong>
        <asp:Label ID="lblAntiguedad" runat="server" />
        <br />
        Si su fecha de ingreso es posterior al inicio del periodo seleccionado, no podrá autoevaluarse en periodos anteriores.
    </div>


    <div class="container mt-4">
    <h2 class="mb-3">Autoevaluación</h2>
    <asp:Literal ID="litMensaje" runat="server"></asp:Literal>
        <asp:Literal ID="litEvaluadoPor" runat="server"></asp:Literal>
    
    <!-- Selección de Periodo -->
    <div class="row mb-3">
            <div class="col-md-4">
                <label for="ddlAnios" class="form-label">Año</label>
                <asp:DropDownList ID="ddlAnios" runat="server" CssClass="form-select"></asp:DropDownList>
            </div>
            <div class="col-md-4">
                <label for="ddlTrimestres" class="form-label">Trimestre</label>
                <asp:DropDownList ID="ddlTrimestres" runat="server" CssClass="form-select">
                    <asp:ListItem Value="1">1</asp:ListItem>
                    <asp:ListItem Value="2">2</asp:ListItem>
                    <asp:ListItem Value="3">3</asp:ListItem>
                    <asp:ListItem Value="4">4</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="col-md-4 d-flex align-items-end">
                <asp:Button ID="btnCargarPreguntas" runat="server" Text="Cargar Preguntas" OnClick="btnCargarPreguntas_Click" CssClass="btn btn-primary" />
            </div>
        </div>
        
        <!-- Panel de Preguntas -->
        <asp:Panel ID="pnlPreguntas" runat="server" Visible="false">
    <asp:Repeater ID="rptPreguntas" runat="server">
        <HeaderTemplate>
            <table class="table table-bordered">
                <thead>
                    <tr>
                        <th>Pregunta</th>
                        <th>Puntaje</th>
                        <th>Comentarios</th>
                    </tr>
                </thead>
                <tbody>
        </HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td><%# Eval("texto_pregunta") %></td>
                <td>
                    <asp:DropDownList ID="ddlPuntaje" runat="server" CssClass="form-select">
                        <asp:ListItem Value="1">1 - Muy Bajo</asp:ListItem>
                        <asp:ListItem Value="2">2 - Bajo</asp:ListItem>
                        <asp:ListItem Value="3">3 - Regular</asp:ListItem>
                        <asp:ListItem Value="4">4 - Muy Bien</asp:ListItem>
                        <asp:ListItem Value="5">5 - Excelente</asp:ListItem>
                    </asp:DropDownList>
                </td>
                <td>
                    <asp:TextBox ID="txtComentario" runat="server" CssClass="form-control" 
                        TextMode="MultiLine" Rows="3" Placeholder="Justifique su puntaje"></asp:TextBox>
                </td>
                <!-- Campo Hidden para almacenar el ID de la pregunta -->
                <asp:HiddenField ID="hfIdPregunta" runat="server" Value='<%# Eval("id_pregunta") %>' />
            </tr>
        </ItemTemplate>
        <FooterTemplate>
                </tbody>
            </table>
        </FooterTemplate>
    </asp:Repeater>
    <asp:Button ID="btnGuardarAutoevaluacion" runat="server" Text="Guardar Autoevaluación" 
        OnClick="btnGuardarAutoevaluacion_Click" CssClass="btn btn-success mt-3" />
    <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" OnClick="btnCancelar_Click" 
        CssClass="btn btn-secondary mt-3" ToolTip="Borrar todos los campos" />
            </asp:Panel>
    
    <!-- Panel de Retroalimentación (solo lectura, si ya fue evaluado por el supervisor) -->
    <asp:Panel ID="pnlRetroalimentacion" runat="server" Visible="false" CssClass="mt-4">
      <h3>Retroalimentación del Supervisor</h3>
      <asp:Literal ID="litRetroalimentacion" runat="server"></asp:Literal>
    </asp:Panel>
  </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script type="text/javascript"> 
        document.addEventListener('DOMContentLoaded', function () {
            setTimeout(function () {
                var alerts = document.querySelectorAll('.alert:not(.permanent-alert)');
                alerts.forEach(function (alert) {
                    alert.style.display = 'none';
                });
            }, 5000);
        });
    </script>

</asp:Content>
