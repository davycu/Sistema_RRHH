<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="HistorialPermisos.aspx.cs" Inherits="Sistema_RRHH.HistorialPermisos" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Historial de Permisos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

          <!-- Resumen de Permisos -->
    <div class="card mt-4">
        <div class="card-header">
            <i class="fas fa-chart-bar me-2"></i> Resumen de Permisos
        </div>
        <div class="card-body">
            <asp:Repeater ID="repeaterResumenPermisos" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                        <table class="table table-bordered table-sm">
                            <thead>
                                <tr class="text-center">
                                    <th>Tipo Permiso</th>
                                    <th>Días Disponibles</th>
                                    <th>Horas Disponibles</th>
                                    <th>Total Horas Solicitadas</th>
                                    <th>Total Días Solicitados</th>
                                </tr>
                            </thead>
                            <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                                <tr>
                                    <td class="text-center"><%# Eval("nombre_permiso") %></td>
                                    <!-- Formateamos SaldoDiasReal a 1 decimal -->
                                    <td class="text-center">
                                        <%# Eval("SaldoDiasReal") != DBNull.Value 
                                             ? Convert.ToDouble(Eval("SaldoDiasReal")).ToString("0.0") 
                                             : "0.0" %>
                                    </td>
                                    <td class="text-center"><%# Eval("horas_disponibles", "{0:0.##}") %></td>
                                    <td class="text-center"><%# Eval("total_horas_solicitadas", "{0:0.##}") %></td>
                                    <td class="text-center">
                                        <%# (Convert.ToDouble(Eval("total_horas_solicitadas")) / 8.0).ToString("0.0") %>
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

    <!-- Historial Detallado de Permisos -->
    <div class="card mt-4">
        <div class="card-header">
            <i class="fas fa-history me-2"></i> Historial Detallado de Permisos
        </div>
        <div class="card-body">
            <asp:Repeater ID="repeaterHistorialPermisos" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                        <table class="table table-bordered table-sm" style="font-size:0.9rem;">
                            <thead>
                                <tr class="text-center">
                                    <th>Código</th>
                                    <th>Permiso</th>
                                    <th>Fecha Inicio</th>
                                    <th>Fecha Fin</th>
                                    <th>Horas</th>
                                    <th>Días</th>
                                    <th>Fecha Solicitud</th>
                                    <th>Estado</th>
                                    <th>Documento</th>
                                    <th>Comentarios Empleado</th>
                                    <th>Comentarios Supervisor</th>
                                    <th>Revisado Por</th>
                                    <th>Fecha Revisión</th>
                                </tr>
                            </thead>
                            <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                                <tr>
                                    <td class="text-center"><%# Eval("codigo_permiso") %></td>
                                    <td><%# Eval("nombre_permiso") %></td>
                                    <td class="text-center"><%# Eval("fecha_inicio", "{0:yyyy-MM-dd}") %></td>
                                    <td class="text-center"><%# Eval("fecha_fin", "{0:yyyy-MM-dd}") %></td>
                                    <td class="text-center"><%# Eval("horas_solicitadas") %></td>

                                    <td class="text-center">
                                        <%# (Convert.ToDouble(Eval("horas_solicitadas")) / 8.0).ToString("0.0") %>
                                    </td>
                                    <td class="text-center"><%# Eval("fecha_solicitud", "{0:yyyy-MM-dd HH:mm}") %></td>

                                    <td class="text-center" style='<%# GetStatusColor(Eval("estado").ToString()) %>'>
                                        <%# Eval("estado") %>
                                    </td>
                                    <td class="text-center">
                                       <%# Eval("documento") != DBNull.Value && !String.IsNullOrEmpty(Eval("documento").ToString()) 
                                          ? "<a href='" + ResolveUrl("~/Permisos/" + System.IO.Path.GetFileName(Eval("documento").ToString())) + "' target='_blank'>Ver/Descargar</a>" 
                                          : "N/A" %>
                                    </td>
                                    <td><%# Eval("comentarios_empleado") %></td>
                                    <td><%# Eval("comentarios_supervisor") %></td>
                                    <td>
                                        <%# Eval("revisado_por") != DBNull.Value ? Eval("revisado_por").ToString() : "-" %>
                                    </td>
                                    <td class="text-center">
                                        <%# Eval("fecha_revisado") != DBNull.Value ? String.Format("{0:yyyy-MM-dd HH:mm}", Eval("fecha_revisado")) : "-" %>
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

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
