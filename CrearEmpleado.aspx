<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="CrearEmpleado.aspx.cs" Inherits="Sistema_RRHH.CrearEmpleado" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Gestión de Empleados
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

        <div class="container mt-4">
        <h2>Gestión de Empleados</h2>

        <!-- Tarjeta para Crear/Editar Empleado -->
        <div class="card">
            <div class="card-header">
                <i class="fas fa-user-plus"></i> Crear/Editar Empleado
            </div>
            <div class="card-body">
                <!-- Literal para mostrar mensajes de alerta -->
                <asp:Literal ID="litAlert" runat="server"></asp:Literal>

                <!-- Campo oculto para almacenar el id del empleado en edición -->
                <asp:HiddenField ID="hiddenEmpleadoId" runat="server" />

                <!-- Nombre -->
                <div class="mb-3">
                    <label for="txtNombre" class="form-label">Nombre *</label>
                    <asp:TextBox ID="txtNombre" runat="server" CssClass="form-control" placeholder="Ingrese el nombre"></asp:TextBox>
                </div>

                <!-- Apellido -->
                <div class="mb-3">
                    <label for="txtApellido" class="form-label">Apellido</label>
                    <asp:TextBox ID="txtApellido" runat="server" CssClass="form-control" placeholder="Ingrese el apellido"></asp:TextBox>
                </div>

                <!-- Correo -->
                <div class="mb-3">
                    <label for="txtCorreo" class="form-label">Correo *</label>
                    <asp:TextBox ID="txtCorreo" runat="server" CssClass="form-control" placeholder="Ingrese el correo con el dominio de la empresa, @email.com"></asp:TextBox>
                    <asp:RegularExpressionValidator 
                        ID="revCorreo" 
                        runat="server" 
                        ControlToValidate="txtCorreo"
                        ErrorMessage="El correo debe tener el dominio @email.com"
                        ValidationExpression="^[\w\.-]+@email\.com$"
                        CssClass="text-danger" 
                        Display="Dynamic" />
                </div>

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

                <!-- Cargo -->
                <div class="mb-3">
                    <label for="txtCargo" class="form-label">Cargo *</label>
                    <asp:TextBox ID="txtCargo" runat="server" CssClass="form-control" placeholder="Ingrese el cargo"></asp:TextBox>
                </div>

                <!-- Salario -->
                <div class="mb-3">
                    <label for="txtSalario" class="form-label">Salario (L.) *</label>
                    <asp:TextBox ID="txtSalario" runat="server" CssClass="form-control" placeholder="Ej. 15000.00"></asp:TextBox>
                </div>

                <!-- Fecha de Ingreso -->
                <div class="mb-3">
                    <label for="txtFechaIngreso" class="form-label">Fecha de Ingreso *</label>
                    <asp:TextBox ID="txtFechaIngreso" runat="server" CssClass="form-control" placeholder="yyyy-MM-dd" TextMode="Date" Width="150px"></asp:TextBox>
                </div>

                <!-- Fecha de Finalización -->
                <div class="mb-3">
                    <label for="txtFechaFinalizacion" class="form-label">Fecha de Finalización</label>
                    <asp:TextBox ID="txtFechaFinalizacion" runat="server" CssClass="form-control" placeholder="yyyy-MM-dd" TextMode="Date" Width="150px"></asp:TextBox>
                </div>

                <!-- Tipo de Empleado -->
                <div class="mb-3">
                    <label for="ddlTipoEmpleado" class="form-label">Tipo de Empleado *</label>
                    <asp:DropDownList ID="ddlTipoEmpleado" runat="server" CssClass="form-select">
                        <asp:ListItem Text="Seleccione tipo" Value="0"></asp:ListItem>
                        <asp:ListItem Text="Interno" Value="Interno"></asp:ListItem>
                        <asp:ListItem Text="Externo" Value="Externo"></asp:ListItem>
                    </asp:DropDownList>
                </div>

                <!-- Comentario (solo para externos) -->
                <div class="mb-3">
                    <label for="txtComentario" class="form-label">Comentario</label>
                    <asp:TextBox ID="txtComentario" runat="server" TextMode="MultiLine" CssClass="form-control" placeholder="Ingrese comentario (solo para empleados externos)"></asp:TextBox>
                </div>

                <!-- Departamento -->
                <div class="mb-3">
                    <label for="ddlDepartamento" class="form-label">Departamento *</label>
                    <asp:DropDownList ID="ddlDepartamento" runat="server" CssClass="form-select">
                    </asp:DropDownList>
                </div>

                <!-- Departamento Supervisado (opcional) -->
                <div class="mb-3">
                    <label for="ddlSupervisorDepto" class="form-label">Departamento para Supervisar (opcional)</label>
                    <asp:DropDownList ID="ddlSupervisorDepto" runat="server" CssClass="form-select">
                    </asp:DropDownList>
                </div>

                <!-- Botones -->
                <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-primary" OnClick="btnGuardar_Click" />
                <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn btn-secondary" OnClick="btnCancelar_Click" />
            </div>
        </div>

        <!-- Lista de Empleados -->
