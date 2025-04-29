
    // Función para actualizar el contador global usando el WebMethod
    function actualizarConteoGlobal() {
        $.ajax({
            type: "POST",
            url: "Mensajes.aspx/ObtenerConteoMensajesNuevos",
            data: '{}',
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (response) {
                var count = Number(response.d);
                if (count > 0)
                    $("#notifCount").text(count);
                else
                    $("#notifCount").text("");
            },
            error: function (err) {
                console.log(err);
            }
        });
    }


    $(function () {
        $("#notifCount").text("");
        // Llamada inicial
        actualizarConteoGlobal();
    // Actualización periódica cada 30 segundos
    setInterval(actualizarConteoGlobal, 30000);
    });


