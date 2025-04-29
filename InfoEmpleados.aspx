<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="InfoEmpleados.aspx.cs" Inherits="Sistema_RRHH.InfoEmpleados" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Info Empleados
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
        <h2>Info Empleados</h2>
        <div class="row mb-3">
            <div class="col-md-4">
                <asp:Label ID="lblEmpleado" runat="server" Text="Buscar Empleado:" CssClass="form-label"></asp:Label>
                <!-- Dropdown con búsqueda (se usa bootstrap-select) -->
                <asp:DropDownList 
                    ID="ddlEmpleados" 
                    runat="server" 
                    CssClass="form-select selectpicker" 
                    data-live-search="true" 
                    AutoPostBack="true" 
                    OnSelectedIndexChanged="ddlEmpleados_SelectedIndexChanged">
                </asp:DropDownList>
            </div>
        </div>
        <!-- Card para mostrar la información del empleado -->
        <asp:Panel ID="pnlEmpleadoInfo" runat="server" CssClass="card" Visible="false">
            <div class="card-header">
                Información del Empleado
            </div>
            <div class="card-body">
                <!-- Usamos filas y columnas para distribuir la información -->
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Código Empleado:</strong>
                        <span><asp:Label ID="lblCodigoEmpleado" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Nombre y Apellido:</strong>
                        <span><asp:Label ID="lblNombreCompleto" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Dirección:</strong>
                        <span><asp:Label ID="lblDireccion" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Teléfono:</strong>
                        <span><asp:Label ID="lblTelefono" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Género:</strong>
                        <span><asp:Label ID="lblGenero" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Departamento:</strong>
                        <span><asp:Label ID="lblDepartamento" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Cargo:</strong>
                        <span><asp:Label ID="lblCargo" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Supervisor:</strong>
                        <span><asp:Label ID="lblSupervisor" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Fecha Inicio:</strong>
                        <span><asp:Label ID="lblFechaIngreso" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Fecha Final:</strong>
                        <span><asp:Label ID="lblFechaFinalizacion" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Salario:</strong>
                        <span><asp:Label ID="lblSalario" runat="server"></asp:Label></span>
                    </div>
                    <div class="col-md-6">
                        <strong>Usuario:</strong>
                        <span><asp:Label ID="lblUsuario" runat="server"></asp:Label></span>
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-md-6">
                        <strong>Estado:</strong>
                        <span><asp:Label ID="lblEstado" runat="server"></asp:Label></span>
                    </div>
                </div>
            </div>
        </asp:Panel>
    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
