<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="Mensajes.aspx.cs" Inherits="Sistema_RRHH.Mensajes" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Mensajes
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container-fluid mt-4">
    <div class="row">
       <!-- Panel de Contactos -->
        <div class="col-md-4">
          <div class="card">
            <div class="card-header">
             <strong> Contactos </strong>
            </div>
            <div class="card-body">
                <div style="max-height:400px; overflow-y:auto;">
              <asp:Repeater ID="repeaterContactos" runat="server">
                <HeaderTemplate>
                  <ul class="list-group">
                </HeaderTemplate>
                <ItemTemplate>
                  <li class="list-group-item">
                      <a href="#" class="contacto" data-id='<%# Eval("id_usuario") %>' 
                         title='Cargo: <%# Eval("cargo") %> | Departamento: <%# Eval("departamento") %>'>
                         <span class="contact-name"><%# Eval("nombre") %> <%# Eval("apellido") %></span>
                        <%-- Si el contacto tiene nuevos mensajes, se mostrará el indicador --%>
                        <%# Convert.ToBoolean(Eval("tieneMensajesNuevos")) ? "<span class='new-message-indicator'></span>" : "" %>
                      </a>
                    </li>
                </ItemTemplate>
                <FooterTemplate>
                  </ul>
                </FooterTemplate>
              </asp:Repeater>
            </div>
          </div>
        </div>
        </div>
      
      <!-- Panel de Conversación -->
      <div class="col-md-8">
        <div class="card">
          <div class="card-header">
          <strong> Conversación con:</strong> <strong><em><span id="lblContacto"></span></em></strong>
          </div>
          <div class="card-body" id="chatArea" style="height:500px; overflow-y:scroll;">
            <!-- Mensajes se cargarán vía AJAX -->
          </div>
          <div class="card-footer">
            <div class="input-group">
              <asp:TextBox ID="txtMensaje" runat="server" CssClass="form-control" placeholder="Escribe tu mensaje..."></asp:TextBox>
              <button class="btn btn-primary" id="btnEnviarMensaje" type="button">Enviar</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <!-- HiddenField para almacenar el id del contacto seleccionado -->
  <asp:HiddenField ID="hfIdReceptor" runat="server" />

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script type="text/javascript">
        $(document).ready(function () {

            $("#<%= txtMensaje.ClientID %>").keypress(function (e) {
                if (e.which === 13) { //13 es el código de la tecla Enter
                    e.preventDefault(); //Previene el comportamiento por defecto (por ejemplo, submit)
                    $("#btnEnviarMensaje").click();
                }
            });

            //Función para actualizar el contador global de nuevos mensajes
            function updateGlobalMessageCount() {
                var total = 0;
                $(".new-message-indicator").each(function () {
                    if ($(this).is(":visible")) {
                        total++;
                    }
                });
                $("#notifCount").text(total);
            }
            //Llamada inicial para actualizar el contador
            updateGlobalMessageCount();

            //Seleccionar un contacto
            $(".contacto").click(function (e) {
                e.preventDefault();
                var $contacto = $(this); //Guarda la referencia del elemento clickeado
                var idReceptor = $contacto.data("id");  //Usa el valor de data-id
                var nombreContacto = $contacto.find(".contact-name").text();
                $("#lblContacto").text(nombreContacto);
                $("#<%= hfIdReceptor.ClientID %>").val(idReceptor);

            //Llamar al WebMethod para marcar los mensajes de este contacto como leídos
            $.ajax({
                type: "POST",
                url: "Mensajes.aspx/MarcarMensajesComoLeidos",
                data: JSON.stringify({ idReceptor: idReceptor }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function () {
                    //Oculta el indicador para este contacto
                    $contacto.find(".new-message-indicator").hide();
                    //Actualiza el contador global
                    updateGlobalMessageCount();
                },
                error: function (err) {
                    console.log(err);
                }
            });

            //Cargar los mensajes del contacto
            cargarMensajes(idReceptor);
        });

            //Enviar mensaje
            $("#btnEnviarMensaje").click(function () {
                var idReceptor = $("#<%= hfIdReceptor.ClientID %>").val();
            var mensaje = $("#<%= txtMensaje.ClientID %>").val();
            if (mensaje.trim() === "") {
                alert("Ingrese un mensaje.");
                return;
            }
            enviarMensaje(idReceptor, mensaje);
        });

        //Función para cargar mensajes vía AJAX
        function cargarMensajes(idReceptor) {
            $.ajax({
                type: "POST",
                url: "Mensajes.aspx/ObtenerMensajes",
                data: JSON.stringify({ idReceptor: idReceptor }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    $("#chatArea").html(response.d);
                    // Auto-scroll al final
                    var chatArea = $("#chatArea");
                    chatArea.scrollTop(chatArea[0].scrollHeight);
                },
                error: function (err) {
                    console.log(err);
                }
            });
        }

        //Función para enviar mensaje vía AJAX
        function enviarMensaje(idReceptor, mensaje) {
            $.ajax({
                type: "POST",
                url: "Mensajes.aspx/EnviarMensaje",
                data: JSON.stringify({ idReceptor: idReceptor, mensaje: mensaje }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    $("#<%= txtMensaje.ClientID %>").val("");
                    cargarMensajes(idReceptor);
                    //Actualizar el contador global luego de enviar el mensaje
                    updateGlobalMessageCount();
                },
                error: function (err) {
                    console.log(err);
                }
            });
            }
        });
    </script>


</asp:Content>
