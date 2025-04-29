<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="CrearUsuario.aspx.cs" Inherits="Sistema_RRHH.CrearUsuario" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">

    Gestión de Usuarios

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

<div class="container mt-4">
        <h2>Gestión de Usuarios</h2>

        <div class="card">
            <div class="card-header">
                <i class="fas fa-user-plus"></i> Crear/Editar Usuario
            </div>
            <div class="card-body">
                <asp:Literal ID="litAlert" runat="server"></asp:Literal>

                <input type="hidden" id="hiddenUserId" runat="server" />

                <!-- Seleccionar Empleado -->
                <div class="mb-3">
                    <label for="ddlEmpleado" class="form-label">Empleado:</label>
                    <asp:DropDownList ID="ddlEmpleado" runat="server" CssClass="form-select">
                        <asp:ListItem Text="Seleccione un empleado" Value="0"></asp:ListItem>
                    </asp:DropDownList>
                </div>

                <!-- Nombre de Usuario -->
                <div class="mb-3">
                    <label for="txtUsername" class="form-label">Nombre de Usuario:</label>
                    <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" placeholder="Ingrese nombre de usuario"></asp:TextBox>
                </div>

                <!-- Contraseña -->
                <div class="mb-3">
                    <label for="txtPassword" class="form-label">Contraseña:</label>
                    <div class="input-group">
                        <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" placeholder="Ingrese contraseña" TextMode="Password"></asp:TextBox>
                        <button type="button" class="btn btn-outline-secondary" id="togglePassword">
                            <i class="fas fa-eye"></i>
                        </button>
                    </div>
                </div>

                <!-- Rol -->
                <div class="mb-3">
                    <label for="ddlRol" class="form-label">Rol:</label>
                    <asp:DropDownList ID="ddlRol" runat="server" CssClass="form-select">
                        <asp:ListItem Value="admin">Admin</asp:ListItem>
                        <asp:ListItem Value="rh">RH</asp:ListItem>
                        <asp:ListItem Value="supervisor">Supervisor</asp:ListItem>
                        <asp:ListItem Value="empleado">Empleado</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <!-- Estado -->
                <div class="mb-3">
                    <label for="ddlEstado" class="form-label">Estado:</label>
                    <asp:DropDownList ID="ddlEstado" runat="server" CssClass="form-select">
                        <asp:ListItem Value="Activo">Activo</asp:ListItem>
                        <asp:ListItem Value="Inactivo">Inactivo</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" />
                <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
            </div>
        </div>

        <div class="card mt-4">
            <div class="card-header">
                <i class="fas fa-table"></i> Lista de Usuarios
            </div>
            <div class="card-body">
                <asp:Repeater ID="repeaterUsuarios" runat="server">
                    <HeaderTemplate>
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th>Código</th>
                                    <th>Nombre</th>
                                    <th>Usuario</th>
                                    <th>Rol</th>
                                    <th>Estado</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><%# Eval("codigo_usuario") %></td>
                            <td><%# Eval("nombreCompleto") %></td>
                            <td><%# Eval("username") %></td>
                            <td><%# Eval("rol") %></td>
                            <td><%# Eval("estado") %></td>
                            <td>
                                <asp:Button ID="btnEditar" runat="server" Text="Editar" CssClass="btn btn-warning btn-sm"
                                    CommandArgument='<%# Eval("id_usuario") %>' OnClick="btnEditar_Click" />
                                <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" CssClass="btn btn-danger btn-sm"
                                    CommandArgument='<%# Eval("id_usuario") %>' OnClick="btnEliminar_Click" OnClientClick="return confirm('¿Está seguro de eliminar este usuario?');" />
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
           document.addEventListener('DOMContentLoaded', function () {
               setTimeout(function () {
                   var alerts = document.querySelectorAll('.alert');
                   alerts.forEach(function (alert) {
                       alert.style.display = 'none';
                   });
               }, 5000); // 5 segundos
           });
       </script>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var togglePassword = document.getElementById('togglePassword');
            var passwordField = document.getElementById('<%= txtPassword.ClientID %>');

        togglePassword.addEventListener('click', function () {
            if (passwordField.type === 'password') {
                passwordField.type = 'text';
                togglePassword.innerHTML = '<i class="fas fa-eye-slash"></i>';
            } else {
                passwordField.type = 'password';
                togglePassword.innerHTML = '<i class="fas fa-eye"></i>';
            }
        });
    });
    </script>


</asp:Content>
