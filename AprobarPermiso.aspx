<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="AprobarPermiso.aspx.cs" Inherits="Sistema_RRHH.AprobarPermiso" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Aprobar Permisos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

     <div class="container mt-4">

    <!-- Filtro automático para permisos pendientes -->
    <div class="row mb-3">
      <div class="col-md-6">
        <input type="text" id="txtFiltroPendientes" class="form-control" placeholder="Filtrar por empleado (nombre o apellido) en pendientes" />
      </div>
    </div>

    <!-- Permisos Pendientes -->
    <div class="card">
      <div class="card-header">
        <i class="fas fa-hourglass-half me-2"></i> Permisos Pendientes
      </div>
      <div class="card-body">
        <asp:Repeater ID="repeaterPendientes" runat="server">
          <HeaderTemplate>
            <div class="table-responsive">
              <table id="tablePendientes" class="table table-bordered table-sm" style="font-size:0.9rem;">
                <thead>
                  <tr class="text-center">
                    <th>Permiso</th>
                    <th>Empleado</th>
                    <th>Fecha Inicio</th>
                    <th>Fecha Fin</th>
                    <th>Días</th>
                    <th>Horas</th>
                    <th>Fecha</th>
                    <th>Estado</th>
                    <th>Comentarios Empleado</th>
                    <th style="min-width:150px;">Comentarios Supervisor</th>
                    <th style="min-width:120px;">Acciones</th>
                  </tr>
                </thead>
                <tbody>
          </HeaderTemplate>
          <ItemTemplate>
                  <tr class="text-center">
                    <td><%# Eval("nombre_permiso") %></td>
                    <td><%# Eval("nombre") %> <%# Eval("apellido") %></td>
                    <td><%# Eval("fecha_inicio", "{0:yyyy-MM-dd}") %></td>
                    <td><%# Eval("fecha_fin", "{0:yyyy-MM-dd}") %></td>
                    <td>
                      <%# (Convert.ToDouble(Eval("horas_solicitadas")) / 8.0).ToString("0.0") %>
                    </td>
                    <td><%# Eval("horas_solicitadas") %></td>
                    <td><%# Eval("fecha_solicitud", "{0:yyyy-MM-dd HH:mm}") %></td>
                    <td style='<%# String.Format("background-color:{0}", GetStatusColor(Eval("estado").ToString())) %>'>
                      <%# Eval("estado") %>
                    </td>
                    <td style="max-width:150px;">
                      <div style="max-height:1.5em; line-height:1.5em; overflow-y:auto;" title='<%# Eval("comentarios_empleado") %>'>
                        <%# Eval("comentarios_empleado") %>
                      </div>
                    </td>
                    <!-- Columna para Comentarios Supervisor: se muestra un TextBox con scroll horizontal si es necesario -->
                    <td style="max-width:150px; overflow-x:auto; white-space:nowrap;">
                      <asp:TextBox ID="txtComentariosSupervisor" runat="server" 
                                     CssClass="form-control" TextMode="MultiLine" Rows="1" 
                                     Placeholder="Ingrese comentario"
                                     Text='<%# Eval("comentarios_supervisor") %>'></asp:TextBox>
                    </td>
                    <!-- Columna para Acciones: botones dispuestos horizontalmente -->
                    <td style="min-width:120px;">
                      <div class="d-flex gap-1 justify-content-center">
                        <asp:LinkButton ID="lnkAprobar" runat="server" Text="Aprobar" 
                                        CommandArgument='<%# Eval("id_permiso") %>' 
                                        OnClick="Aprobar_Click" CssClass="btn btn-sm btn-success" />
                        <asp:LinkButton ID="lnkRechazar" runat="server" Text="Rechazar" 
                                        CommandArgument='<%# Eval("id_permiso") %>' 
                                        OnClick="Rechazar_Click" CssClass="btn btn-sm btn-danger" />
                        <asp:LinkButton ID="lnkEliminar" runat="server" Text="Eliminar" 
                                        CommandArgument='<%# Eval("id_permiso") %>' 
                                        OnClick="Eliminar_Click" CssClass="btn btn-sm btn-warning" 
                                        Visible='<%# IsAdmin() %>' 
                                        OnClientClick="return confirm('¿Está seguro que desea eliminar este permiso?');" />
                      </div>
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

    
    <!-- Filtro automático para historial (aprobados/rechazados) -->
    <div class="row mb-2 mt-5">
      <div class="col-md-6">
        <input type="text" id="txtFiltroHistorial" class="form-control" placeholder="Filtrar historial por empleado (nombre o apellido)" />
      </div>
    </div>

    <!-- Historial de Permisos (Aprobados y Rechazados) -->
    <div class="card mt-3">
      <div class="card-header">
        <i class="fas fa-history me-2"></i> Historial de Permisos
      </div>
      <div class="card-body">
        <asp:Repeater ID="repeaterHistorial" runat="server">
          <HeaderTemplate>
            <div class="table-responsive">
              <table id="tableHistorial" class="table table-bordered table-sm" style="font-size:0.9rem;">
                <thead>
                  <tr class="text-center">
                    <th>Código</th>
                    <th>Permiso</th>
                    <th>Empleado</th>
                    <th>Fecha Inicio</th>
                    <th>Fecha Fin</th>
                    <th>Días</th>
                    <th>Horas</th>
                    <th>Fecha</th>
                    <th>Estado</th>
                    <th style="width: 15%;">Comentarios Empleado</th>
                    <th style="width: 15%;">Comentarios Supervisor</th>
                    <th>Revisado</th>
                    <th>Fecha Revisión</th>
                  </tr>
                </thead>
                <tbody>
          </HeaderTemplate>
          <ItemTemplate>
                  <tr class="text-center">
                    <td style="font-size:small"><%# Eval("codigo_permiso") %></td>
                    <td style="font-size:small"><%# Eval("nombre_permiso") %></td>
                    <td style="font-size:small"><%# Eval("nombre") %> <%# Eval("apellido") %></td>
                    <td style="font-size:small"><%# Eval("fecha_inicio", "{0:yyyy-MM-dd}") %></td>
                    <td style="font-size:small"><%# Eval("fecha_fin", "{0:yyyy-MM-dd}") %></td>
                    <td>
                      <%# (Convert.ToDouble(Eval("horas_solicitadas")) / 8.0).ToString("0.0") %>
                    </td>
                    <td><%# Eval("horas_solicitadas") %></td>
                    <td style="font-size:small"><%# Eval("fecha_solicitud", "{0:yyyy-MM-dd HH:mm}") %></td>
                    <td style='<%# String.Format("background-color:{0}", GetStatusColor(Eval("estado").ToString())) %>'>
                      <%# Eval("estado") %>
                    </td>
                    <td style="max-width:300px; font-size:smaller; overflow: hidden; white-space: normal; word-wrap:break-word">
                      <div title='<%# Eval("comentarios_empleado") %>'>
                        <%# Eval("comentarios_empleado") %>
                      </div>
                    </td>
                    <td style="max-width:150px; font-size:smaller; overflow: hidden; white-space: normal; word-wrap:break-word">
                      <div style="max-height:1.5em; line-height:1.5em; overflow-y:auto;" title='<%# Eval("comentarios_supervisor") %>'>
                        <%# Eval("comentarios_supervisor") %>
                      </div>
                    </td>
                    <td style="font-size:small">
                      <%# Eval("revisado_por") != DBNull.Value ? Eval("revisado_por") : "-" %>
                    </td>
                    <td style="font-size:small; max-width:fit-content; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                      <%# Eval("fecha_revisado") != DBNull.Value ? String.Format("{0:yyyy-MM-dd HH:mm}", Eval("fecha_revisado")) : "-" %>
                    </td>
                      <td>
                          <div class="d-inline-flex">
                          <asp:LinkButton ID="lnkEliminarPermiso" runat="server" CssClass="btn btn-danger btn-sm"
                            OnClick="EliminarPermisoHistorial_Click"
                            CommandArgument='<%# Eval("id_permiso") %>'
                            ToolTip="Eliminar Permiso"
                            Visible='<%# IsAdmin() %>'
                            OnClientClick="return confirm('¿Está seguro que desea eliminar este permiso?');">
                            <i class="fas fa-trash"></i>
                        </asp:LinkButton>
                          </div>
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
    //Filtro automático: a medida que el usuario escribe, filtra las filas del Repeater
    $(document).ready(function(){
        $("#txtFiltroEmpleado").on("keyup", function(){
            var value = $(this).val().toLowerCase();
            $("#tablePendientes tbody tr").filter(function(){
                $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
            });
        });
    });

        $(document).ready(function () {
            $("#txtFiltroHistorial").on("keyup", function () {
                var value = $(this).val().toLowerCase();
                $("#tableHistorial tbody tr").filter(function () {
                    $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
                });
            });
        });
  </script>

</asp:Content>
