<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="Sistema_RRHH.Login" %>

<!DOCTYPE html>

<!--[if IE 8]> <html lang="en" class="ie8"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en">
<!--<![endif]-->
<head>
	<meta charset="utf-8" />
	<title> HonduHR | Login </title>
	<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" />
	<meta content="" name="description" />
	<meta content="" name="author" />
	
	<!-- ================== BEGIN BASE CSS STYLE ================== -->
	<link href="http://fonts.googleapis.com/css?family=Open+Sans:300,400,600,700" rel="stylesheet">
	<link href="Content/BsLogin/assets/plugins/jquery-ui/themes/base/minified/jquery-ui.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/plugins/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/css/animate.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/css/style.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/css/style-responsive.min.css" rel="stylesheet" />
	<link href="Content/BsLogin/assets/css/theme/default.css" rel="stylesheet" id="theme" />
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

	<!-- ================== END BASE CSS STYLE ================== -->
	
	<!-- ================== BEGIN BASE JS ================== -->
	<script src="Content/BsLogin/assets/plugins/pace/pace.min.js"></script>
	<!-- ================== END BASE JS ================== -->
</head>
<body class="pace-top">
	<!-- begin #page-loader -->
	<div id="page-loader" class="fade in"><span class="spinner"></span></div>
	<!-- end #page-loader -->
	
	<div class="login-cover">
	    <div class="login-cover-image"><img src="Content/BsLogin/assets/img/login-bg/bg-5.jpg" data-id="login-cover-image" alt="" /></div>
	    <div class="login-cover-bg"></div>
	</div>
	<!-- begin #page-container -->
	<div id="page-container" class="fade">
	    <!-- begin login -->
        <div class="login login-v2" data-pageload-addclass="animated fadeIn">
            <!-- begin brand -->
            <div class="login-header">
                <div class="brand">
                    <span class="logo"></span> HonduHR
                    <small>Sistema de Gestión de Permisos y Evaluaciones</small>
                </div>
                <div class="icon">
                    <i class="fa fa-sign-in"></i>
                </div>
            </div>
            <!-- end brand -->
            <div class="login-content">
                <form action="index.html" method="POST" class="margin-bottom-0">
                    <div class="form-group m-b-20">
                        <input type="text" class="form-control input-lg" placeholder="Usuario" required />
                    </div>
                    <div class="form-group m-b-20 position-relative">
                        <input type="password" id="password" class="form-control input-lg" placeholder="Contraseña" required />
                        <i class="fas fa-eye" id="togglePassword" style="position: absolute; right: 45px; top: 44%; transform: translateY(-50%); cursor: pointer;"></i>
                    </div>
                    <!--
                    <div class="checkbox m-b-20">
                        <label>
                            <input type="checkbox" /> Recordar mis credenciales
                        </label>
                    </div>
                    -->
                    <div class="login-buttons">
                        <button type="submit" class="btn btn-success btn-block btn-lg">Ingresar</button>
                    </div>
                    <div class="m-t-20 text-center">
                        ¿Olvidaste tu contraseña? Recupérala <a href="#" data-toggle="modal" data-target="#modalRecuperar">aquí</a>.
                    </div>
                </form>
            </div>
        </div>
        <!-- end login -->
        
	</div>
	<!-- end page container -->

	 <!-- Modal de Recuperación de Contraseña -->
    <div class="modal fade" id="modalRecuperar" tabindex="-1" role="dialog" aria-labelledby="modalRecuperarLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content animate__animated animate__fadeIn">
                <!-- Modal Header: Título y botón cerrar -->
                <div class="modal-header" style="padding: 10px 15px; border-bottom: none;">
                    <h4 class="modal-title" id="modalRecuperarLabel" style="margin-bottom: 0px;">Recuperar Contraseña</h4>
                    <h6>Contacta a tu supervisor en caso de no lograr obtener tus credenciales.</h6>
                    <button type="button" class="close" title="Cerrar" data-dismiss="modal" aria-label="Cerrar" style="margin-top: -60px;">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <!-- Línea separadora -->
                <hr style="margin: 5px 15px 5px; border-top:1px solid #ccc">
                <div class="modal-body">
                    <form id="formRecuperar">
                        <!-- Campo para nombre de usuario -->
                        <div class="mb-3">
                            <label for="txtUsuarioRecuperar" class="form-label">Usuario</label>
                            <input type="text" class="form-control" id="txtUsuarioRecuperar" required>
                        </div>
                        <!-- Campo para email -->
                        <div class="mb-3" style="margin-top: 15px;">
                            <label for="txtEmailRecuperar" class="form-label">Email</label>
                            <input type="email" class="form-control" id="txtEmailRecuperar" required>
                        </div>
                        
                        <!-- Sección de pregunta y respuesta: inicialmente oculta -->
                        <div class="mb-3" id="divPreguntaSeguridad" style="display: none; margin-top: 15px">
                            <label class="form-label">Pregunta de seguridad</label>
                            <p id="lblPreguntaSeguridad" style="margin-bottom: 0;"></p>
                        </div>
                        
                        <div class="mb-3" id="divRespuesta" style="display: none; margin-top: 15px">
                            <label for="txtRespuestaRecuperar" class="form-label">Respuesta</label>
                            <input type="password" class="form-control" id="txtRespuestaRecuperar" required>
                        </div>

                        <!-- Fila para botones: Cargar pregunta y Recuperar Contraseña -->
                        <div class="row mb-3" style="margin-top: 20px;">
                            <div class="col-md-6">
                                <button type="button" class="btn btn-outline-primary btn-block" id="btnCargarPregunta">Cargar pregunta de seguridad</button>
                            </div>
                            <div class="col-md-6">
                                <button type="button" class="btn btn-primary btn-block" id="btnRecuperar">Recuperar Contraseña</button>
                            </div>
                        </div>
                        <hr style="margin: 5px 15px 15px; margin-top:15px; border-top:1px solid #ccc">
                        <!-- Alertas se muestran debajo de los botones, alineadas a la izquierda -->
                        <div id="recuperarMsg" class="text-danger mb-3" style="text-align: left;"></div>
                    </form>
                </div>
            </div>
        </div>
    </div>
	
	<!-- ================== BEGIN BASE JS ================== -->
	<script src="Content/BsLogin/assets/plugins/jquery/jquery-1.9.1.min.js"></script>
	<script src="Content/BsLogin/assets/plugins/jquery/jquery-migrate-1.1.0.min.js"></script>
	<script src="Content/BsLogin/assets/plugins/jquery-ui/ui/minified/jquery-ui.min.js"></script>
	<script src="Content/BsLogin/assets/plugins/bootstrap/js/bootstrap.min.js"></script>
	<!--[if lt IE 9]>
		<script src="assets/crossbrowserjs/html5shiv.js"></script>
		<script src="assets/crossbrowserjs/respond.min.js"></script>
		<script src="assets/crossbrowserjs/excanvas.min.js"></script>
	<![endif]-->
	<script src="Content/BsLogin/assets/plugins/slimscroll/jquery.slimscroll.min.js"></script>
	<script src="Content/BsLogin/assets/plugins/jquery-cookie/jquery.cookie.js"></script>
	<!-- ================== END BASE JS ================== -->
	
	<!-- ================== BEGIN PAGE LEVEL JS ================== -->
	<script src="Content/BsLogin/assets/js/login-v2.demo.min.js"></script>
	<script src="Content/BsLogin/assets/js/apps.min.js"></script>
	<!-- ================== END PAGE LEVEL JS ================== -->

	<script 
		src="Scripts/login.js">

	</script>
	
	<script>
		$(document).ready(function() {
			App.init();
			LoginV2.init();
		});
	</script>

    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const passwordInput = document.getElementById("password");
            const togglePassword = document.getElementById("togglePassword");

            togglePassword.addEventListener("mouseenter", function () {
                passwordInput.type = "text"; // Mostrar contraseña
            });

            togglePassword.addEventListener("mouseleave", function () {
                passwordInput.type = "password"; // Ocultar contraseña
            });
        });

        //reset campos del modal al salir
        $('#modalRecuperar').on('hidden.bs.modal', function () {
            var form = $(this).find('form')[0];
            if (form) {
                form.reset();
            }
            $('#recuperarMsg').text('');
            $('#divPreguntaSeguridad').hide();
            $('#divRespuesta').hide();
        });

    </script>

    <script
        src="Scripts/RecuperarPass.js">
    </script>

</body>
</html>
