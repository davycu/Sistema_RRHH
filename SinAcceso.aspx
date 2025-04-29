<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SinAcceso.aspx.cs" Inherits="Sistema_RRHH.SinAcceso" %>

<!DOCTYPE html>

<html lang="es"> <!-- Se cambia el idioma a español -->
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Error 404 - Página No Encontrada</title>

    <!-- ================== ESTILOS ================== -->
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,400,600,700" rel="stylesheet">
    <link href="Content/BsLogin/assets/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet">
    <link href="Content/BsLogin/assets/plugins/font-awesome/css/font-awesome.min.css" rel="stylesheet">
    <link href="Content/BsLogin/assets/css/style.min.css" rel="stylesheet">
    <link href="Content/BsLogin/assets/css/style-responsive.min.css" rel="stylesheet">
    <link href="Content/BsLogin/assets/css/theme/default.css" rel="stylesheet" id="theme">
</head>

<body class="pace-top">
    <!-- CARGADOR DE PÁGINA -->
    <div id="page-loader" class="fade in"><span class="spinner"></span></div>

    <!-- CONTENEDOR PRINCIPAL -->
    <div id="page-container" class="fade">
        <div class="error">
            <div class="error-code m-b-10">404 <i class="fa fa-warning"></i></div>
            <div class="error-content">
                <div class="error-message">¡Oops! Página no encontrada</div>
                <div class="error-desc m-b-20">
                    Parece que la página que buscas no existe o ha sido eliminada. <br>
                    Puedes volver a la página anterior o regresar al inicio.
                </div>
                <div>
                    <button onclick="history.back()" class="btn btn-warning">Volver Atrás</button>
                    <a href="CerrarSesion.aspx" class="btn btn-success">Ir al Inicio</a>
                </div>
            </div>
        </div>
    </div>

    <!-- ================== SCRIPTS ================== -->
    <script src="Content/BsLogin/assets/plugins/jquery/jquery-1.9.1.min.js"></script>
    <script src="Content/BsLogin/assets/plugins/bootstrap/js/bootstrap.min.js"></script>
    <script src="Content/BsLogin/assets/js/apps.min.js"></script>
    
    <script>
        $(document).ready(function () {
            App.init();
        });
    </script>
</body>
</html>