//Cargar la pregunta de seguridad cuando se hace clic en "Cargar pregunta de seguridad"
$("#btnCargarPregunta").click(function () {
    var usuario = $("#txtUsuarioRecuperar").val().trim();
    var email = $("#txtEmailRecuperar").val().trim();
    if (usuario === "" || email === "") {
        $("#recuperarMsg").text("Ingrese usuario y email.");
        return;
    }
    $.ajax({
        type: "POST",
        url: "Login.aspx/CargarPreguntaSeguridad",
        data: JSON.stringify({ username: usuario, email: email }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (response) {
            var data = response.d;
            if (data.CodigoError == 1) {
                $("#lblPreguntaSeguridad").text(data.Pregunta);
                $("#divPreguntaSeguridad").show();
                $("#divRespuesta").show();
                $("#recuperarMsg").text("");
            } else {
                $("#recuperarMsg").text(data.Mensaje);
                $("#divPreguntaSeguridad").hide();
                $("#divRespuesta").hide();
            }
        },
        error: function () {
            $("#recuperarMsg").text("Error al cargar la pregunta.");
        }
    });
});

//Recuperar la contraseña cuando se hace clic en "Recuperar Contraseña"
$("#btnRecuperar").click(function () {
    var usuario = $("#txtUsuarioRecuperar").val().trim();
    var email = $("#txtEmailRecuperar").val().trim();
    var respuesta = $("#txtRespuestaRecuperar").val().trim();
    if (usuario === "" || email === "" || respuesta === "") {
        $("#recuperarMsg").text("Complete todos los campos.");
        return;
    }
    $.ajax({
        type: "POST",
        url: "Login.aspx/RecuperarContrasenaConPregunta",
        data: JSON.stringify({ username: usuario, email: email, respuesta: respuesta }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (response) {
            var data = response.d;
            if (data.CodigoError == 1) {
                $("#recuperarMsg").removeClass("text-danger").addClass("text-primary").text(data.Mensaje);
            } else {
                $("#recuperarMsg").removeClass("text-primary").addClass("text-danger").text(data.Mensaje);
            }
        },
        error: function () {
            $("#recuperarMsg").text("Error al recuperar la contraseña.");
        }
    });
});
