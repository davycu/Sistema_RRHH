<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="Auditoria.aspx.cs" Inherits="Sistema_RRHH.Auditoria" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Auditoría del Sistema
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
        <h2>Auditoría del Sistema</h2>
        <asp:GridView ID="gvAuditoria" runat="server" CssClass="table table-striped table-bordered" AutoGenerateColumns="False">
            <Columns>
                <asp:BoundField DataField="id_auditoria" HeaderText="ID" />
                <asp:BoundField DataField="tabla_afectada" HeaderText="Tabla" />
                <asp:BoundField DataField="id_registro" HeaderText="ID Registro" />
                <asp:BoundField DataField="tipo_accion" HeaderText="Acción" />
                <asp:BoundField DataField="fecha_cambio" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
                <asp:BoundField DataField="usuario_modificador" HeaderText="Usuario" />
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
