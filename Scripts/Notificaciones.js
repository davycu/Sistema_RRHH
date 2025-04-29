function toggleNotifications(e) {
    e.preventDefault();
    var dropdown = document.getElementById("notificationsDropdown");
    if (dropdown.style.display === "none" || dropdown.style.display === "") {
        dropdown.style.display = "block";
        // Si quieres marcar todas como leídas al abrir, no lo hagas de inmediato para que el usuario pueda interactuar.
        // Es mejor que cada notificación se marque individualmente al hacer clic.
    } else {
        dropdown.style.display = "none";
    }
}

function marcarNotificacionLeida(notificacionId, redirectUrl) {
    $.ajax({
        type: "POST",
        url: "NotificacionesService.aspx/MarcarNotificacionLeida",
        data: JSON.stringify({ notificacionId: parseInt(notificacionId) }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (response) {
            // Una vez que se marca como leída, redirige a la URL indicada
            window.location.href = redirectUrl;
        },
        error: function (xhr, status, error) {
            console.log("Error al marcar la notificación como leída: " + error);
            // mostrar un mensaje de error
            window.location.href = redirectUrl;
        }
    });
    
    return false;
}