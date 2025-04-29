<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="AjustesEvaluaciones.aspx.cs" Inherits="Sistema_RRHH.AjustesEvaluaciones" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Ajustes Evaluaciones
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    
    <div class="container mt-4">
    <h2>Ajustes de Preguntas de Evaluación</h2>
    <asp:Literal ID="litMensaje" runat="server"></asp:Literal>

    <!-- Panel para crear/editar una pregunta -->
    <div class="card">
      <div class="card-header">
        Crear / Editar Pregunta de Evaluación
      </div>
      <div class="card-body">
        <!-- HiddenField para modo edición (si se desea editar una pregunta ya creada) -->
        <asp:HiddenField ID="hfIdPregunta" runat="server" />

        <div class="mb-3">
          <label for="txtPregunta" class="form-label"><strong>Pregunta 1 *</strong></label>
          <asp:TextBox ID="txtPregunta" runat="server" CssClass="form-control" placeholder="Ingrese la pregunta"></asp:TextBox>
        </div>
          <div class="mb-3">
          <label for="txtPregunta2" class="form-label">Pregunta 2 (opcional)</label>
          <asp:TextBox ID="txtPregunta2" runat="server" CssClass="form-control" Placeholder="Ingrese pregunta 2 (opcional)"></asp:TextBox>
        </div>
        <div class="mb-3">
          <label for="txtPregunta3" class="form-label">Pregunta 3 (opcional)</label>
          <asp:TextBox ID="txtPregunta3" runat="server" CssClass="form-control" Placeholder="Ingrese pregunta 3 (opcional)"></asp:TextBox>
        </div>

        <div class="mb-3">
          <label for="ddlCategoria" class="form-label"><strong>Sección</strong></label>
          <asp:DropDownList ID="ddlCategoria" runat="server" CssClass="form-select">
            <asp:ListItem Value="Desempeño Laboral">Desempeño Laboral</asp:ListItem>
            <asp:ListItem Value="Política Organizacional">Política Organizacional</asp:ListItem>
            <asp:ListItem Value="Cumplimiento">Cumplimiento</asp:ListItem>
          </asp:DropDownList>
        </div>

          <div class="mb-3">
            <label class="form-label"><strong>Año</strong></label>
            <asp:DropDownList ID="ddlAnios" runat="server" AutoPostBack="true" CssClass="form-select" OnSelectedIndexChanged="ddlAnios_SelectedIndexChanged">
            </asp:DropDownList>
        </div>

        <div class="mb-3">
          <label class="form-label"><strong>Asignar a Periodos</strong></label>
          <!-- CheckBoxList para seleccionar uno o más periodos -->
          <asp:CheckBoxList ID="cblPeriodos" runat="server" RepeatLayout="Flow" RepeatDirection="Vertical" CssClass="form-check">
          </asp:CheckBoxList>
        </div>

        <div class="mb-3">
          <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" OnClientClick="return confirm('¿Está seguro de guardar esta pregunta?');" />
          <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
        </div>
      </div>
    </div>

       <!-- Filtro automático para el GridView de Preguntas -->
        <div class="row mb-2 mt-4">
            <div class="col-md-6">
                <input type="text" id="txtFiltroPreguntas" class="form-control" placeholder="Filtrar preguntas..." />
            </div>
        </div>


    <!-- Panel para mostrar la lista de preguntas -->
    <asp:GridView ID="gvPreguntas" runat="server" AutoGenerateColumns="false" ClientIDMode="Static" CssClass="table table-bordered"
        AllowPaging="true" PageSize="50" OnPageIndexChanging="gvPreguntas_PageIndexChanging">
        <PagerSettings Mode="NextPrevious" />
        <PagerStyle HorizontalAlign="Center" />
        <Columns>
            <asp:BoundField DataField="id_pregunta" HeaderText="ID" Visible="false" />
            <asp:BoundField DataField="texto_pregunta" HeaderText="Pregunta" />
            <asp:BoundField DataField="seccion" HeaderText="Sección" />

            <asp:TemplateField HeaderText="Periodo">
            <ItemTemplate>
                <div style="white-space: normal; word-break: break-word;">
                    <%# FormatPeriodos(Eval("Periodos").ToString()) %>
                </div>
            </ItemTemplate>
        </asp:TemplateField>

            <asp:TemplateField HeaderText="Acciones">
                <ItemTemplate>
                    <asp:LinkButton ID="lnkEditar" runat="server" Text="Editar" 
                        CommandArgument='<%# Eval("id_pregunta") %>' 
                        OnClick="lnkEditar_Click" CssClass="btn btn-sm btn-warning" />
                    <asp:LinkButton ID="lnkEliminar" runat="server" Text="Eliminar" 
                        CommandArgument='<%# Eval("id_pregunta") %>' 
                        OnClick="lnkEliminar_Click" CssClass="btn btn-sm btn-danger" 
                        OnClientClick="return confirm('¿Está seguro de eliminar esta pregunta?');" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script>

    document.addEventListener('DOMContentLoaded', function () {
        setTimeout(function () {
            var alerts = document.querySelectorAll('.alert');
            alerts.forEach(function (alert) {
                alert.style.display = 'none';
            });
        }, 5000);
    });

    </script>

    <script type="text/javascript">
        $(document).ready(function () {
            $("#txtFiltroPreguntas").on("keyup", function () {
                var value = $(this).val().toLowerCase();
                //selecciona las filas del cuerpo de la tabla (tbody) del GridView con id "gvPreguntas"
                $("#gvPreguntas tbody tr").filter(function () {
                    $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
                });
            });
        });
</script>

</asp:Content>
