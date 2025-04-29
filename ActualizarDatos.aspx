<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="ActualizarDatos.aspx.cs" Inherits="Sistema_RRHH.ActualizarDatos" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Actualizar Datos
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
        <h2 class="mb-4">Actualizar Datos Personales</h2>
        <asp:Literal ID="litMensaje" runat="server"></asp:Literal>
        <p class="text-muted">Si encuentra alguna inconsistencia en sus datos, por favor contacte a Recursos Humanos.</p>

        <!-- Fila que une título + supervisados -->
        <div class="row mb-4 align-items-start">
            <!-- Columna izquierda: Título y datos del usuario -->
            <div class="col-md-7">
                <h3 class="mb-3">Mis Datos Actuales</h3>
                <h4 class="fw-bold text-primary mb-2">
                    <asp:Literal ID="litNombreCompleto" runat="server" />
                </h4>
                <p class="mb-1"><strong>Departamento:</strong>
                    <asp:Literal ID="litDepartamento" runat="server" /></p>
                <p class="mb-0"><strong>Cargo:</strong>
                    <asp:Literal ID="litCargo" runat="server" /></p>
            </div>

            <!-- Columna derecha: Supervisados (solo para supervisor) -->
            <asp:Panel ID="panelSupervisados" runat="server" CssClass="col-md-5" Visible="false">
                <div class="card h-100">
                    <div class="card-header">
                        <i class="fas fa-users me-1"></i>Empleados bajo mi cargo
                    </div>
                    <div class="card-body p-0">
                        <!-- Contenedor de scroll: sólo vertical -->
                        <div style="max-height: 250px; overflow-y: auto; overflow-x: hidden;">
                            <table class="table table-sm table-hover table-bordered text-center mb-0 w-100 text-start"
                                style="table-layout: auto; border-color: #dee2e6;">
                                <thead class="table-light">
                                    <tr class="text-center">
                                        <th>Código</th>
                                        <th>Nombre</th>
                                        <th>Cargo</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <asp:Repeater ID="rptSupervisados" runat="server">
                                        <ItemTemplate>
                                            <tr>
                                                <td class="text-start text-nowrap"><%# Eval("codigo_empleado")   %></td>
                                                <td class="text-start text-nowrap"><%# Eval("nombreCompleto")     %></td>
                                                <td class="text-start text-nowrap"><%# Eval("cargo")              %></td>
                                            </tr>
                                        </ItemTemplate>
                                    </asp:Repeater>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </asp:Panel>
        </div>


    <!-- Tabla con datos del empleado -->
        
        <div class="table-responsive">
            <table class="table table-bordered table-sm" style="font-size: 14px">
                <thead class="table-light">
                    <tr class="text-center">
                        <th>Código Empleado</th>
                        <th>Fecha Nacimiento</th>
                        <th>Género</th>
                        <th>Dirección</th>
                        <th>Teléfono</th>
                        <th>Correo</th>
                        <th>Usuario</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="repeaterDatos" runat="server">
                        <ItemTemplate>
                            <tr class="text-center">
                                <td class="text-nowrap"><%# Eval("codigo_empleado") %></td>
                                <td class="text-nowrap"><%# Eval("fecha_nacimiento", "{0:yyyy-MM-dd}") %></td>
                                <td class="text-nowrap"><%# Eval("genero") %></td>
                                <td class="text-nowrap"><%# Eval("direccion") %></td>
                                <td class="text-nowrap"><%# Eval("telefono") %></td>
                                <td class="text-nowrap"><%# Eval("correo") %></td>
                                <td class="text-nowrap"><%# Eval("username") %></td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>
        
        <p class="text-muted">Por favor actualice o corrija sus datos.</p>

        <div class="card mb-4">
            <div class="card-body">
                <asp:Panel ID="pnlFormulario" runat="server">
                    <!-- Teléfono -->
                    <div class="mb-3">
                        <label for="txtTelefono" class="form-label">Teléfono</label>
                        <div class="input-group">
                            <span class="input-group-text">+504</span>
                            <asp:TextBox ID="txtTelefono" runat="server" CssClass="form-control" placeholder="Ingrese 8 dígitos, ej. 1234-5678"></asp:TextBox>
                        </div>
                        <asp:RegularExpressionValidator 
                            ID="revTelefono" 
                            runat="server" 
                            ControlToValidate="txtTelefono"
                            ErrorMessage="El teléfono debe tener 8 dígitos, ej. 1234-5678"
                            ValidationExpression="^\d{4}-?\d{4}$"
                            CssClass="text-danger" 
                            Display="Dynamic" />
                    </div>
                    <!-- Dirección -->
                    <div class="mb-3">
                        <label for="txtDireccion" class="form-label">Dirección</label>
                        <asp:TextBox ID="txtDireccion" runat="server" CssClass="form-control" placeholder="Ingrese su dirección"></asp:TextBox>
                    </div>
                    <!-- Género -->
                    <div class="mb-3">
                        <label for="ddlGenero" class="form-label">Género</label>
                        <asp:DropDownList ID="ddlGenero" runat="server" CssClass="form-select">
                            <asp:ListItem Value="">Seleccione género</asp:ListItem>
                            <asp:ListItem Value="Masculino">Masculino</asp:ListItem>
                            <asp:ListItem Value="Femenino">Femenino</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                    <!-- Fecha de Nacimiento -->
                    <div class="mb-3">
                        <label for="txtFechaNacimiento" class="form-label">Fecha de Nacimiento</label>
                        <asp:TextBox ID="txtFechaNacimiento" runat="server" CssClass="form-control" placeholder="yyyy-mm-dd" TextMode="Date" Width="150px"></asp:TextBox>
                    </div>
                    <!-- Contraseña -->
                    <div class="mb-3">
                        <label for="txtPassword" class="form-label">Contraseña:</label>
                        <div class="input-group">
                            <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" placeholder="Ingrese contraseña (opcional)" TextMode="Password"></asp:TextBox>
                            <button type="button" class="btn btn-outline-secondary" id="togglePassword">
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="ddlPreguntaSeguridad" class="form-label">Pregunta de Seguridad</label>
                        <asp:DropDownList ID="ddlPreguntaSeguridad" runat="server" CssClass="form-control">
                        </asp:DropDownList>
                    </div>
                    <div class="mb-3">
                        <label for="txtRespuestaSeguridad" class="form-label">Respuesta de Seguridad</label>
                        <div class="input-group">
                            <asp:TextBox ID="txtRespuestaSeguridad" runat="server" CssClass="form-control" TextMode="Password"></asp:TextBox>
                            <button type="button" class="btn btn-outline-secondary" id="toggleRespuesta">
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>
                    </div>


                    <asp:Button ID="btnActualizar" runat="server" Text="Actualizar Datos" CssClass="btn btn-primary" OnClick="btnActualizar_Click" />
                    <!-- Botón Cancelar que limpia el formulario -->
                    <asp:Button ID="btnCancelar" runat="server" Text="Borrar Campos" CssClass="btn btn-secondary" OnClientClick="LimpiarFormulario(); return false;" ToolTip="Borrar todos los campos del formulario" />
                    
                </asp:Panel>
            </div>
        </div>
        
        
    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    

    <script type="text/javascript">
        $(document).ready(function () {


            // Ocultar alerts después de 5 segundos
            setTimeout(function () {
                $('.alert').fadeOut();
            }, 5000);

            // visibilidad de la contraseña
            $('#togglePassword').click(function () {
                var passwordField = $('#<%= txtPassword.ClientID %>');
            if (passwordField.attr('type') === 'password') {
                passwordField.attr('type', 'text');
                $(this).html('<i class="fas fa-eye-slash"></i>');
            } else {
                passwordField.attr('type', 'password');
                $(this).html('<i class="fas fa-eye"></i>');
            }
            });
        });

        // Alternar visibilidad para la respuesta de seguridad
        $('#toggleRespuesta').click(function () {
            var respuestaField = $('#<%= txtRespuestaSeguridad.ClientID %>');
            if (respuestaField.attr('type') === 'password') {
                respuestaField.attr('type', 'text');
                $(this).html('<i class="fas fa-eye-slash"></i>');
            } else {
                respuestaField.attr('type', 'password');
                $(this).html('<i class="fas fa-eye"></i>');
            }
        });

        // Función global para limpiar el formulario
        function LimpiarFormulario() {
            $("#<%= txtTelefono.ClientID %>").val("");
            $("#<%= txtDireccion.ClientID %>").val("");
            $("#<%= ddlGenero.ClientID %>").val("");
            $("#<%= txtFechaNacimiento.ClientID %>").val("");
            $("#<%= txtPassword.ClientID %>").val("");
            $("#<%= txtRespuestaSeguridad.ClientID %>").val("");
        }

    </script>

</asp:Content>
