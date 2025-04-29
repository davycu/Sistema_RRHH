<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="Anuncios.aspx.cs" Inherits="Sistema_RRHH.Anuncios" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Anuncios
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container mt-4">
        <h2>Gestión de Anuncios</h2>

        <!-- Card para Crear/Editar Anuncio -->
        <div class="card">
            <div class="card-header">
                <i class="fas fa-bullhorn"></i> Crear/Editar Anuncio
            </div>
            <div class="card-body">
                <asp:Literal ID="litAlert" runat="server"></asp:Literal>
                <input type="hidden" id="hiddenAnuncioId" runat="server" />

                <!-- Título del Anuncio -->
                <div class="mb-3">
                    <label for="txtTitulo" class="form-label">Título:</label>
                    <asp:TextBox ID="txtTitulo" runat="server" CssClass="form-control" placeholder="Ingrese título del anuncio"></asp:TextBox>
                </div>

                <!-- Mensaje del Anuncio -->
                <div class="mb-3">
                    <label for="txtMensaje" class="form-label">Mensaje:</label>
                    <asp:TextBox ID="txtMensaje" runat="server" CssClass="form-control" placeholder="Ingrese mensaje del anuncio" TextMode="MultiLine" Rows="4"></asp:TextBox>
                </div>

                <!-- Estado Activo -->
                <div class="mb-3 form-check">
                    <asp:CheckBox ID="chkActivo" runat="server" Text="Activo" />
                    <label class="form-check-label" for="<%= chkActivo.ClientID %>"></label>
                </div>

                <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" />
                <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
            </div>
        </div>

        <!-- Card para Listar Anuncios -->
        <div class="card mt-4">
            <div class="card-header">
                <i class="fas fa-table"></i> Lista de Anuncios
            </div>
            <div class="card-body">
                <asp:Repeater ID="repeaterAnuncios" runat="server">
                    <HeaderTemplate>
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th class="text-nowrap">Título</th>
                                    <th class="text-nowrap">Mensaje</th>
                                    <th class="text-nowrap">Fecha Publicación</th>
                                    <th class="text-nowrap">Activo</th>
                                    <th class="text-nowrap">Creado Por</th>
                                    <th class="text-nowrap">Fecha Modificación</th>
                                    <th class="text-nowrap">Modificado Por</th>
                                    <th class="text-nowrap">Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><%# Eval("titulo") %></td>
                            <td><%# Eval("mensaje") %></td>
                            <td><%# Eval("fecha_publicacion", "{0:yyyy-MM-dd HH:mm}") %></td>
                            <td><%# Eval("activo") %></td>
                            <td><%# Eval("usuario_creacion") %></td>
                            <td><%# Eval("fecha_modificacion", "{0:yyyy-MM-dd HH:mm}") %></td>
                            <td><%# Eval("usuario_modificacion") %></td>
                            <td>
                                <div class="d-flex gap-2">
                                <asp:Button ID="btnEditar" runat="server" Text="Editar" CssClass="btn btn-warning btn-sm"
                                    CommandArgument='<%# Eval("id_anuncio") %>' OnClick="btnEditar_Click" />
                                <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" CssClass="btn btn-danger btn-sm"
                                    CommandArgument='<%# Eval("id_anuncio") %>' OnClick="btnEliminar_Click"
                                    OnClientClick="return confirm('¿Está seguro de eliminar este anuncio?');" 
                                    Visible='<%# ((string)Session["rol"]).ToLower() == "admin" %>' />
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

</asp:Content>
