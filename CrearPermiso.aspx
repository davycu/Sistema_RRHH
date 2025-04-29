<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="CrearPermiso.aspx.cs" Inherits="Sistema_RRHH.CrearPermiso" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Crear Tipo de Permiso
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

<div class="container mt-4">
        <!-- Formulario de creación/edición -->
        <div class="card">
            <div class="card-header">
                <i class="fas fa-edit"></i> Crear / Editar Tipo de Permiso
            </div>
            <div class="card-body">
                <asp:Literal ID="litAlert" runat="server"></asp:Literal>
                
                <!-- HiddenField para modo edición -->
                <asp:HiddenField ID="hiddenTipoPermiso" runat="server" />
                
                <!-- Nombre del Permiso -->
                <div class="mb-3">
                    <label for="txtNombrePermiso" class="form-label">Nombre del Permiso *</label>
                    <asp:TextBox ID="txtNombrePermiso" runat="server" CssClass="form-control" placeholder="Ej.: Vacaciones"></asp:TextBox>
                </div>
                
                <!-- Justificación (fusión de descripción y referencia) -->
                <div class="mb-3">
                    <label for="txtJustificacion" class="form-label">Justificación *</label>
                    <asp:TextBox ID="txtJustificacion" runat="server" TextMode="MultiLine" CssClass="form-control" placeholder="Ej.: Permiso interno o externo / Incluir artículo según ley"></asp:TextBox>
                </div>
                
                <!-- Días Máximos -->
                <div class="row">
                    <div class="mb-3 col-md-6">
                        <label for="txtDiasMaxAnuales" class="form-label">Días Máx Anuales *</label>
                        <asp:TextBox ID="txtDiasMaxAnuales" runat="server" CssClass="form-control" placeholder="Ej.: 15"></asp:TextBox>
                    </div>
                    <div class="mb-3 col-md-6">
                        <label for="txtDiasMaxMensuales" class="form-label">Días Máx Mensuales</label>
                        <asp:TextBox ID="txtDiasMaxMensuales" runat="server" CssClass="form-control" placeholder="Ej.: 2"></asp:TextBox>
                    </div>
                </div>
                
                <!-- Requiere Documento -->
                <div class="mb-3">
                    <div class="form-check">
                        <asp:CheckBox ID="chkRequiereDocumento" runat="server" />
                        <label for='<%= chkRequiereDocumento.ClientID %>' class="form-check-label">
                            Requiere Documento Adjunto
                        </label>
                    </div>
                </div>

                
                <!-- Botones -->
                <div class="mb-3">
                    <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" />
                    <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
                </div>
            </div>
        </div>
        
        <!-- Listado de Tipos de Permisos -->
        <div class="card mt-4">
            <div class="card-header">
                <i class="fas fa-table"></i> Lista de Tipos de Permisos
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <asp:Repeater ID="repeaterTiposPermisos" runat="server" OnItemDataBound="ocultarBtnEliminar">
                        <HeaderTemplate>
                            <table class="table table-bordered table-sm">
                                <thead>
                                    <tr class="text-center">
                                        <th>Código</th>
                                        <th>Nombre</th>
                                        <th>Justificación</th>
                                        <th>Días Máx Anuales</th>
                                        <th>Días Máx Mensuales</th>
                                        <th>Requiere Doc.</th>
                                        <th>Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                                    <tr>
                                        <td class="text-center"><%# Eval("codigo_permiso") %></td>
                                        <td><%# Eval("nombre_permiso") %></td>
                                        <td><%# Eval("justificacion") %></td>
                                        <td class="text-center"><%# Eval("dias_maximos_anuales") %></td>
                                        <td class="text-center"><%# Eval("dias_maximos_mensuales") %></td>
                                        <td class="text-center">
                                            <%# Convert.ToBoolean(Eval("requiere_documento")) ? "Sí" : "No" %>
                                        </td>
                                        <td class="text-center">
                                            <div class="d-inline-flex">
                                            <asp:Button ID="btnEditar" runat="server" Text="Editar" CssClass="btn btn-warning btn-sm me-2"
                                                CommandArgument='<%# Eval("id_tipo_permiso") %>' OnClick="btnEditar_Click" />
                                            <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" CssClass="btn btn-danger btn-sm"
                                                CommandArgument='<%# Eval("id_tipo_permiso") %>' OnClick="btnEliminar_Click"
                                                OnClientClick="return confirm('¿Está seguro de eliminar este tipo de permiso?');" />
                                                </div>
                                        </td>
                                    </tr>
                        </ItemTemplate>
                        <FooterTemplate>
                                </tbody>
                            </table>
                        </FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

        <script>
        //ocultar alert después de 5 segundos
        document.addEventListener('DOMContentLoaded', function () {
            setTimeout(function () {
                var alerts = document.querySelectorAll('.alert');
                alerts.forEach(function (alert) {
                    alert.style.display = 'none';
                });
            }, 5000);
        });
        </script>

        <style>
        .form-check-input[type="hidden"] {
             display: none !important;
        }
        </style>



</asp:Content>
