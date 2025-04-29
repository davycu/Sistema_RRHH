<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="IngresarPermiso.aspx.cs" Inherits="Sistema_RRHH.IngresarPermiso" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Ingresar Permiso
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

<div class="container mt-4">

      <div class="card">
          <div class="card-header">
              <i class="fas fa-calendar-plus me-2"></i> Solicitar Permiso
          </div>
          <div class="card-body">
              <asp:Literal ID="litAlert" runat="server"></asp:Literal>
              
              <!-- Dropdown de Tipos de Permiso -->
              <div class="mb-3">
                  <label for="ddlTipoPermiso" class="form-label">Tipo de Permiso *</label>
                  <asp:DropDownList ID="ddlTipoPermiso" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="ddlTipoPermiso_SelectedIndexChanged">
                      <asp:ListItem Value="0">Seleccione un tipo de permiso</asp:ListItem>
                  </asp:DropDownList>
              </div>
              
              <!-- Saldo Disponible -->
              <div class="mb-3">
                  <asp:Label ID="lblSaldo" runat="server" Text="" CssClass="form-control-plaintext"></asp:Label>
              </div>
              
              <!-- Unidad de Solicitud: Días o Horas -->
              <div class="mb-3">
                  <label class="form-label">Unidad de Solicitud</label>
                  <div class="form-check form-check-inline">
                      <asp:RadioButton ID="rbDias" runat="server" GroupName="unidad" Text="Días" Checked="true" />
                  </div>
                  <div class="form-check form-check-inline">
                      <asp:RadioButton ID="rbHoras" runat="server" GroupName="unidad" Text="Horas" />
                  </div>
                  <div class="form-check form-check-inline">
                        <asp:RadioButton ID="rbUnDia" runat="server" GroupName="unidad" Text="1 Día" />
                  </div>
              </div>
              
              <!-- Fechas: Fecha de Inicio y Fecha de Fin -->
              <div class="row">
                  <div class="mb-3 col-md-6">
                      <label for="txtFechaInicio" class="form-label">Fecha de Inicio *</label>
                      <asp:TextBox ID="txtFechaInicio" runat="server" CssClass="form-control" placeholder="yyyy-mm-dd" />
                  </div>
                  <div class="mb-3 col-md-6" id="divFechaFin" runat="server">
                      <label for="txtFechaFin" class="form-label">Fecha Final *</label>
                      <asp:TextBox ID="txtFechaFin" runat="server" CssClass="form-control" placeholder="yyyy-mm-dd" />
                  </div>
              </div>
              
              <!-- Selector de Horas: siempre visible, pero se habilita solo si se solicita por horas -->
              <div class="mb-3">
                  <label for="ddlHoras" class="form-label">Horas Solicitadas *</label>
                  <asp:DropDownList ID="ddlHoras" runat="server" CssClass="form-select">
                      <asp:ListItem Value="0">Seleccione las horas</asp:ListItem>
                      <asp:ListItem Value="1">1</asp:ListItem>
                      <asp:ListItem Value="2">2</asp:ListItem>
                      <asp:ListItem Value="3">3</asp:ListItem>
                      <asp:ListItem Value="4">4</asp:ListItem>
                      <asp:ListItem Value="5">5</asp:ListItem>
                      <asp:ListItem Value="6">6</asp:ListItem>
                      <asp:ListItem Value="7">7</asp:ListItem>
                      <asp:ListItem Value="8">8</asp:ListItem>
                  </asp:DropDownList>
              </div>
              
              <!-- Comentarios del Empleado -->
              <div class="mb-3">
                  <label for="txtComentarios" class="form-label">Comentarios *</label>
                  <asp:TextBox ID="txtComentarios" runat="server" TextMode="MultiLine" CssClass="form-control" placeholder="Escriba una justificación. Si eligió horas, especifique el rango." />
              </div>
              
              <!-- Subir Documento (si aplica) -->
              <div class="mb-3">
                  <label for="fuDocumento" class="form-label">Adjuntar Documento</label>
                  <asp:FileUpload ID="fuDocumento" runat="server" CssClass="form-control" />
              </div>
              
              <!-- Botones -->
              <div class="mb-3">
                  <asp:Button ID="btnSolicitar" runat="server" Text="Solicitar Permiso" CssClass="btn btn-primary" OnClick="btnSolicitar_Click" />
                  <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
              </div>
          </div>
      </div>

    <div class="card mt-4">
            <div class="card-header">
                <i class="fas fa-hourglass-half me-2"></i> Permisos Pendientes de Aprobar
            </div>
            <div class="card-body">
                <asp:Repeater ID="repeaterPendientes" runat="server">
                    <HeaderTemplate>
                        <div class="table-responsive">
                            <table class="table table-bordered table-sm">
                                <thead>
                                    <tr class="text-center">
                                        <th>Tipo de Permiso</th>
                                        <th>Fecha Inicio</th>
                                        <th>Fecha Fin</th>
                                        <th>Días Solicitados</th>
                                        <th>Horas Solicitadas</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                                    <tr>
                                        <td><%# Eval("nombre_permiso") %></td>
                                        <td class="text-center"><%# Eval("fecha_inicio", "{0:yyyy-MM-dd}") %></td>
                                        <td class="text-center"><%# Eval("fecha_fin", "{0:yyyy-MM-dd}") %></td>
                                        <td class="text-center">
                                            <%# (Convert.ToDouble(Eval("horas_solicitadas")) / 8.0).ToString("0.0") %>
                                        </td>
                                        <td class="text-center"><%# Eval("horas_solicitadas") %></td>
                                        <td class="text-center"><%# Eval("estado") %></td>
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

      
      <!-- Enlace a Historial de Permisos: Se redirige a una página separada -->
      <div class="mt-4 text-center">
          <a class="nav-link" href="HistorialPermisos.aspx">
              <i class="fas fa-history me-2"></i>Historial de Permisos
          </a>
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

            //Fechas de feriados (formato: yyyy-mm-dd)
            var feriados = [
                "2024-01-01", // Año Nuevo
                "2024-04-14", // dia de las americas
                "2024-04-17", // jueves santo
                "2024-04-18", //viernes santo
                "2024-04-19", // sabado santo
                "2024-04-20", //domingo de resurreccion
                "2024-09-15", //dia de la independencia
                "2024-10-03", //dia del soldado
                "2024-10-12", //dia de la raza
                "2024-10-21", //dia de las fuerzas armadas
                "2024-12-25",  // Navidad
                "2025-01-01", // Año Nuevo
                "2025-04-14", // dia de las americas
                "2025-04-17", // jueves santo
                "2025-04-18", //viernes santo
                "2025-04-19", // sabado santo
                "2025-04-20", //domingo de resurreccion
                "2025-09-15", //dia de la independencia
                "2025-10-03", //dia del soldado
                "2025-10-12", //dia de la raza
                "2025-10-21", //dia de las fuerzas armadas
                "2025-12-25"  // Navidad
            ];

            //Revisar fecha es feriado
            function esFeriado(date) {
                var d = new Date(date),
                    month = '' + (d.getMonth() + 1),
                    day = '' + d.getDate(),
                    year = d.getFullYear();
                if (month.length < 2) month = '0' + month;
                if (day.length < 2) day = '0' + day;
                var formattedDate = [year, month, day].join('-');
                return feriados.indexOf(formattedDate) !== -1;
            }
       

            //Inicializar datepickers con fines de semana deshabilitados
            $('#<%= txtFechaInicio.ClientID %>').datepicker({
                format: 'yyyy-mm-dd',
                autoclose: true,
                todayHighlight: true,
                daysOfWeekDisabled: [0, 6],
                beforeShowDay: function (date) {
                    if (esFeriado(date)) {
                        return {
                            enabled: true,
                            classes: 'holiday',
                            tooltip: 'Feriado'
                        };
                    }
                    return;
                }
            });
            $('#<%= txtFechaFin.ClientID %>').datepicker({
                format: 'yyyy-mm-dd',
                autoclose: true,
                todayHighlight: true,
                daysOfWeekDisabled: [0, 6],
                beforeShowDay: function (date) {
                    if (esFeriado(date)) {
                        return {
                            enabled: true,
                            classes: 'holiday',
                            tooltip: 'Feriado'
                        };
                    }
                    return;
                }
            });

            //se asume "Días": Fecha Fin habilitado y ddlHoras deshabilitado
            $('#<%= txtFechaFin.ClientID %>').prop('disabled', false).css("background-color", "");
            $('#<%= ddlHoras.ClientID %>').prop('disabled', true).css("background-color", "#e9ecef").val("0");

            //Si se selecciona "Horas", deshabilitar Fecha Fin y habilitar ddlHoras
            $('#<%= rbHoras.ClientID %>').change(function () {
                if ($(this).is(':checked')) {
                    $('#<%= txtFechaFin.ClientID %>').prop('disabled', true).css("background-color", "#e9ecef").val("");
            $('#<%= ddlHoras.ClientID %>').prop('disabled', false).css("background-color", "");
        }
    });

            //Si se selecciona "Días", habilitar Fecha Fin y deshabilitar ddlHoras
            $('#<%= rbDias.ClientID %>').change(function () {
        if ($(this).is(':checked')) {
            $('#<%= txtFechaFin.ClientID %>').prop('disabled', false).css("background-color", "");
            $('#<%= ddlHoras.ClientID %>').prop('disabled', true).css("background-color", "#e9ecef").val("0");
        }
    });
    
    //Si se selecciona "1 Día", deshabilitar Fecha Fin y fijar ddlHoras en 8 (deshabilitado)
    $('#<%= rbUnDia.ClientID %>').change(function () {
        if ($(this).is(':checked')) {
            $('#<%= txtFechaFin.ClientID %>').prop('disabled', true).css("background-color", "#e9ecef").val("");
            $('#<%= ddlHoras.ClientID %>').val("8").prop('disabled', true).css("background-color", "#e9ecef");
        }
    });
        });
    </script>

    <style>
    /* Estilo para resaltar feriados */
    .holiday {
        background-color: #ccffcc !important;  /* verde claro */
        color: #000 !important;
    }
</style>

</asp:Content>
