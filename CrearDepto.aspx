<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="CrearDepto.aspx.cs" Inherits="Sistema_RRHH.CrearDepto" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">

    Crear Departamento

</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

<div class="container mt-4">
        <h2>Gestión de Departamentos</h2>

        <div class="card">
            <div class="card-header">
                <i class="fas fa-building"></i> Crear/Editar Departamento
            </div>
            <div class="card-body">
                <asp:Literal ID="litAlert" runat="server"></asp:Literal>

                <input type="hidden" id="hiddenDeptId" runat="server" />

                <!-- Nombre del Departamento -->
                <div class="mb-3">
                    <label for="txtNombreDepto" class="form-label">Nombre del Departamento:</label>
                    <asp:TextBox ID="txtNombreDepto" runat="server" CssClass="form-control" placeholder="Ingrese nombre del departamento"></asp:TextBox>
                </div>

                <!-- Seleccionar Supervisor del Departamento -->
                <div class="mb-3">
                    <label for="ddlSupervisor" class="form-label">Supervisor del Departamento:</label>
                    <asp:DropDownList ID="ddlSupervisor" runat="server" CssClass="form-select">
                        <asp:ListItem Text="Seleccione un supervisor" Value="0"></asp:ListItem>
                    </asp:DropDownList>
                </div>

                <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" />
                <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
            </div>
        </div>

        <div class="card mt-4">
            <div class="card-header">
                <i class="fas fa-table"></i> Lista de Departamentos
            </div>
            <div class="card-body">
                <asp:Repeater ID="repeaterDepartamentos" runat="server" OnItemDataBound="ocultarBtnEliminar">
                    <HeaderTemplate>
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th>Código</th>
                                    <th>Nombre</th>
                                    <th>Supervisor</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><%# Eval("codigo_departamento") %></td>
                            <td><%# Eval("nombre_departamento") %></td>
                            <td><%# Eval("supervisor") %></td>
                            <td>
                                <asp:Button ID="btnEditar" runat="server" Text="Editar" CssClass="btn btn-warning btn-sm"
                                    CommandArgument='<%# Eval("id_departamento") %>' OnClick="btnEditar_Click" />
                                <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" CssClass="btn btn-danger btn-sm"
                                    CommandArgument='<%# Eval("id_departamento") %>' OnClick="btnEliminar_Click" OnClientClick="return confirm('¿Está seguro de eliminar este departamento?');" />
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

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script>
        // Ocultar alertas después de 3 segundos
        document.addEventListener('DOMContentLoaded', function () {
            setTimeout(function () {
                var alerts = document.querySelectorAll('.alert');
                alerts.forEach(function (alert) {
                    alert.style.display = 'none';
                });
            }, 3000);
        });
    </script>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>


</asp:Content>
