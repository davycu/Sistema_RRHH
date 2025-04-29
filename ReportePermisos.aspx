<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="ReportePermisos.aspx.cs" Inherits="Sistema_RRHH.ReportePermisos" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Reporte Permisos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
  
    <div class="container mt-4">
        <h2 class="mb-4">
            <i class="fas fa-file-alt me-2"></i>Reporte: Saldo de Permisos por Empleado
        </h2>
        <div class="row mb-3">
            <div class="col-md-4">
                <div class="form-group">
                    <asp:DropDownList
                        ID="ddlEmpleados"
                        runat="server"
                        CssClass="form-control"
                        AutoPostBack="true"
                        OnSelectedIndexChanged="ddlEmpleados_SelectedIndexChanged">
                    </asp:DropDownList>
                </div>
            </div>
        </div>
        <asp:Panel ID="infoEmpleado" runat="server" CssClass="mt-4" Visible="false">
            <p><strong>Departamento:</strong> <span id="lblDepartamento" runat="server"></span></p>
            <asp:GridView
                ID="gvPermisos"
                runat="server"
                AutoGenerateColumns="false"
                CssClass="table table-striped table-bordered">
                <Columns>
                    <asp:BoundField DataField="nombre_permiso" HeaderText="Tipo de Permiso" />
                    <asp:BoundField DataField="DiasDisponibles" HeaderText="Días Disponibles" DataFormatString="{0:N2}" />
                    <asp:BoundField DataField="HorasDisponibles" HeaderText="Horas Disponibles" DataFormatString="{0:N2}" />
                </Columns>
            </asp:GridView>
        </asp:Panel>
    </div>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