<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-table"></i> Lista de Empleados
    </div>
    <div class="card-body">
        <!-- Envolvemos la tabla en un contenedor responsive -->
        <div class="table-responsive">
            <asp:Repeater ID="repeaterEmpleados" runat="server" OnItemDataBound="ocultarBtnEliminar">
                <HeaderTemplate>
                    <table class="table table-bordered table-sm">
                        <thead>
                            <tr class="text-center">
                                <th>Código</th>
                                <th>Código Supervisor</th>
                                <th>Nombre</th>
                                <th>Correo</th>
                                <th>Departamento</th>
                                <th>Supervisor Dept.</th>
                                <th>Tipo Empleado</th>
                                <th>Fechas</th>
                                <th>Comentario</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                            <tr style="font-size: small">
                                <td><%# Eval("codigo_empleado") %></td>
                                <td><%# Eval("codigoSupervisor") %></td>
                                <td><%# Eval("nombre") %> <%# Eval("apellido") %></td>
                                <td><%# Eval("correo") %></td>
                                <td><%# Eval("departamento") %></td>
                                <td><%# Eval("supervisorDepto") %></td>
                                <td><%# Eval("TipoEmpleado") %></td>
                                <td style="font-size:smaller;">
                                    <strong>Ingreso:</strong> <%# Eval("fecha_ingreso") %> <br />
                                    <strong>Salida:</strong> <%# Eval("fecha_finalizacion") %>
                                <td><%# Eval("Comentario") %></td>
                                </td>
                                <td>
                                    <asp:Button ID="btnEditar" runat="server" Text="Editar" CssClass="btn btn-warning btn-sm"
                                        CommandArgument='<%# Eval("id_empleado") %>' OnClick="btnEditar_Click" />
                                    <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" CssClass="btn btn-danger btn-sm"
                                        CommandArgument='<%# Eval("id_empleado") %>' OnClick="btnEliminar_Click"
                                        OnClientClick="return confirm('¿Está seguro de eliminar este empleado?');" />
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

    <script type="text/javascript"> $(document).ready(function () { $('#<%= txtTelefono.ClientID %>').mask('0000-0000'); }); </script>

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
   // $(document).ready(function () {
     //   $('#<%= txtFechaIngreso.ClientID %>').datepicker({
       //     format: 'yyyy-mm-dd',
         //   autoclose: true,
       // });
       // $('#<%= txtFechaFinalizacion.ClientID %>').datepicker({
         //   format: 'yyyy-mm-dd',
          //  autoclose: true,
       // });
   // });
</script>

    <script type="text/javascript">
        $(document).ready(function () {
            $('#<%= txtSalario.ClientID %>').on('blur', function () {
            var valor = $(this).val();
            if (valor) {
                //Quitar cualquier coma ya existente y convertir a número
                valor = valor.replace(/,/g, '');
                var num = parseFloat(valor);
                if (!isNaN(num)) {
                    //Formatear el número con separadores de miles y 2 decimales
                    $(this).val(num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
                }
            }
        });
    });
    </script>


</asp:Content>
