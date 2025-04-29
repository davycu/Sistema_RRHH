<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="EvaluarEmpleados.aspx.cs" Inherits="Sistema_RRHH.EvaluarEmpleados" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Evaluar Empleados
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
    <h2 class="mb-3">Evaluar Empleados</h2>
    <asp:Literal ID="litMensaje" runat="server"></asp:Literal>
    
    <!-- Fila con dropdown para selección de evaluación y botón para eliminar autoevaluación -->
    <div class="row mb-3">
      <div class="col-md-6">
         <label for="ddlEvaluaciones" class="form-label">Selecciona Evaluación</label>
         <asp:DropDownList ID="ddlEvaluaciones" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="ddlEvaluaciones_SelectedIndexChanged">
         </asp:DropDownList>
      </div>
      <div class="col-md-6 text-end">
         <!-- Botón visible solo para Admin (o según decidas) -->
         <asp:Button ID="btnResetear" runat="server" Text="Eliminar Autoevaluación" CssClass="btn btn-danger" 
             OnClick="btnResetear_Click" 
             ToolTip="Borra la autoevaluación para que el empleado pueda volver a ingresarla" />
      </div>
    </div>
    
    <!-- Panel con el detalle de la evaluación -->
    <asp:Panel ID="pnlEvaluacion" runat="server" Visible="false">
      <asp:Repeater ID="rptEvaluacion" runat="server">
        <HeaderTemplate>
          <table class="table table-bordered">
            <thead>
              <tr>
                <th>Pregunta</th>
                <th>Respuesta Empleado</th>
                <th>Puntaje Supervisor</th>
                <th>Comentario Supervisor</th>
              </tr>
            </thead>
            <tbody>
        </HeaderTemplate>
        <ItemTemplate>
          <tr>
            <td><%# Eval("texto_pregunta") %></td>
            <td>
              <strong>Puntaje:</strong> <%# Eval("puntaje_empleado") %><br />
              <strong>Comentario:</strong> <%# Eval("comentario_empleado") %>
            </td>
            <td>
              <asp:DropDownList ID="ddlPuntajeSupervisor" runat="server" CssClass="form-select">
                <asp:ListItem Value="1">1 - Muy Bajo</asp:ListItem>
                <asp:ListItem Value="2">2 - Bajo</asp:ListItem>
                <asp:ListItem Value="3">3 - Regular</asp:ListItem>
                <asp:ListItem Value="4">4 - Muy Bien</asp:ListItem>
                <asp:ListItem Value="5">5 - Excelente</asp:ListItem>
              </asp:DropDownList>
            </td>
            <td>
              <asp:TextBox ID="txtComentarioSupervisor" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" Placeholder="Ingrese comentario"></asp:TextBox>
            </td>
            <!-- Campo oculto para identificar la pregunta -->
            <asp:HiddenField ID="hfIdPregunta" runat="server" Value='<%# Eval("id_pregunta") %>' />
          </tr>
        </ItemTemplate>
        <FooterTemplate>
            </tbody>
          </table>
        </FooterTemplate>
      </asp:Repeater>
      
      <!-- Comentarios generales del supervisor -->
      <div class="mb-3">
        <label for="txtComentariosGenerales" class="form-label">Comentarios Generales</label>
        <asp:TextBox ID="txtComentariosGenerales" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" Placeholder="Ingrese comentarios generales"></asp:TextBox>
      </div>
      
      <asp:Button ID="btnGuardarEvaluacion" runat="server" Text="Guardar Evaluación" OnClick="btnGuardarEvaluacion_Click" CssClass="btn btn-success" />
      <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" OnClick="btnCancelar_Click" CssClass="btn btn-secondary" />
    </asp:Panel>
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
