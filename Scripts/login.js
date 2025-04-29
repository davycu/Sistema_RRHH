$(document).ready(function () {
    $(".login-buttons button").click(function (e) {
        e.preventDefault();

        let usuario = $(".login-content input[type='text']").val();
        let password = $(".login-content input[type='password']").val();

        if (usuario === "" || password === "") {
            alert("Por favor, complete ambos campos.");
            return;
        }

        $.ajax({
            type: "POST",
            url: "Login.aspx/AutenticarUsuario",
            data: JSON.stringify({ username: usuario, password: password }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (response) {
                if (response.d.CodigoError === 1) {
                    window.location.href = response.d.Redireccion;
                } else if (response.d.CodigoError === -2) {
                    alert("Su cuenta está inactiva. Contacte al administrador.");
                } else {
                    alert(response.d.Mensaje);
                }
            },
            error: function () {
                alert("Error en la comunicación con el servidor.");
            }
        });
    });
});
